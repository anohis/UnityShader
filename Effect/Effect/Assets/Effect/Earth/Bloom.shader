// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Bloom" 
{
	Properties 
	{
		_MainTex ("Main Tex", 2D) = "white" {}
		_Bloom ("Bloom", 2D) = "black" {}
		_LuminanceThreshold ("Luminance Threshold", Float) = 0.5
		_BlurSize ("Blur Size", Float) = 1.0
	}
	SubShader 
	{
		ZTest Always Cull Off ZWrite Off

		Pass
		{  
			CGPROGRAM  
			#pragma vertex vert  
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _Bloom;
			float _LuminanceThreshold;
			float _BlurSize;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
			};
			
			v2f vert(appdata v)
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;

				return o;
			}

			fixed luminance(fixed4 color)
			{
				return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 c = tex2D(_MainTex, i.uv);
				fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);
			
				return c * val;
			}
			ENDCG  
		}
		
		Pass 
		{
			CGPROGRAM
			  
			#pragma vertex vert
			#pragma fragment frag
			  
			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			float _BlurSize;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv[5]: TEXCOORD0;
			};

			v2f vert(appdata v) 
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				half2 uv = v.uv;

				o.uv[0] = uv;
				o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
				o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
				o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
				o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target 
			{
				float weight[3] = {0.4026, 0.2442, 0.0545};
			
				fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
			
				for (int it = 1; it < 3; it++) {
					sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
					sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
				}
			
				return fixed4(sum, 1.0);
			}

			ENDCG  
		}
		
		Pass 
		{  
			CGPROGRAM  
			
			#pragma vertex vert
			#pragma fragment frag
			
			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			float _BlurSize;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				half2 uv[5]: TEXCOORD0;
			};

			v2f vert(appdata v) 
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				half2 uv = v.uv;

				o.uv[0] = uv;
				o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
				o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
				o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
				o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target 
			{
				float weight[3] = {0.4026, 0.2442, 0.0545};
			
				fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
			
				for (int it = 1; it < 3; it++) {
					sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
					sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
				}
			
				return fixed4(sum, 1.0);
			}

			ENDCG
		}

		Pass
		{  
			CGPROGRAM  
			#pragma vertex vert 
			#pragma fragment frag  

			sampler2D _MainTex;
			sampler2D _Bloom;
			float _LuminanceThreshold;
			float _BlurSize;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				half4 uv : TEXCOORD0;
			};

			v2f vert(appdata v) 
			{
				v2f o;
			
				o.pos = UnityObjectToClipPos (v.vertex);
				o.uv.xy = v.uv;
				o.uv.zw = v.uv;
				        	
				return o; 
			}
		
			fixed4 frag(v2f i) : SV_Target 
			{
				return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
			} 
			ENDCG  
		}
	}
	FallBack Off
}