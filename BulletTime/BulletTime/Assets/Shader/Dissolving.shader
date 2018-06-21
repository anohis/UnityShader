Shader "Custom/Dissolving"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(0.0, 256)) = 20
		
		//_DissolveTex("DissolveTex",2D) = "white" {}

		_Color1("Bottom Color", Color) = (0,0,0,1)
		_Color2("Top Color", Color) = (1,1,1,1)
		_DissolvePercentage("DissolveDistance", Range(0,1)) = 0.5

		_Octaves("Octaves", Float) = 1
		_Frequency("Frequency", Float) = 2.0
		_Amplitude("Amplitude", Float) = 1.0
		_Lacunarity("Lacunarity", Float) = 1
		_Persistence("Persistence", Float) = 0.8
		_Offset("Offset", Vector) = (0.0, 0.0, 0.0, 0.0)
		_Size("Radius", Range(0,3)) = 0
		_Intensity("Intensity", Range(0,1)) = 1.0
	}

	

	SubShader
	{
		Pass
		{
			Tags{"LightMode" = "ForwardBase"}

			Cull off

			CGPROGRAM
			#pragma glsl
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "Noise.cginc"

			sampler2D _MainTex;
			sampler2D _DissolveTex;
			float4 _MainTex_ST;
			float4 _DissolveTex_ST;
			float _Gloss;
			fixed4 _Specular;
			fixed4 _Color;

			fixed _Octaves;
			float _Frequency;
			float _Amplitude;
			float3 _Offset;
			float _Lacunarity;
			float _Persistence;

			float _Scale;
			float _DissolvePercentage;
			float _DissolvePercentage2;
			half _Glossiness;
			half _Size;
			half _Intensity;
			fixed4 _Color1;
			fixed4 _Color2;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float4 worldPos : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				//算出來的是齊次座標
				o.screenPos = ComputeScreenPos(o.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				/*光照*/
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				//環境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				//漫反射
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				//高光
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				
				/*溶解*/

				/*物件轉向會怪怪的
				float2 uv = i.worldPos.xy + i.worldPos.z * i.worldNormal.xy;
				float dissolve = tex2D(_DissolveTex, uv).r;
				clip(_Intensity - dissolve);
				*/

				//距離
				float dist = length(0 - i.screenPos.z);
				half viewDist = length(dist);
				//可以看成以_DissolvePercentage2為基準，長度以_DissolvePercentage為限制
				half falloff = saturate(( 10 * viewDist ) / _DissolvePercentage);
				//Pi = 180度
				const float pi = 3.14159;
				const float tau = pi * 2;
				float2 screenUV = i.screenPos.xy / i.screenPos.w;
				//表示離畫面中心越遠,數值越低,範圍在0~1
				float sinX = clamp(0.0, 1.0, cos(clamp(0.0, pi, screenUV.x * pi - (0.5 * pi))));
				float sinY = clamp(0.0, 1.0, cos(clamp(0.0, pi, screenUV.y * pi - (0.5 * pi))));
				float2 moddedUV = float2(sinX, sinY) * _Intensity;
				//跟距離畫面中心的距離做_Color1~_Color2平滑
				fixed4 x = saturate(lerp(_Color1, _Color2, pow(moddedUV.x, _Size)) * lerp(_Color1, _Color2, pow(moddedUV.y, _Size)));
				float _Dissolve = x.r * (falloff);
				float gradient = PerlinNormal(i.worldPos, _Octaves, _Offset, _Frequency, _Amplitude, _Lacunarity, _Persistence);
				float dissolve = 3 * _Dissolve - 1.5;
				clip(gradient - dissolve);

				return fixed4(ambient + diffuse + specular, 1.0);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
