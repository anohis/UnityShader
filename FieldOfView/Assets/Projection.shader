Shader "Custom/Projection" 
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			Tags{ "RenderType" = "Transparent" }
			LOD 200
			ZWrite off
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag  
			#include "UnityCG.cginc"  

			sampler2D _MainTex;
			float4x4 unity_Projector;

			struct v2f
			{
				float4 pos:SV_POSITION;
				float4 texc:TEXCOORD0;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.texc = mul(unity_Projector,v.vertex);
				return o;
			}

			float4 frag(v2f o) :COLOR
			{
				float4 c = tex2Dproj(_MainTex,o.texc);
				c = c*step(0,o.texc.w);
				return c;
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
