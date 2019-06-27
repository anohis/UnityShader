Shader "Custom/GS"
{
	Properties
	{
		_Cubemap("Cubemap", Cube) = "" {}
		_Brightness("Brightness", Float) = 1
		_Saturation("Saturation", Float) = 1
		_Contrast("Contrast", Float) = 1
		_RefractAmount("Refraction Amount", Range(0, 1)) = 1
		_RefractRatio("Refraction Ratio", Range(0.1, 1)) = 0.5
	}
	SubShader
	{

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Assets/Hsv.cginc"

			samplerCUBE _Cubemap;
			float _RefractAmount;
			float _RefractRatio;
			
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				float2 uv : TEXCOORD3;
				fixed3 worldRefr : TEXCOORD4;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal) * sign(dot(o.worldNormal, o.worldViewDir)), _RefractRatio);
				o.uv = v.uv;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 color1 = texCUBE(_Cubemap, i.worldViewDir);
				fixed4 color2 = texCUBE(_Cubemap, i.worldRefr);
				fixed4 color = lerp(color1, color2, _RefractAmount);
				return fixed4(GetColor(color.rgb),color.a);
			}
			ENDCG
		}
	}
}
