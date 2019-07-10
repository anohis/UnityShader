Shader "Custom/MaskGen"
{
	CGINCLUDE
#include "UnityCG.cginc"
		fixed4 frag_maskGen(v2f_img i) : SV_Target
	{
		return fixed4(0, 0, 0, 1.0f);
	}
		ENDCG


		SubShader
	{
		Tags
		{
			"Queue" = "Geometry"
			"RenderType" = "Opaque"
		}

			Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Lighting Off
			Fog{ Mode Off }

			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag_maskGen
			ENDCG
		}
	}

}
