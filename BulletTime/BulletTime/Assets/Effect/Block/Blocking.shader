Shader "Custom/Blocking" 
{
	Properties 
	{
		_MainTex("Texture", 2D) = "white" {}
		_MainColor("MainColor", Color) = (1,1,1,1)

		_BlockUnit("BlockUnit" ,Range(0,1)) = 1
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "Transparent" = "Opaque" }
		Lighting Off
		cull off

		Pass
		{
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

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float4 _MainColor;

			float _BlockUnit;

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
				o.uv = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.normal = v.normal;
				return o;
			}

			[maxvertexcount(60)]
			void geom(inout TriangleStream <g2f> OutputStream, triangle v2g input[3])
			{
				float4 center = input[0].vertex + input[1].vertex + input[2].vertex;
				center = center / 3;
				float4 normal = input[0].normal + input[1].normal + input[2].normal;
				normal = normal / 3;
				float3 centerWorldPos = mul(unity_ObjectToWorld, center).xyz;

				for (int count = 0; count < 3; count++)
				{
					g2f o = (g2f)0;
					float4 vertex = input[count].vertex;
					vertex = floor(vertex / _BlockUnit) * _BlockUnit;
					o.pos = UnityObjectToClipPos(vertex) ;
					o.uv = input[count].uv;
					o.worldPos = mul(unity_ObjectToWorld, vertex).xyz;
					o.worldNormal = mul(input[count].normal, (float3x3)unity_WorldToObject);
					OutputStream.Append(o);
				}
				OutputStream.RestartStrip();
			}
			
			fixed4 frag(g2f i) : SV_Target
			{
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _MainColor.rgb;

				return fixed4(albedo, 1.0);
			}
			ENDCG
		}
	}
	FallBack "Transparent/VertexLit"
}
