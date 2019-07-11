Shader "Custom/GodRay"
{
	Properties
	{
		_MainTex("Main Tex", 2D) = "white" {}
		_MaskTex("Mask Tex", 2D) = "white" {}
		_RadialSampleCount("Radial Sample Count", Float) = 6
	}
	SubShader
	{
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _MaskTex;
			float4 _ViewPortLightPos;
			float _LightAttenuation;
			float _LuminancePower;
			float _LuminanceThreshold;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 color = tex2D(_MainTex, i.uv);
				float depth = tex2D(_MaskTex, i.uv);

				float disFromLight = 1 - saturate(length(_ViewPortLightPos.xy - i.uv) / pow(2, 0.5));
				float disFactor = pow(disFromLight, _LightAttenuation);

				float luminance = Luminance(color.rgb);
				luminance = saturate(luminance * sign(luminance - _LuminanceThreshold));
				//luminance = pow(luminance, _LuminancePower);
				luminance *= depth * disFactor;

				return fixed4(luminance, luminance, luminance, 1);
			}
			ENDCG
		}

		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float _RadialSampleCount;
			float4 _ViewPortLightPos;
			float4 _BlurOffsetScale;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 blurOffset : TEXCOORD1;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.blurOffset = _BlurOffsetScale * (_ViewPortLightPos.xy - o.uv);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				half4 color = half4(0,0,0,0);
				for (int j = 0; j < _RadialSampleCount; j++)
				{
					color += tex2D(_MainTex, i.uv.xy);
					i.uv.xy += i.blurOffset;
				}

				return color / _RadialSampleCount;
			}

				ENDCG
		}

		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _BlurTex;
			fixed4 _LightColor;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.uv;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 ori = tex2D(_MainTex, i.uv);
				fixed4 blur = tex2D(_BlurTex, i.uv);
				return blur  *_LightColor;
			}
			ENDCG
		}
	}
}
