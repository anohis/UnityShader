Shader "Custom/Dissolving2"
{
	Properties
	{
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
		Tags{ "Queue" = "Transparent" "LightMode" = "ForwardBase"}
		Blend SrcAlpha OneMinusSrcAlpha
		
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

			fixed _Octaves;
			float _Frequency;
			float _Amplitude;
			float3 _Offset;
			float _Lacunarity;
			float _Persistence;

			float _DissolveDistance;
			float _DissolveDistancePower;
			half _IntensityX;
			half _IntensityY;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 worldPos : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
				float depth : TEXCOORD4;
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				//算出來的是齊次座標
				o.screenPos = ComputeScreenPos(o.vertex);
				o.depth = length(o.worldPos.xyz - _WorldSpaceCameraPos.xyz);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				//可以看成長度以_DissolveDistance為限制
				half deepValue = saturate(( i.depth ) / _DissolveDistance);
				
				//Pi = 180度
				const float pi = 3.14159;
				const float tau = pi * 2;
				float2 screenUV = i.screenPos.xy / i.screenPos.w;
				//表示離畫面中心越遠,數值越低,範圍在 -1 ~ 1
				float cosX = clamp(0.0, 1.0, cos(clamp(0.0, pi, screenUV.x * pi - (0.5 * pi))));
				float cosY = clamp(0.0, 1.0, cos(clamp(0.0, pi, screenUV.y * pi - (0.5 * pi))));
				float sceenValue = (cosX * _IntensityX + cosY * _IntensityY) - 1;

				float gradient = PerlinNormal(i.worldPos, _Octaves, _Offset, _Frequency, _Amplitude, _Lacunarity, _Persistence);
			
				float result = gradient + 2 * deepValue - sceenValue * pow((1 - deepValue), _DissolveDistancePower);
				clip(-result);

				return fixed4(1, 0, 0, 0);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
