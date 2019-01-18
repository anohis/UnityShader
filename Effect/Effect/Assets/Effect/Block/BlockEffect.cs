using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Rendering;

namespace RPG2.Effect
{
	public class BlockEffect : MonoBehaviour
	{
		private class State
		{
			public event Func<bool> OnUpdate;
			public event Action OnEnter;

			private bool _isFirst = true;

			public bool Update()
			{
				if (_isFirst && OnEnter!=null)
				{
					_isFirst = false;
					OnEnter();
				}
				if (OnUpdate != null)
				{
					return OnUpdate();
				}
				return false;
			}
		}

		public bool IsReverse;

		[Header("Mesh")]
		public SkinnedMeshRenderer[] TargetSkinRender;
		public MeshFilter[] TargetMeshFilter;

		[Header("Time")]
		public float BlockingTime;
		public float BeamTime;

		[Header("Material")]
		public Shader BlockShader;
		public Texture Texture;
		public float _BlockHeight;
		[Range(0, 1)] public float _BlockUnit = 0.05f;
		[Range(0, 1)] public float _BlockOffset = 0.001f;
		public Color _BlockColor = Color.white;
		public Vector3 _BlockCenterOffset;
		public Vector3 _BeamCenterOffset;
		public float _BeamRadius = 4;
		[Range(0, 1)] public float _BeamMinShowRate = 0.7f;
		[Range(0, 1)] public float _BeamMaxShowRate = 0.9f;
		[Range(0, 1)] public float _BeamCount = 0.9f;
		public Vector4 _BeamDirection = new Vector4(0,3,0,0);
		public Vector4 _BeamStretchPower = new Vector4(-1,-20,-1,1);

		public UnityEvent OnComplete;

		private Material EffectMaterial
		{
			get
			{
				if (_material == null)
				{
					_material = new Material(BlockShader);
				}
				return _material;
			}
		}
		private Material _material;
		private float _blockingTime = 0;
		private float _beamTime = 0;
		private Queue<State> _stateQueue = new Queue<State>();

		private Dictionary<SkinnedMeshRenderer, Material[]> _skinnedMeshMaterials = new Dictionary<SkinnedMeshRenderer, Material[]>();

		#region MonoBehaviour
		private void Awake()
		{
			foreach (SkinnedMeshRenderer skinnedMeshRenderer in TargetSkinRender)
			{
				_skinnedMeshMaterials.Add(skinnedMeshRenderer, skinnedMeshRenderer.materials);
			}
		}
		private void OnEnable()
		{
			ReStart();
			InitializeMaterial();
		}
		private void Update()
		{
			if (_stateQueue.Count == 0)
			{
				enabled = false;
				OnComplete.Invoke();
				return;
			}

			State state = _stateQueue.Peek();
			if(state.Update() == false)
			{
				_stateQueue.Dequeue();
			}

			foreach (SkinnedMeshRenderer skinnedMeshRenderer in TargetSkinRender)
			{
				Mesh mesh = new Mesh();
				skinnedMeshRenderer.BakeMesh(mesh);
				for (int subMeshIndex = 0; subMeshIndex < mesh.subMeshCount; subMeshIndex++)
				{
					Graphics.DrawMesh(
						mesh,
						Matrix4x4.TRS(skinnedMeshRenderer.transform.position, skinnedMeshRenderer.transform.rotation, skinnedMeshRenderer.transform.lossyScale),
						EffectMaterial,
						gameObject.layer,
						Camera.main,
						subMeshIndex
						);
				}
			}
			foreach (MeshFilter meshFilter in TargetMeshFilter)
			{
				Graphics.DrawMesh(
					meshFilter.sharedMesh,
					Matrix4x4.TRS(meshFilter.transform.position, meshFilter.transform.rotation, meshFilter.transform.lossyScale),
					EffectMaterial,
					gameObject.layer
					);
			}
		}
		#endregion

