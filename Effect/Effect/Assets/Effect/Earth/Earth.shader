Shader "Custom/Earth"
{
    Properties
    {
		_Color("Color", Color) = (1, 1, 1, 1) 
		_MainTex("Texture", 2D) = "white" {}
		_BumpMap("Normap Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		_HeightMap("Height Map", 2D) = "white" {}
		_Parallax("Parallax", float) = 0
		_NightMap("Night Map", 2D) = "white" {}
		_AtmosphereColor("AtmosphereColor", Color) = (1, 1, 1, 1)


		_Diffuse("Diffuse", Color) = (1,1,1,1)
		_RimColor("RimColor", Color) = (1,1,1,1)
		_RimPower("RimPower", Range(0.000001, 3.0)) = 0.1
		_AlphaPower("AlphaPower", Range(0, 1.0)) = 0
    }
    SubShader
    {
        Pass
        {
			Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			sampler2D _HeightMap;
			float4 _HeightMap_ST;
			sampler2D _NightMap;
			float4 _NightMap_ST;
			float _BumpScale;
			float _Parallax;

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 uv2 : TEXCOORD1;
				float3 lightDir : TEXCOORD2;
				float3 viewDir : TEXCOORD3;
				float3 normalDir : TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				o.uv2.xy = v.uv.xy * _HeightMap_ST.xy + _HeightMap_ST.zw;
				o.uv2.zw = v.uv.xy * _NightMap_ST.xy + _NightMap_ST.zw;

				TANGENT_SPACE_ROTATION;

				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
				o.normalDir = mul(rotation, v.normal).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);
				fixed3 tangentNormalDir = normalize(i.normalDir);

				float heightTex = tex2D(_HeightMap, i.uv2.xy).r;
				float2 parallaxOffset = ParallaxOffset(heightTex, _Parallax, tangentViewDir);

				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw + parallaxOffset);
				fixed3 tangentNormal;

				tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				fixed3 albedo = tex2D(_MainTex, i.uv.xy + parallaxOffset).rgb * _Color.rgb;
				float dotNL = 0.5 * dot(tangentNormal, tangentLightDir) + 0.5;
				fixed3 diffuse = _LightColor0.rgb * albedo * dotNL;
				fixed3 night = (1 - dotNL) * tex2D(_NightMap, i.uv2.zw + parallaxOffset).rgb;

				return fixed4(diffuse + night, 1.0);
            }
            ENDCG
        }

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			Zwrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#include "Lighting.cginc" 

			fixed4 _Diffuse;
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
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldViewDir : TEXCOORD1;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex + v.normal);
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
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

				float3 worldViewDir = normalize(i.worldViewDir);
				float rim = max(0, dot(worldViewDir, worldNormal));
				fixed3 rimColor = _RimColor * pow(rim, 1 / _RimPower);
				return fixed4(rimColor, max(0, 1 - rim - _AlphaPower));
			}
			ENDCG
		}
    }
}
