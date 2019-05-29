using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using ToolKit.Math;
using System;

namespace Effect.Blur
{
	public class BlockEffect : MonoBehaviour
	{
		public bool IsAppear = true;

		[SerializeField] private Shader _shader;

		[SerializeField] private float _blockDuringTime = 1;
		[SerializeField] private float _beamDuringTime = 1;
		[SerializeField] private Color _color;
		[SerializeField] private float _maxBlockClip = 1;
		[SerializeField] private Vector4 _beamDirection;
		[SerializeField] private float _blockClipMaxLength;
		[SerializeField] private float _effectRadius;

		[SerializeField] private UnityEvent _OnComplete;

		private List<Material> _materials = new List<Material>();
		private float _blockTime = 0;
		private float _beamTime = 0;
		private bool _isComplete = false;

		private void OnEnable()
		{
			var list = gameObject.GetComponentsInChildren<Renderer>();
			foreach (var r in list)
			{
				var m = new Material(_shader);
				_materials.Add(m);

				r.materials = new Material[]
				{
					r.material,
					m
				};
			}
			Restart();
		}

		private void Update()
		{
			foreach (var material in _materials)
			{
				material.SetVector("_BlockClipCenter", transform.position);
				material.SetVector("_EffectPosition", transform.position);
			}

			if (CheckBlockTime() || CheckBeamTime())
			{
				if (IsAppear)
				{
					Appear();
				}
				else
				{
					Disappear();
				}
			}
			else if (_isComplete == false)
			{
				_isComplete = true;
				_OnComplete.Invoke();
			}
		}

		#region public custom func
		public void Revert()
		{
			IsAppear = !IsAppear;
		}
		public void Restart()
		{
			_isComplete = false;

			_blockTime = 0;
			_beamTime = 0;
			foreach (var material in _materials)
			{
				material.SetVector("_EffectDirection", _beamDirection);
				material.SetFloat("_BlockClipMaxLength", _blockClipMaxLength);
				material.SetFloat("_EffectRadius", _effectRadius);

				if (IsAppear)
				{
					material.SetFloat("_BeamStep", 0);
					material.SetFloat("_BlockClip", GetBlockClip(1));
					material.SetColor("_BlockColor", _color);
				}
				else
				{
					material.SetFloat("_BeamStep", 1);
					material.SetFloat("_BlockClip", GetBlockClip(0));
					material.SetColor("_BlockColor", new Color(0, 0, 0, 0));
				}
			}
		}
		#endregion

		#region private custom func
		private bool CheckBlockTime()
		{
			return _blockTime < _blockDuringTime;
		}
		private bool CheckBeamTime()
		{
			return _beamTime < _beamDuringTime;
		}

		private float GetRate(float value, float max)
		{
			float rate = value / max;

			if (rate < 0)
			{
				rate = 0;
			}
			else if (rate > 1)
			{
				rate = 1;
			}

			return rate;
		}
		private float GetBlockRate()
		{
			return GetRate(_blockTime, _blockDuringTime);
		}
		private float GetBeamRate()
		{
			return GetRate(_beamTime, _beamDuringTime);
		}

		private float GetBlockClip(float rate)
		{
			//return _maxBlockClip * (2 * rate - 1);
			return rate;
		}

		private void Disappear()
		{
			if (CheckBlockTime())
			{
				float rate = GetBlockRate();
				Blocking(rate);
				_blockTime += Time.deltaTime;
			}
			else if (CheckBeamTime())
			{
				float rate = 1 - GetBeamRate();
				Beaming(rate);
				_beamTime += Time.deltaTime;
			}
		}
		private void Appear()
		{
			if (CheckBeamTime())
			{
				float rate = GetBeamRate();
				Beaming(rate);
				_beamTime += Time.deltaTime;
			}
			else if (CheckBlockTime())
			{
				float rate = 1 - GetBlockRate();
				Blocking(rate);
				_blockTime += Time.deltaTime;
			}
		}

		private void Blocking(float rate)
		{
			var r = GetBlockClip(rate);
			ForeachMaterials((m) =>
			{
				m.SetFloat("_BlockClip", r);
				m.SetColor("_BlockColor", _color * rate);
			});
		}
		private void Beaming(float rate)
		{
			ForeachMaterials((m) =>
			{
				m.SetFloat("_BeamStep", rate);
			});
		}

		private void ForeachMaterials(Action<Material> action)
		{
			foreach (var material in _materials)
			{
				action?.Invoke(material);
			}
		}
		#endregion
	}
}