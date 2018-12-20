Shader "Custom/Dissolving"
{
	Properties
	{
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex("Texture", 2D) = "white" {}
		_BumpMap("NormalMap", 2D) = "white" {}
		_BumpScale ("Bump", Float) = 1.0
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(0.0, 256)) = 20

		_Cutoff("Alpha cutoff", Range(0.000000,1.000000)) = 0.300000

		_Octaves("Octaves", Float) = 1
		_Frequency("Frequency", Float) = 2.0
		_Amplitude("Amplitude", Float) = 1.0
		_Lacunarity("Lacunarity", Float) = 1
		_Persistence("Persistence", Float) = 0.8
		_Offset("Offset", Vector) = (0.0, 0.0, 0.0, 0.0)

		_DissolveDistance("DissolveDistance", Float) = 0.5
		_DissolveDistancePower("DissolveDistancePower",  Float) = 1.0
		_IntensityX("IntensityX", Range(0,1)) = 1.0
		_IntensityY("IntensityY", Range(0,1)) = 1.0
	}

	SubShader
	{
		Pass
		{
			Tags{"LightMode" = "ForwardBase"}

			Cull off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma glsl
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "Noise.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			float _Cutoff;

			fixed _Octaves;
			float _Frequency;
			float _Amplitude;
			float3 _Offset;
			float _Lacunarity;
			float _Persistence;

			float _Scale;
			half _Glossiness;

			float _DissolveDistance;
			float _DissolveDistancePower;
			half _IntensityX;
			half _IntensityY;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
				float depth : TEXCOORD4;
				float3 worldTangent : TEXCOORD5;
				float3 worldBinormal : TEXCOORD6;
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldBinormal = cross(o.worldNormal, o.worldTangent) * v.tangent.w;
				
				o.screenPos = ComputeScreenPos(o.pos);
				o.depth = length(o.worldPos.xyz - _WorldSpaceCameraPos.xyz);
				return o;
			}


			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));

				float3 TtoW0 = float3(i.worldTangent.x, i.worldBinormal.x, i.worldNormal.x);
				float3 TtoW1 = float3(i.worldTangent.y, i.worldBinormal.y, i.worldNormal.y);
				float3 TtoW2 = float3(i.worldTangent.z, i.worldBinormal.z, i.worldNormal.z);

				bump = normalize(half3(dot(TtoW0, bump), dot(TtoW1, bump), dot(TtoW2, bump)));

				fixed4 texColor = tex2D(_MainTex, i.uv);
				clip(texColor.a - _Cutoff);

				fixed3 albedo = texColor.rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, worldLightDir));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);
				
				half deepValue = saturate(( i.depth ) / _DissolveDistance);
				
				const float pi = 3.14159;
				const float tau = pi * 2;
				float2 screenUV = i.screenPos.xy / i.screenPos.w;
				float cosX = clamp(0.0, 1.0, cos(clamp(0.0, pi, screenUV.x * pi - (0.5 * pi))));
				float cosY = clamp(0.0, 1.0, cos(clamp(0.0, pi, screenUV.y * pi - (0.5 * pi))));
				float sceenValue = (cosX * _IntensityX + cosY * _IntensityY) - 1;

				float gradient = PerlinNormal(i.worldPos, _Octaves, _Offset, _Frequency, _Amplitude, _Lacunarity, _Persistence);
			
				clip(gradient + 2 * deepValue - sceenValue * pow((1 - deepValue), _DissolveDistancePower));

				return fixed4(ambient + diffuse + specular, _Color.a);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}