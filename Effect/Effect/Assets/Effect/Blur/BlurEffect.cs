using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Effect.Blur
{
	public class BlurEffect : MonoBehaviour
	{
		public Material EffectMaterial;

		#region MonoBehaviour
		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			EffectMaterial.SetVector("_BlurDirection", new Vector2(1, 0));
			Graphics.Blit(source, destination, EffectMaterial, 0);
			EffectMaterial.SetVector("_BlurDirection", new Vector2(0, 1));
			Graphics.Blit(destination, source, EffectMaterial, 0);
		}
		#endregion
	}
}
