// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/CircleRange"
{
    Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_Angle("Angle", Range(0, 180)) = 60
		_LineColor("LineColor", Color) = (1,1,1,1)
		_LineWidth("LineWidth", Range(0, 0.5)) = 0
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float4 _LineColor;
			sampler2D _MainTex;
			float4 _Color;
			float _Angle;
			float _LineWidth;

			struct fragmentInput 
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXTCOORD0;
			};

			fragmentInput vert(appdata_base v)
			{
				fragmentInput o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;

				return o;
			}

			fixed4 frag(fragmentInput i) : SV_Target
			{
				fixed angle = _Angle * 0.017453;
				fixed otherAngle = max(_Angle - 90, 0) * 0.017453;

				fixed cosAngle = cos(angle);
				fixed cosOtherAngle = cos(otherAngle);
				fixed2 dir = i.uv - 0.5;
				fixed distance = sqrt(pow(dir.x, 2) + pow(dir.y, 2));
				fixed cosDir = dir.x / distance;

				clip(saturate(sign(0.5 - distance)) * saturate(sign(cosDir - cosAngle)) - 0.1);

				fixed len = min(abs(_LineWidth / (sin(angle) + 0.00000001)), 0.5);
				fixed2 newDir = dir;
				newDir.x = newDir.x - len;
				fixed newCosDir = newDir.x / sqrt(pow(newDir.x, 2) + pow(newDir.y, 2));

				fixed colorPar = saturate(sign(0.5 - _LineWidth - distance)) * min(1, saturate(sign(distance - _LineWidth)) * saturate(sign(cosDir - cosOtherAngle)) + saturate(sign(newCosDir - cosAngle)));

				fixed4 result = tex2D(_MainTex, i.uv) * _Color *  colorPar + (1 - colorPar) * _LineColor;

				return result;
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
