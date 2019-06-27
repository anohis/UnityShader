Shader "Custom/GS-Tail"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		_Cubemap("Cubemap", Cube) = "" {}

		_Brightness("Brightness", Float) = 1
		_Saturation("Saturation", Float) = 1
		_Contrast("Contrast", Float) = 1

		_RefractRatio("Refraction Ratio", Range(-1, 1)) = 0.5

		_Octaves("Octaves", Float) = 1
		_Frequency("Frequency", Float) = 2.0
		_Amplitude("Amplitude", Float) = 1.0
		_Lacunarity("Lacunarity", Float) = 1
		_Persistence("Persistence", Float) = 0.8
		_Offset("Offset", Vector) = (0.0, 0.0, 0.0, 0.0)
    }
    SubShader
    {
		Pass
		{
			Cull off
			//Zwrite Off
			//Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Assets/Hsv.cginc"
			#include "Assets/Noise.cginc"


			sampler2D _MainTex;
			float4 _MainTex_ST;
			samplerCUBE _Cubemap;
			float _RefractRatio;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				float2 uv : TEXCOORD3;
				float2 uv2 : TEXCOORD4;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv2 = v.uv2;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed alpha = tex2D(_MainTex, i.uv).a - i.uv2.x;
				clip(alpha);

				float noise = PerlinNormal(i.worldPos);

				float refractRatio = max(min(_RefractRatio, 1), -1);
				refractRatio = _RefractRatio;

				fixed3 worldRefr = refract(-normalize(i.worldViewDir), normalize(i.worldNormal), refractRatio);

				fixed4 color = texCUBE(_Cubemap, worldRefr);

				//return fixed4(GetColor(color.rgb), alpha);

				float3 worldNormal = normalize(i.worldNormal);

				return fixed4(worldNormal.x, worldNormal.y, worldNormal.z, 1);
			}
			ENDCG
		}
    }
}