		#region public func
		public void ReStart()
		{
			enabled = true;

			_stateQueue.Clear();
			if (IsReverse)
			{
				_blockingTime = BlockingTime;
				_beamTime = BeamTime;

				State state = new State();
				state.OnEnter += () =>
				{
					SetOtherMaterialEnable(false);
				};
				state.OnUpdate += () =>
				{
					if (_beamTime > 0)
					{
						_beamTime -= Time.deltaTime;
						CalcBeamStep();
						return true;
					}
					return false;
				};
				_stateQueue.Enqueue(state);

				state = new State();
				state.OnEnter += () =>
				{
					SetOtherMaterialEnable(true);
				};
				state.OnUpdate += () =>
				{
					if (_blockingTime > 0)
					{
						_blockingTime -= Time.deltaTime;
						CalcBlockStep();
						return true;
					}
					return false;
				};
				_stateQueue.Enqueue(state);
			}
			else
			{
				_blockingTime = 0;
				_beamTime = 0;

				State state = new State();
				state.OnEnter += () =>
				{
					SetOtherMaterialEnable(true);
				};
				state.OnUpdate += () =>
				{
					if (_blockingTime < BlockingTime)
					{
						_blockingTime += Time.deltaTime;
						CalcBlockStep();
						return true;
					}
					return false;
				};
				_stateQueue.Enqueue(state);

				state = new State();
				state.OnEnter += () =>
				{
					SetOtherMaterialEnable(false);
				};
				state.OnUpdate += () =>
				{
					if (_beamTime < BeamTime)
					{
						_beamTime += Time.deltaTime;
						CalcBeamStep();
						return true;
					}
					return false;
				};
				_stateQueue.Enqueue(state);
			}

			CalcBlockStep();
			CalcBeamStep();
		}
		#endregion

		#region private func
		private void CalcBlockStep()
		{
			float rate = Mathf.Clamp(_blockingTime / BlockingTime, 0, 1);
			EffectMaterial.SetFloat("_BlockStep", rate);
		}
		private void CalcBeamStep()
		{
			float rate = Mathf.Clamp(_beamTime / BeamTime, 0, 1);
			EffectMaterial.SetFloat("_BeamStep", rate);
		}

		private void InitializeMaterial()
		{
			EffectMaterial.SetTexture("_MainTex", Texture);
			CalcBlockStep();
			CalcBeamStep();
			EffectMaterial.SetFloat("_BlockHeight", _BlockHeight);
			EffectMaterial.SetFloat("_BlockUnit", _BlockUnit);
			EffectMaterial.SetFloat("_BlockOffset", _BlockOffset);
			EffectMaterial.SetVector("_BlockBasePosition", transform.position + _BlockCenterOffset);
			EffectMaterial.SetColor("_BlockColor", _BlockColor);
			EffectMaterial.SetFloat("_BeamRadius", _BeamRadius);
			EffectMaterial.SetFloat("_BeamMinShowRate", _BeamMinShowRate);
			EffectMaterial.SetFloat("_BeamMaxShowRate", _BeamMaxShowRate);
			EffectMaterial.SetFloat("_BeamCount", _BeamCount);
			EffectMaterial.SetVector("_BeamCenterPosition", transform.position + _BeamCenterOffset);
			EffectMaterial.SetVector("_BeamDirection", _BeamDirection);
			EffectMaterial.SetVector("_BeamStretchPower", _BeamStretchPower);
		}
		private void SetOtherMaterialEnable(bool isEnable)
		{
			foreach (SkinnedMeshRenderer skinnedMeshRenderer in TargetSkinRender)
			{
				if (isEnable)
				{
					skinnedMeshRenderer.materials = _skinnedMeshMaterials[skinnedMeshRenderer];
				}
				else
				{
					skinnedMeshRenderer.materials = new Material[0];
				}
			}

			foreach (MeshFilter meshFilter in TargetMeshFilter)
			{
				Renderer renderer = meshFilter.GetComponent<Renderer>();
				renderer.enabled = isEnable;
			}
		}
		#endregion
	}
}