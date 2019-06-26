Shader "Custom/GS-Tail"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		_Cubemap("Cubemap", Cube) = "" {}
		_AlphaMin("AlphaMin", Range(0,1)) = 0
		_AlphaMax("AlphaMax", Range(0,1)) = 1
		_Brightness("Brightness", Float) = 1
		_Saturation("Saturation", Float) = 1
		_Contrast("Contrast", Float) = 1
    }
    SubShader
    {
		Tags{ "Queue" = "Transparent"  "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Pass
		{
			Cull off
			Zwrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Assets/Hsv.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			samplerCUBE _Cubemap;
			float _AlphaMin;
			float _AlphaMax;

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
				fixed4 color = texCUBE(_Cubemap, i.worldViewDir);

				alpha = (alpha - _AlphaMin) / (_AlphaMax - _AlphaMin);
				alpha = min(max(alpha,0),1);
				return fixed4(GetColor(color.rgb), alpha);
			}
			ENDCG
		}
    }
}
