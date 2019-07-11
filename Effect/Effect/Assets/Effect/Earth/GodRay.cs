using UnityEngine;
using System.Collections;

namespace Effect.Earth
{
    [ExecuteInEditMode]
    public class GodRay : MonoBehaviour
    {
        public Camera MainCamera;
        public Transform Sun;

        public Material Material;
        public Material MaskMaterial;

        public Color LightColor;
        [Range(0, 3)] public int DownSample = 1;
        [Range(1, 3)] public int BlurIteration = 2;
        [Range(0, 10)] public float SamplerScale = 10.0f;
        [Range(0, 10)] public float LightAttenuation = 0.5f;
        [Range(0, 1)] public float LuminanceThreshold = 0.5f;
        [Range(1, 4)] public float LuminancePower = 1f;

        private RenderTexture _maskTexture = null;

        private void OnEnable()
        {
            MainCamera.depthTextureMode |= DepthTextureMode.Depth;

            if (_maskTexture == null)
            {
                _maskTexture = new RenderTexture(512, 512, 0);
            }
        }

        void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            int rtWidth = src.width >> DownSample;
            int rtHeight = src.height >> DownSample;

            RenderTexture temp = RenderTexture.GetTemporary(rtWidth, rtHeight, 0, src.format);

            Vector3 viewPortLightPos = MainCamera.WorldToViewportPoint(Sun.position);
            Vector4 viewPortLightPos4 = new Vector4(viewPortLightPos.x, viewPortLightPos.y, viewPortLightPos.z, 0);

            Graphics.Blit(src, _maskTexture, MaskMaterial);

            Material.SetTexture("_MaskTex", _maskTexture);
            Material.SetVector("_ViewPortLightPos", viewPortLightPos4);
            Material.SetFloat("_LightAttenuation", LightAttenuation);
            Material.SetFloat("_LuminancePower", LuminancePower);
            Material.SetFloat("_LuminanceThreshold", LuminanceThreshold);
            Graphics.Blit(src, temp, Material, 0);

            Material.SetVector("_ViewPortLightPos", viewPortLightPos4);
            float samplerOffset = SamplerScale / src.width;
            for (int i = 0; i < BlurIteration; i++)
            {
                RenderTexture temp2 = RenderTexture.GetTemporary(rtWidth, rtHeight, 0, src.format);
                float offset = samplerOffset * (i * 2 + 1);
                Material.SetVector("_BlurOffsetScale", new Vector4(offset, offset, 0, 0));
                Graphics.Blit(temp, temp2, Material, 1);

                offset = samplerOffset * (i * 2 + 2);
                Material.SetVector("_BlurOffsetScale", new Vector4(offset, offset, 0, 0));
                Graphics.Blit(temp2, temp, Material, 1);
                RenderTexture.ReleaseTemporary(temp2);
            }

            Material.SetTexture("_BlurTex", temp);
            Material.SetColor("_LightColor", LightColor);
            Graphics.Blit(src, dest, Material, 2);

            RenderTexture.ReleaseTemporary(temp);
        }
    }
}