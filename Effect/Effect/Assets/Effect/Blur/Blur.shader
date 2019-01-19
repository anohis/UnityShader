Shader "Custom/Blur" 
{
	Properties
	{
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
	}
	SubShader 
	{
		Pass
		{
			CGPROGRAM
			// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
			#pragma exclude_renderers d3d11
			#pragma glsl
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Assets/Blur.cginc"

			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			float2 _BlurDirection;

			struct a2v
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv[5] : TEXCOORD0;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv[0] = v.texcoord - 2 * _BlurDirection * _MainTex_TexelSize.xy;
				o.uv[1] = v.texcoord - _BlurDirection * _MainTex_TexelSize.xy;
				o.uv[2] = v.texcoord;
				o.uv[3] = v.texcoord + _BlurDirection * _MainTex_TexelSize.xy;
				o.uv[4] = v.texcoord + 2 * _BlurDirection * _MainTex_TexelSize.xy;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float[5] filter = {0.0545,0.2442,0.4026,0.2442,0.0545};
				fixed4 color = fixed4(0,0,0,0);
				color += filter[0] * tex2D(_MainTex, i.uv[0]);
				color += filter[1] * tex2D(_MainTex, i.uv[1]);
				color += filter[2] * tex2D(_MainTex, i.uv[2]);
				color += filter[3] * tex2D(_MainTex, i.uv[3]);
				color += filter[4] * tex2D(_MainTex, i.uv[4]);
				return color;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
