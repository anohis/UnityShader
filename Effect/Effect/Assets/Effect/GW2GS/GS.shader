Shader "Custom/GS"
{
	Properties
	{
		_Cubemap("Cubemap", Cube) = "" {}
		_Brightness("Brightness", Float) = 1
		_Saturation("Saturation", Float) = 1
		_Contrast("Contrast", Float) = 1
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
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.uv = v.uv;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 color = texCUBE(_Cubemap, i.worldViewDir);
				return fixed4(GetColor(color.rgb),color.a);
			}
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Assets/Noise.cginc"
			#include "Assets/Hsv.cginc"

			samplerCUBE _Cubemap;

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
			};

			v2f vert(appdata v)
			{
				v2f o;
				v.vertex.xyz += v.normal * 0.0025;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.uv = v.uv;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float gradient = PerlinNormal(i.worldPos * sin(_Time.x), 10, 10, 100, 1, 1, 1);
				clip(gradient);

				fixed4 color = texCUBE(_Cubemap, i.worldViewDir);
				return fixed4(GetColor(color.rgb), color.a);
			}
			ENDCG
		}
	}
}
