using UnityEngine;
using System.Collections;

namespace Effect.Earth
{
    public class Bloom : MonoBehaviour
    {
        public Material Material;
        [Range(0, 10)] public int Iterations = 3;
        [Range(0.2f, 3.0f)] public float BlurSpread = 0.6f;
        [Range(1, 8)] public int DownSample = 2;
        [Range(0.0f, 4.0f)] public float LuminanceThreshold = 0.6f;

        void OnRenderImage(RenderTexture src, RenderTexture dest)
        {
            Material.SetFloat("_LuminanceThreshold", LuminanceThreshold);

            int rtW = src.width / DownSample;
            int rtH = src.height / DownSample;

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;

            Graphics.Blit(src, buffer0, Material, 0);

            for (int i = 0; i < Iterations; i++)
            {
                Material.SetFloat("_BlurSize", 1.0f + i * BlurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1, Material, 1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1, Material, 2);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            Material.SetTexture("_Bloom", buffer0);
            Graphics.Blit(src, dest, Material, 3);

            RenderTexture.ReleaseTemporary(buffer0);
        }
    }
}

