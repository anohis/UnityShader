Shader "Custom/GS"
{
	Properties
	{
		_Cubemap("Cubemap", Cube) = "" {}

		_EdgePower("EdgePower",Float) = 1

		_Brightness("Brightness", Float) = 1
		_Saturation("Saturation", Float) = 1
		_Contrast("Contrast", Float) = 1

		_RefractRatio("Refraction Ratio", Range(0.1, 1)) = 0.5
		_EdgeRefractRatio("Edge Refraction Ratio", Range(0.1, 1)) = 0.5

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
			Stencil
			{
				Ref 2
				Comp always
				Pass replace
			}

			Zwrite Off
			ColorMask 0

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			float _EdgePower;
			
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex - v.normal * _EdgePower);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return fixed4(0,0,0,0);
			}
			ENDCG
		}
		
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Assets/Hsv.cginc"

			samplerCUBE _Cubemap;
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
				fixed4 color = texCUBE(_Cubemap, i.worldRefr);
				return fixed4(GetColor(color.rgb),color.a);
			}
			ENDCG
		}

		Pass
		{
			Stencil
			{
				Ref 2
				Comp NotEqual
				Pass replace
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Assets/Hsv.cginc"
			#include "Assets/Noise.cginc"

			samplerCUBE _Cubemap;
			float _RefractRatio;
			float _EdgePower;
			float _EdgeRefractRatio;

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
				o.pos = UnityObjectToClipPos(v.vertex + _EdgePower * v.normal);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal) * sign(dot(o.worldNormal, o.worldViewDir)), _EdgeRefractRatio);
				o.uv = v.uv;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float noise = PerlinNormal(i.worldPos + _Time.x);
				clip(noise);

				fixed4 color = texCUBE(_Cubemap, i.worldRefr);
				return fixed4(GetColor(color.rgb),color.a);
			}
			ENDCG
		}
	}
}
