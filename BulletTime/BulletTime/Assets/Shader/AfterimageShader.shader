Shader "Custom/AfterimageShader" 
{
	Properties 
	{
		_MainColor("MainColor", Color) = (1,1,1,1)
		_DissolveLightColor("DissolveLightColor", Color) = (1,1,1,1)
		_Alpha("Alpha",Range(0,1)) = 1

		_DissolvePower("DissolvePower",Range(0,1)) = 0
		_DissolveLightPower("DissolveLightPower",Range(0,1)) = 0
		_DissolveTex("DissolveTex",2D) = "white" {}

		_Step("Step",Range(0 ,1)) = 1
		_SandSize("SandSize",Range(0 ,1)) = 1
		_Radius("Radius" ,Range(0,4)) = 1
		_RadiusPower("RadiusPower" ,Range(0,10)) = 1
		_Position("Position" ,Vector) = (0,0,0)

		_Octaves("Octaves", Float) = 1
		_Frequency("Frequency", Float) = 2.0
		_Amplitude("Amplitude", Float) = 1.0
		_Lacunarity("Lacunarity", Float) = 1
		_Persistence("Persistence", Float) = 0.8
			_Offset("Offset", Vector) = (0.0, 0.0, 0.0, 0.0)
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "Transparent" = "Opaque" }
		Lighting Off
		cull off

		Pass
		{
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Lighting Off
			Cull Off
			Tags{"LightMode" = "Always"}

			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag    
			#pragma geometry geom
			#include "UnityCG.cginc"
			#include "Noise.cginc"

			float4 _MainColor;
			float _Alpha;

			sampler2D _DissolveTex;
			float4 _DissolveTex_ST;
			float4 _DissolveLightColor;
			float _DissolvePower;
			float _DissolveLightPower;

			float _Step;
			float _Radius;
			float _RadiusPower;
			float _SandSize;
			float3 _Position;

			fixed _Octaves;
			float _Frequency;
			float _Amplitude;
			float _Lacunarity;
			float _Persistence;
			float3 _Offset;

			struct a2v
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2g
			{
				float4 vertex : SV_POSITION;
				float4 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct g2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

			v2g vert(a2v v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.uv = v.uv.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
				o.normal = v.normal;
				return o;
			}

			[maxvertexcount(60)]
			void geom(inout TriangleStream <g2f> OutputStream, triangle v2g input[3])
			{
				_Radius = _Radius * (_Step + 0.000000000001);
				_DissolvePower = _DissolvePower * _Step;
				_DissolveLightPower = _DissolveLightPower / 2;

				float4 center = input[0].vertex + input[1].vertex + input[2].vertex;
				center = center / 3;
				float4 normal = input[0].normal + input[1].normal + input[2].normal;
				normal = normal / 3;
				float3 centerWorldPos = mul(unity_ObjectToWorld, center).xyz;
				/*
				float dist = length(_Position - centerWorldPos);
				float rate = saturate(_Radius - dist) / _Radius ;
				float scale = _RadiusPower * rate;
				*/

				float gradient = PerlinNormal(centerWorldPos, _Octaves, _Offset, _Frequency, _Amplitude, _Lacunarity, _Persistence);
				float rate = saturate((_DissolveLightPower - (gradient * 2 - 0.5 - _DissolvePower)) / _DissolveLightPower);
				float scale = _RadiusPower * rate;

				for (int i = 0; i < 3; i++)
				{
					g2f o = (g2f)0;
					float4 vertex = lerp(input[i].vertex, center, saturate(rate + step(0.01, rate) * _SandSize));
					vertex = vertex + scale * normal;
					o.pos = UnityObjectToClipPos(vertex) ;
					o.uv = input[i].uv;
					o.worldPos = mul(unity_ObjectToWorld, vertex).xyz;
					o.worldNormal = mul(input[i].normal, (float3x3)unity_WorldToObject);
					OutputStream.Append(o);
				}
				OutputStream.RestartStrip();
			}

			fixed4 frag(g2f i) : SV_Target
			{
				_DissolvePower = _DissolvePower * _Step;
				_Alpha = _Alpha * (1 - _Step);

				//float dissolve = tex2D(_DissolveTex, i.uv).r;
				float gradient = PerlinNormal(i.worldPos, _Octaves, _Offset, _Frequency, _Amplitude, _Lacunarity, _Persistence);
				float dissolve = gradient * 2 - 0.5;

				clip(dissolve - _DissolvePower);

				fixed4 color;
				color.rgb = lerp(_MainColor, _DissolveLightColor, step(dissolve , _DissolvePower + _DissolveLightPower));
				color.a = _Alpha;

				return color;
			}
			ENDCG
		}
	}
	FallBack "Transparent/VertexLit"
}
