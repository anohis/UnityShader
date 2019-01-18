using System.Collections;
using System.Collections.Generic;
using RPG2.Math;
using RPGBattle;
using UnityEngine;
using UnityEngine.Events;

namespace RPG2.Effect
{
	public class BlockEffect : TimeBehaviour
	{
		private enum StateType
		{
			Block,
			Beam,
			Complete
		}

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
		public Vector3 _BeamCenterOffset;
		public float _BeamRadius = 4;
		[Range(0, 1)] public float _BeamMinShowRate = 0.7f;
		[Range(0, 1)] public float _BeamMaxShowRate = 0.9f;
		[Range(0, 1)] public float _BeamCount = 0.9f;
		public Vector4 _BeamDirection = new Vector4(0,3,0,0);
		public Vector4 _BeamStretchPower = new Vector4(-1,-20,-1,1);

		[Header("Event")]
		public UnityEvent OnComplete;

		private Material BlockMaterial
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
		private StateType _state;

		#region MonoBehaviour
		private void Awake()
		{
			ReStart();

			InitializeMaterial();
			AddMaterial();
		}
		#endregion

		#region TimeBehaviour
		public override void OnFixedUpdate(float deltaTime)
		{

		}
		public override void OnUpdate(float deltaTime)
		{
			if (_blockingTime < BlockingTime)
			{
				_blockingTime += deltaTime;
				CalcBlockStep();
			}
			else if (_beamTime < BeamTime)
			{
				ChangeState(StateType.Beam);
				_beamTime += deltaTime;
				CalcBeamStep();
			}
			else
			{
				ChangeState(StateType.Complete);
			}
		}
		#endregion

		#region public func
		public void ReStart()
		{
			_blockingTime = 0;
			_beamTime = 0;

			CalcBlockStep();
			CalcBeamStep();

			_state = StateType.Block;
		}
		public void DestroyObject()
		{
			Destroy(gameObject);
		}
		#endregion

		#region private func
		private void ChangeState(StateType type)
		{
			if (_state == StateType.Block && type == StateType.Beam)
			{
				RemoveOtherMaterial();
			}
			else if(_state == StateType.Beam && type == StateType.Complete)
			{
				OnComplete?.Invoke();
			}
			_state = type;
		}

		private void CalcBlockStep()
		{
			float rate = MathFunc.Saturate(_blockingTime / BlockingTime, 0, 1);
			BlockMaterial.SetFloat("_BlockStep", rate);
		}
		private void CalcBeamStep()
		{
			float rate = MathFunc.Saturate(_beamTime / BeamTime, 0, 1);
			BlockMaterial.SetFloat("_BeamStep", rate);
		}

		private void InitializeMaterial()
		{
			BlockMaterial.SetTexture("_MainTex", Texture);
			CalcBlockStep();
			CalcBeamStep();
			BlockMaterial.SetFloat("_BlockHeight", _BlockHeight);
			BlockMaterial.SetFloat("_BlockUnit", _BlockUnit);
			BlockMaterial.SetFloat("_BlockOffset", _BlockOffset);
			BlockMaterial.SetVector("_BlockBasePosition", transform.position);
			BlockMaterial.SetColor("_BlockColor", _BlockColor);
			BlockMaterial.SetFloat("_BeamRadius", _BeamRadius);
			BlockMaterial.SetFloat("_BeamMinShowRate", _BeamMinShowRate);
			BlockMaterial.SetFloat("_BeamMaxShowRate", _BeamMaxShowRate);
			BlockMaterial.SetFloat("_BeamCount", _BeamCount);
			BlockMaterial.SetVector("_BeamCenterPosition", transform.position + _BeamCenterOffset);
			BlockMaterial.SetVector("_BeamDirection", _BeamDirection);
			BlockMaterial.SetVector("_BeamStretchPower", _BeamStretchPower);
		}
		private void AddMaterial()
		{
			Transform parent = transform;
			while (parent.parent != null)
			{
				parent = parent.parent;
			}

			Renderer[] renderers = parent.GetComponentsInChildren<Renderer>();
			foreach (Renderer renderer in renderers)
			{
				List<Material> materials = new List<Material>(renderer.materials);

				materials.Add(BlockMaterial);
				renderer.materials = materials.ToArray();
			}
		}
		private void RemoveMaterial()
		{
			Transform parent = transform;
			while (parent.parent != null)
			{
				parent = parent.parent;
			}

			Renderer[] renderers = parent.GetComponentsInChildren<Renderer>();
			foreach (Renderer renderer in renderers)
			{
				List<Material> materials = new List<Material>(renderer.materials);
				Material removeMaterial = BlockMaterial;
				foreach (Material material in materials)
				{
					if (material.shader == BlockShader)
					{
						removeMaterial = material;
						break;
					}
				}
				materials.Remove(removeMaterial);
				renderer.materials = materials.ToArray();
			}
		}
		private void RemoveOtherMaterial()
		{
			Transform parent = transform;
			while (parent.parent != null)
			{
				parent = parent.parent;
			}

			Renderer[] renderers = parent.GetComponentsInChildren<Renderer>();
			foreach (Renderer renderer in renderers)
			{
				List<Material> materials = new List<Material>();
				materials.Add(BlockMaterial);
				renderer.materials = materials.ToArray();
			}
		}
		#endregion
	}
}