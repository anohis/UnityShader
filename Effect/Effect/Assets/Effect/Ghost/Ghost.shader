Shader "Custom/Ghost" 
{
	Properties 
	{
		_MainColor("MainColor", Color) = (1,1,1,1)
		_DissolveLightColor("DissolveLightColor", Color) = (1,1,1,1)
		_Alpha("Alpha",Range(0,1)) = 1

		_DissolvePower("DissolvePower",Range(0,1)) = 0
		_DissolveLightPower("DissolveLightPower",Range(0,1)) = 0

		_Step("Step",Range(0 ,1)) = 1
		_SandSize("SandSize",Range(0 ,1)) = 1
		_SandRange("SandRange" ,Range(0,4)) = 1
		_SandRangePower("SandRangePower" ,Range(0,10)) = 1

		_Amplitude("Amplitude", Float) = 1.0
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
			#include "Assets/Noise.cginc"

			float4 _MainColor;
			float _Alpha;

			float4 _DissolveLightColor;
			float _DissolvePower;
			float _DissolveLightPower;

			float _Step;
			float _SandRange;
			float _SandRangePower;
			float _SandSize;

			float _Amplitude;

			struct a2v
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
			};

			struct v2g
			{
				float4 vertex : SV_POSITION;
				float4 normal : NORMAL;
			};

			struct g2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			v2g vert(a2v v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.normal = v.normal;
				return o;
			}

			float GetDissolve(float3 pos)
			{
				float gradient = PerlinNormal(pos, 1, float3(0,0,0), 1, _Amplitude, 1, 1);
				float dissolve = (gradient /_Amplitude  + 1) * 0.5;
				return dissolve;

			}

			[maxvertexcount(60)]
			void geom(inout TriangleStream <g2f> OutputStream, triangle v2g input[3])
			{
				float dissolvePower = _DissolvePower * _Step;
				_SandRange = _SandRange * (_Step + 0.000000000001);

				float4 center = input[0].vertex + input[1].vertex + input[2].vertex;
				center = center / 3;
				float4 normal = input[0].normal + input[1].normal + input[2].normal;
				normal = normal / 3;
				float3 centerWorldPos = mul(unity_ObjectToWorld, center).xyz;
				
				float dissolve = GetDissolve(centerWorldPos);
				float rate = 1 - saturate((dissolve-dissolvePower) / _SandRange);
				float scale = _SandRangePower * rate;
				
				for (int i = 0; i < 3; i++)
				{
					g2f o = (g2f)0;
					float4 vertex = lerp(input[i].vertex, center, saturate(rate + step(0.01, rate) * _SandSize));
					vertex = vertex + scale * normal;
					o.pos = UnityObjectToClipPos(vertex) ;
					o.worldPos = mul(unity_ObjectToWorld, vertex).xyz;
					o.worldNormal = mul(input[i].normal, (float3x3)unity_WorldToObject);
					OutputStream.Append(o);
				}
				OutputStream.RestartStrip();
			}

			fixed4 frag(g2f i) : SV_Target
			{
				float dissolvePower = _DissolvePower * _Step;
				_Alpha = _Alpha * (1 - _Step);

				float dissolve = GetDissolve(i.worldPos);

				clip(dissolve-dissolvePower);

				fixed4 color;
				color.rgb = lerp(_MainColor, _DissolveLightColor, step(dissolve , dissolvePower + _DissolveLightPower));
				color.a = _Alpha;

				return color;
			}
			ENDCG
		}
	}
	FallBack "Transparent/VertexLit"
}
