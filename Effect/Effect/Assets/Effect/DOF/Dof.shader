Shader "Custom/Dof" 
{
	Properties 
	{
		_MainTex("Albedo (RGB)", 2D) = "white" {}

		_BlurPower("BlurPower",Float) = 1
		_BlurCenterPower("BlurCenterPower",Range(0,1)) = 0.5
		_MaxBlurDistance("MaxBlurDistance",Float) = 0
		_FocalDistance("FocalDistance",Float) = 1
		_FocalRange("FocalRange",Range(0,1)) = 1
	}
	SubShader 
	{
		Pass
		{
			CGPROGRAM
			#pragma glsl
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			sampler2D _CameraDepthTexture;

			float _BlurPower;
			float _BlurCenterPower;
			float _MaxBlurDistance;
			float _FocalDistance;
			float _FocalRange;

			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv[5] : TEXCOORD0;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv[0] = v.texcoord;
				o.uv[1] = v.texcoord + float2(0, _MainTex_TexelSize.y) * _BlurPower;
				o.uv[2] = v.texcoord - float2(0, _MainTex_TexelSize.y) * _BlurPower;
				o.uv[3] = v.texcoord + float2(_MainTex_TexelSize.x, 0) * _BlurPower;
				o.uv[4] = v.texcoord - float2(_MainTex_TexelSize.x, 0) * _BlurPower;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half4 source = tex2D(_MainTex, i.uv[0]); 

				fixed4 blur = source * _BlurCenterPower;
				float blurWeight = (1 - _BlurCenterPower) / 4;
				blur += tex2D(_MainTex, i.uv[1]) * blurWeight;
				blur += tex2D(_MainTex, i.uv[2]) * blurWeight;
				blur += tex2D(_MainTex, i.uv[3]) * blurWeight;
				blur += tex2D(_MainTex, i.uv[4]) * blurWeight;

				float depth  = UNITY_SAMPLE_DEPTH (tex2D (_CameraDepthTexture, i.uv[0]));
				depth  = LinearEyeDepth(depth);
				depth = abs(depth - _FocalDistance);
				float blurFactor = saturate(saturate(depth / _MaxBlurDistance) - _FocalRange);
				//clip(blurFactor - _FocalRange);
				return lerp(source, blur,blurFactor);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
