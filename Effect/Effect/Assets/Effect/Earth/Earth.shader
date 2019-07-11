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
		_NightColor("NightColor", Color) = (1, 1, 1, 1)
		_CloudMap("Cloud Map", 2D) = "white" {}
		_NightBlurCenterWeight("NightBlurCenterWeight",Range(0,1)) = 1
		_NightBlurScale("NightBlurScale",Float) = 1
		_TransitionWidth("Transition Width", Range(0.1, 0.5)) = 0.15
	}
    SubShader
    {
        Pass
        {
			Tags { "LightMode" = "ForwardBase"}

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
			half4 _NightMap_TexelSize;
			sampler2D _CloudMap;
			float _BumpScale;
			float _HeightScale;
			float _TransitionWidth;
			fixed4 _NightColor;
			float _NightBlurCenterWeight;
			float _NightBlurScale;

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

			fixed3 NightBlur(float NLFactor, float2 uv)
			{
				fixed3 night = _NightColor * max(0, -(NLFactor - (0.5 - 0.5 * _TransitionWidth)) / (0.5 - 0.5 * _TransitionWidth)) * tex2D(_NightMap, uv).rgb;
				fixed3 blur = night * _NightBlurCenterWeight;
				float blurWeight = (1 - _NightBlurCenterWeight) / 4;
				blur += tex2D(_NightMap, uv + float2(0, _NightMap_TexelSize.y) * _NightBlurScale) * blurWeight;
				blur += tex2D(_NightMap, uv - float2(0, _NightMap_TexelSize.y) * _NightBlurScale) * blurWeight;
				blur += tex2D(_NightMap, uv + float2(_NightMap_TexelSize.x, 0) * _NightBlurScale) * blurWeight;
				blur += tex2D(_NightMap, uv - float2(_NightMap_TexelSize.x, 0) * _NightBlurScale) * blurWeight;

				return blur;
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
				fixed3 night = _NightColor * max(0, -(NLFactor - (0.5 - 0.5 * _TransitionWidth)) / (0.5 - 0.5 * _TransitionWidth)) * tex2D(_NightMap, i.uv + parallaxOffset).rgb;
				fixed3 cloud = min(1,0.1 + Luminance(NightBlur(NLFactor, i.uv + parallaxOffset)) + NLFactor) * tex2D(_CloudMap, i.uv);
				
				fixed4 color = fixed4(diffuse + night + cloud, 1.0);

				return color;
			}
            ENDCG
        }
    }
		FallBack "Diffuse"
}
