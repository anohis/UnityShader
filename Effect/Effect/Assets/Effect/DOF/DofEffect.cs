using UnityEngine;
using System.Collections;

namespace Effect.Dof
{
	public class DofEffect : MonoBehaviour
	{
		public Transform Focal;
		public Material DofMaterial;

		#region MonoBehaviour
		private void OnEnable()
		{
			GetComponent<UnityEngine.Camera>().depthTextureMode |= DepthTextureMode.Depth;
		}

		private void OnRenderImage(RenderTexture source, RenderTexture destination)
		{
			DofMaterial.SetFloat("_FocalDistance", Vector3.Distance(Focal.transform.position, transform.position) - 0.5f);
			Graphics.Blit(source, destination, DofMaterial);
		}
		#endregion
	}
}