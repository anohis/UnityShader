Shader "Custom/Earth"
{
    Properties
    {
		_Color("Color", Color) = (1, 1, 1, 1) 
		_MainTex("Texture", 2D) = "white" {}
		_BumpMap("Normap Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		_HeightMap("Height Map", 2D) = "white" {}
		_HeightScale("Height Scale", float) = 0
		_NightMap("Night Map", 2D) = "white" {}
		_CloudMap("Cloud Map", 2D) = "white" {}

		_AtmosphereColorMap("Atmosphere Color Map", 2D) = "white" {}
		_ViewPower("View Power", Float) = 5
		_TransitionWidth("Transition Width", Range(0.1, 0.5)) = 0.15
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

			static const float PI = 3.14159265f;

			fixed4 _Color;
			sampler2D _MainTex;
			sampler2D _BumpMap;
			sampler2D _HeightMap;
			sampler2D _NightMap;
			sampler2D _CloudMap;
			float _BumpScale;
			float _HeightScale;
			float _TransitionWidth;

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
				float2 uv : TEXCOORD0;
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
				float3 viewDir : TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				TANGENT_SPACE_ROTATION;

				o.viewDir = mul(rotation, normalize(ObjSpaceViewDir(v.vertex))).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
			{
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 worldNormal = fixed3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z);

				fixed3 tangentViewDir = normalize(i.viewDir);

				float height = tex2D(_HeightMap, i.uv);
				float2 parallaxOffset = ParallaxOffset(height, _HeightScale, tangentViewDir);

				fixed3 newNormalDir = UnpackNormal(tex2D(_BumpMap, i.uv + parallaxOffset));
				newNormalDir.xy *= _BumpScale;
				newNormalDir.z = sqrt(1.0 - saturate(dot(newNormalDir.xy, newNormalDir.xy)));
				newNormalDir = normalize(half3(dot(i.TtoW0.xyz, newNormalDir), dot(i.TtoW1.xyz, newNormalDir), dot(i.TtoW2.xyz, newNormalDir)));

				float angleNL = acos(dot(worldLightDir, newNormalDir)) / PI;
				float NLFactor = max(0, 1 - angleNL - (0.5 - 0.5 * _TransitionWidth)) / (1 - 0.5 * _TransitionWidth);
				
				fixed3 diffuse = NLFactor * tex2D(_MainTex, i.uv + parallaxOffset).rgb;
				fixed3 cloud = tex2D(_CloudMap, i.uv);
				fixed3 night = max(0, -(NLFactor - (0.5 - 0.5 * _TransitionWidth)) / (0.5 - 0.5 * _TransitionWidth)) * (1 - cloud.r) * tex2D(_NightMap, i.uv + parallaxOffset).rgb;
				cloud *= NLFactor;

				fixed4 color = fixed4(diffuse + night + cloud, 1.0);

				return color;
			}
            ENDCG
        }
		
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			Cull Back
			Zwrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#include "Lighting.cginc" 

			static const float PI = 3.14159265f;
			
			sampler2D _AtmosphereColorMap;
			float _ViewPower;
			float _TransitionWidth;

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
				o.pos = UnityObjectToClipPos(v.vertex + 0.2 * v.normal);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(worldPos);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 worldNormal = normalize(i.worldNormal);
				float3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 worldViewDir = normalize(i.worldViewDir);

				float angleNL = acos(dot(worldLightDir, worldNormal)) / PI;
				float NLFactor = 1 - max(0, min(1, (angleNL - 0.5) / _TransitionWidth));
				float angleNV = acos(dot(worldNormal, worldViewDir)) / PI;
				float angleLV = acos(dot(worldLightDir, worldViewDir)) / PI;
				float NVFactor = pow(angleNV + 0.5, _ViewPower * pow(1 - angleLV, 2));

				fixed4 color = _LightColor0 * NLFactor * NVFactor;
				color = color * tex2D(_AtmosphereColorMap, float2(angleNL, 0));

				return color;
			}
			ENDCG
		}
    }
}
