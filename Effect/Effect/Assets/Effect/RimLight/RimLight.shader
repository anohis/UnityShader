// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/RimLight" {
	Properties
	{
		_Diffuse("Diffuse", Color) = (1,1,1,1)
		_RimColor("RimColor", Color) = (1,1,1,1)
		_RimPower("RimPower", Range(0.000001, 3.0)) = 0.1
		_MainTex("Base 2D", 2D) = "white"{}
		_AlphaPower("AlphaPower", Range(0, 1.0)) = 0
	}

		SubShader
		{
			Tags{ "Queue" = "Transparent"  "IgnoreProjector" = "True" "RenderType" = "Transparent" }
			Pass
			{
				Tags{ "LightMode" = "ForwardBase" }
				Zwrite Off
			    Blend SrcAlpha OneMinusSrcAlpha

				CGPROGRAM
				#include "Lighting.cginc"  
				fixed4 _Diffuse;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				fixed4 _RimColor;
				float _RimPower;
				float _AlphaPower;
				float3 _ViewPos;

				#pragma vertex vert  
				#pragma fragment frag     

				struct a2v 
				{
					float4 vertex : POSITION;
					float4 normal : NORMAL;
					float4 texcoord : TEXCOORD0;
				};

				struct v2f
				{
					float4 pos : SV_POSITION;
					float3 worldNormal : TEXCOORD0;
					float2 uv : TEXCOORD1;
					float3 worldViewDir : TEXCOORD2;
				};

				v2f vert(a2v v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
					float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					//o.worldViewDir = _ViewPos - worldPos;
					//o.worldViewDir = UNITY_MATRIX_IT_MV[2].xyz;
					o.worldViewDir = _WorldSpaceCameraPos - worldPos;
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Diffuse.xyz;
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
					fixed3 lambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
					fixed3 diffuse = lambert * _Diffuse.xyz * _LightColor0.xyz + ambient;
					fixed4 color = tex2D(_MainTex, i.uv);

					float3 worldViewDir = normalize(i.worldViewDir);
					float rim = max(0, dot(worldViewDir, worldNormal));
					fixed3 rimColor = _RimColor * pow(rim, 1 / _RimPower);
					//color.rgb = color.rgb * diffuse + rimColor;
					color.rgb = color.rgb + rimColor;
					color.a = max(0, 1 - rim - _AlphaPower);
					return fixed4(color);
				}
				ENDCG
			}
		}
		FallBack "Transparent/VertexLit"
}
