using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

namespace Effect.Block
{
	public class BlockEffect : MonoBehaviour
	{
		public bool IsAppear = true;

		[SerializeField]
		private Renderer[] _renderers;
		[SerializeField]
		private float _blockDuringTime = 1;
		[SerializeField]
		private float _beamDuringTime = 1;
		[SerializeField]
		private Color _color;
		[SerializeField]
		private float _maxBlockClip = 1;

		[SerializeField]
		private UnityEvent _OnComplete;

		private float _blockTime = 0;
		private float _beamTime = 0;
		private bool _isComplete = false;

		private void Start()
		{
			Restart();
		}

		private void Update()
		{
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
		public void DestroyObject()
		{
			Destroy(gameObject);
		}
		public void Restart()
		{
			_isComplete = false;

			_blockTime = 0;
			_beamTime = 0;

			foreach (Renderer renderer in _renderers)
			{
				if (IsAppear)
				{
					renderer.material.SetFloat("_BeamStep", 1);
					renderer.material.SetFloat("_BlockClip", GetBlockClip(1));
					renderer.material.SetColor("_BlockColor", _color);
				}
				else
				{
					renderer.material.SetFloat("_BeamStep", 0);
					renderer.material.SetFloat("_BlockClip", GetBlockClip(0));
					renderer.material.SetColor("_BlockColor", new Color(0, 0, 0, 0));
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

		private float GetRate(float value,float max)
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
			return _maxBlockClip * (2 * rate - 1);
		}

		private void SetBlockClip(float value)
		{
			foreach (Renderer renderer in _renderers)
			{
				renderer.material.SetFloat("_BlockClip", value);
			}
		}
		private void SetBlockColor(float rate)
		{
			foreach (Renderer renderer in _renderers)
			{
				renderer.material.SetColor("_BlockColor", _color * rate);
			}
		}
		private void SetBeamStep(float value)
		{
			foreach (Renderer renderer in _renderers)
			{
				renderer.material.SetFloat("_BeamStep", value);
			}
		}

		private void Disappear()
		{
			if (CheckBlockTime())
			{
				float rate = GetBlockRate();
				SetBlockClip(GetBlockClip(rate));
				SetBlockColor(rate);

				_blockTime += Time.deltaTime;
			}
			else if (CheckBeamTime())
			{
				float rate = GetBeamRate();
				SetBeamStep(rate);

				_beamTime += Time.deltaTime;
			}
		}
		private void Appear()
		{
			if (CheckBeamTime())
			{
				float rate = 1 - GetBeamRate();
				SetBeamStep(rate);

				_beamTime += Time.deltaTime;
			}
			else if (CheckBlockTime())
			{
				float rate = 1 - GetBlockRate();
				SetBlockClip(GetBlockClip(rate));
				SetBlockColor(rate);

				_blockTime += Time.deltaTime;
			}
		}
		#endregion
	}
}