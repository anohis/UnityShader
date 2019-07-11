Shader "Custom/Atmosphere"
{
    Properties
    {
		_AtmosphereColorMap("Atmosphere Color Map", 2D) = "white" {}
		_ViewPower("View Power", Float) = 5
		_TransitionWidth("Transition Width", Range(0.1, 0.5)) = 0.15
    }
    SubShader
    {
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			Cull Back
			Zwrite Off
			//Blend SrcAlpha OneMinusSrcAlpha
			Blend one one

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
