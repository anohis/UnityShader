Shader "Custom/Blocking" 
{
	Properties 
	{
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("NormalMap", 2D) = "white" {}
		_BumpScale("Bump", Float) = 1.0
		_HalfLambertPower("HalfLambertPower",Range(0,1)) = 0.5
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(0.0, 256)) = 20

		_BlockHeight("EffectHeight", Float) = 20
		_BlockBasePosition("EffectBasePosition",Vector) = (0,0,0)

		_BlockStep("BlockStep",Range(0,1)) = 1

		_BlockColor("BlockColor",Color) = (0,0,0,0)
		_BlockUnit("BlockUnit",Range(0.0001,1)) = 0.05
		_BlockOffset("BlockOffset",Range(0,1)) = 0.001

		_BeamStep("BeamStep",Range(0 ,1)) = 0
		_BeamRadius("EffectRadius" ,Float) = 3
		_BeamMinShowRate("BeamMinShowRate",Range(0,1)) = 0.5
		_BeamMaxShowRate("BeamMaxShowRate",Range(0,1)) = 0.8
		_BeamCenterPosition("EffectPosition" ,Vector) = (0,1,0)
		_BeamDirection("EffectDirection",Vector) = (0,1.5,0,0)
		_BeamStretchPower("EffectStretchPower",Vector) = (1,1,1,1)
		_BeamCount("BeamCount",Range(0,1)) = 0.9
	}
	SubShader 
	{	
		Pass
		{
			Tags { "RenderType" = "Opaque" }

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _BlockStep;
			float _BlockHeight;
			float _BlockUnit;
			float _BlockOffset;
			float3 _BlockBasePosition;
			fixed4 _BlockColor;

			float _BeamStep;
			float _BeamRadius;
			float _BeamMinShowRate;
			float _BeamMaxShowRate;
			float _BeamCount;
			float3 _BeamCenterPosition;
			float4 _BeamDirection;
			float4 _BeamStretchPower;

			struct a2v
			{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex  : SV_Position;
				float2 uv : TEXCOORD0;
				float3 rawWorldPos : TEXCOORD1;
			};

			v2f vert(a2v v)
			{
				v2f o;

				o.vertex = v.vertex;
				o.rawWorldPos = v.vertex.xyz;
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				return o;
			}

			float rand(float3 myVector) 
			{
				return frac(sin(dot(myVector, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
			}

			v2f Create(float4 originalPos,float4 offset, float2 uv)
			{
				float dist = length(_BeamCenterPosition - originalPos.xyz);
				float rate = dist / _BeamRadius;
				rate = saturate((rate - _BeamMinShowRate) / (_BeamMaxShowRate - _BeamMinShowRate));

				float4 p = originalPos + offset;
				float size = step(1, max(rate, step(_BeamCount, rand(originalPos)))) * saturate(rate * 4);
				p = lerp(originalPos, p, size);
				p = p + step(0.00001, size) * saturate(1 - rate) * rand(originalPos) * _BeamDirection;
				p = p + step(0.00001, size) * sin(rate * 3.14) * rand(originalPos) * _BeamStretchPower * offset;

				p = mul(unity_WorldToObject, p);

				v2f o;

				o.vertex = UnityObjectToClipPos(p);
				o.uv = uv;
				o.rawWorldPos = (originalPos + offset).xyz;

				return o;
			}

			void CreateTriangle(v2f p1, v2f p2, v2f p3, inout TriangleStream<v2f> OutputStream)
			{
				OutputStream.Append(p1);
				OutputStream.Append(p2);
				OutputStream.Append(p3);
				OutputStream.RestartStrip();
			}

			[maxvertexcount(64)]
			void geom(triangle v2f input[3], inout TriangleStream<v2f> OutputStream)
			{
				float4 center = (input[0].vertex + input[1].vertex + input[2].vertex) / 3;
				float4 worldPos = mul(unity_ObjectToWorld, center);
				float4 original = (floor(worldPos / _BlockUnit)) * _BlockUnit + _BlockOffset;
				float2 centerUV = (input[0].uv + input[1].uv + input[2].uv) / 3;
				float unit = _BlockUnit - 2 * _BlockOffset;

				_BeamRadius = _BeamRadius * (_BeamStep + 0.000000000001);

				v2f o[8];
				o[0] = Create(original, float4(0, 0, 0, 0), centerUV);
				o[1] = Create(original, float4(0, 0, unit, 0), centerUV);
				o[2] = Create(original, float4(0, unit, unit, 0), centerUV);
				o[3] = Create(original, float4(unit, unit, unit, 0), centerUV);
				o[4] = Create(original, float4(unit, 0, unit, 0), centerUV);
				o[5] = Create(original, float4(unit, 0, 0, 0), centerUV);
				o[6] = Create(original, float4(unit, unit, 0, 0), centerUV);
				o[7] = Create(original, float4(0, unit, 0, 0), centerUV);

				CreateTriangle(o[0], o[1], o[2], OutputStream);
				CreateTriangle(o[7], o[0], o[2], OutputStream);

				CreateTriangle(o[3], o[2], o[1], OutputStream);
				CreateTriangle(o[4], o[3], o[1], OutputStream);

				CreateTriangle(o[4], o[1], o[0], OutputStream);
				CreateTriangle(o[5], o[4], o[0], OutputStream);

				CreateTriangle(o[3], o[4], o[5], OutputStream);
				CreateTriangle(o[3], o[5], o[6], OutputStream);

				CreateTriangle(o[2], o[3], o[6], OutputStream);
				CreateTriangle(o[2], o[6], o[7], OutputStream);

				CreateTriangle(o[7], o[5], o[0], OutputStream);
				CreateTriangle(o[6], o[5], o[7], OutputStream);
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 blockCenter = floor(i.rawWorldPos.xyz / _BlockUnit) * _BlockUnit;
				float distance = length(_BlockBasePosition - blockCenter);

				float rate = distance / _BlockHeight;
				clip(_BlockStep - rate);

				fixed4 texColor = tex2D(_MainTex, i.uv);
				return texColor + _BlockColor;
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
