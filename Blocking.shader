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

		_BlockColor("BlockColor",Color) = (0,0,0,0)
		_BlockUnit("BlockUnit",Range(0.0001,1)) = 0.05
		_BlockClip("BlockClip",Float) = 1
		_BlockClipCenter("BlockClipCenter",Vector) = (0,0,0)
		_Offset("BlockOffset",Range(0,1)) = 0.001

		_BeamStep("BeamStep",Range(0 ,1)) = 0
		_EffectRadius("EffectRadius" ,Float) = 3
		_EffectHideRate("EffectHideRate",Range(0,1)) = 0.5
		_EffectShowRate("EffectShowRate",Range(0,1)) = 0.8
		_EffectPosition("EffectPosition" ,Vector) = (0,1,0)
		_EffectDirection("EffectDirection",Vector) = (0,1.5,0,0)
		_EffectStretchPower("EffectStretchPower",Vector) = (1,1,1,1)
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
			fixed4 _BlockColor;
			float _BlockUnit;
			float _BlockClip;
			float _TotalClip;
			float3 _BlockClipCenter;
			float _Offset;

			float _BeamStep;
			float _EffectRadius;
			float _EffectHideRate;
			float _EffectShowRate;
			float3 _EffectPosition;
			float4 _EffectDirection;
			float4 _EffectStretchPower;
			float _BeamCount;

			struct a2v
			{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex  : SV_Position;
				float2 uv : TEXCOORD0;
				float4 rawVertex : TEXCOORD1;
			};

			v2f vert(a2v v)
			{
				v2f o;

				o.vertex = v.vertex;
				o.rawVertex = v.vertex;
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				return o;
			}

			float rand(float3 myVector) 
			{
				return frac(sin(dot(myVector, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
			}

			v2f Create(float4 originalPos,float4 offset, float2 uv)
			{
				float dist = length(_EffectPosition - originalPos.xyz);
				float rate = dist / _EffectRadius;
				rate = saturate((rate - _EffectHideRate) / (_EffectShowRate - _EffectHideRate));
			
				float4 p = originalPos + offset;
				float size = step(1, max(rate, step(_BeamCount, rand(originalPos)))) * saturate(rate * 4);
				p = lerp(originalPos, p, size);
				p = p + step(0.00001, size) * saturate(1 - rate) * rand(originalPos) * _EffectDirection;
				p = p + step(0.00001, size) * sin(rate * 3.14) * rand(originalPos) * _EffectStretchPower * offset;

				v2f o;

				o.vertex = UnityObjectToClipPos(p);
				o.uv = uv;
				o.rawVertex = originalPos + offset;

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
				float4 original = floor(center / _BlockUnit) * _BlockUnit + _Offset;
				float2 centerUV = (input[0].uv + input[1].uv + input[2].uv) / 3;
				float unit = _BlockUnit - 2 * _Offset;

				_EffectRadius = _EffectRadius * (_BeamStep + 0.000000000001);

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
				clip(_BlockClip + length(_BlockClipCenter) - length(_BlockClipCenter - floor(i.rawVertex.xyz / _BlockUnit) * _BlockUnit));
				fixed4 texColor = tex2D(_MainTex, i.uv);
				return texColor + _BlockColor;
			}

			ENDCG
		}
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma multi_compile_fwdbase

			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			float _HalfLambertPower;
			fixed4 _Specular;
			float _Gloss;
			
			float _BlockClip;
			float _BlockUnit;
			float3 _BlockClipCenter;
			fixed4 _BlockColor;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex  : SV_Position;
				float4 uv : TEXCOORD0;
				float4 rawVertex : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				float4 worldPos : TEXCOORD3;
				float3 worldTangent : TEXCOORD4;
				float3 worldBinormal : TEXCOORD5;
				half3 sh : TEXCOORD6;
			};

			v2f vert(a2v v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.rawVertex = v.vertex;

				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldBinormal = cross(o.worldNormal, o.worldTangent) * v.tangent.w;

				o.sh = 0;
				#ifdef LIGHTMAP_OFF
					#if UNITY_SHOULD_SAMPLE_SH
						o.sh = 0;
						#ifdef VERTEXLIGHT_ON
							o.sh += Shade4PointLights (
								unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
								unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
								unity_4LightAtten0, o.worldPos, o.worldNormal);
						#endif
						o.sh = ShadeSHPerVertex (o.worldNormal, o.sh);
					#endif
                #endif

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float show = _BlockClip + length(_BlockClipCenter) - length(_BlockClipCenter - floor(i.rawVertex.xyz / _BlockUnit) * _BlockUnit);
				clip(-show);

				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));

				float3 TtoW0 = float3(i.worldTangent.x, i.worldBinormal.x, i.worldNormal.x);
				float3 TtoW1 = float3(i.worldTangent.y, i.worldBinormal.y, i.worldNormal.y);
				float3 TtoW2 = float3(i.worldTangent.z, i.worldBinormal.z, i.worldNormal.z);

				bump = normalize(half3(dot(TtoW0, bump), dot(TtoW1, bump), dot(TtoW2, bump)));

				fixed halfLambert = saturate(dot(worldLightDir, bump)) * (1 - _HalfLambertPower) + _HalfLambertPower;
				fixed4 texColor = tex2D(_MainTex, i.uv);
				fixed3 albedo = texColor.rgb * _Color.rgb;
				fixed3 diffuse = _LightColor0.rgb * albedo * halfLambert;
				fixed3 halfDir = normalize(worldLightDir + worldViewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(bump, halfDir)), _Gloss);
			
				fixed3 color = diffuse + specular;

				#if UNITY_SHOULD_SAMPLE_SH
					color += i.sh;
				#endif

				return fixed4(color, _Color.a);
			}

			ENDCG
		}
		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }

			Blend One One

			CGPROGRAM

			#pragma multi_compile_fwdadd

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			float _HalfLambertPower;
			fixed4 _Specular;
			float _Gloss;
			
			float _BlockClip;
			float _BlockUnit;
			float3 _BlockClipCenter;
			fixed4 _BlockColor;
			
			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f 
			{
				float4 vertex  : SV_Position;
				float4 uv : TEXCOORD0;
				float4 rawVertex : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				float4 worldPos : TEXCOORD3;
				float3 worldTangent : TEXCOORD4;
				float3 worldBinormal : TEXCOORD5;
				half3 sh : TEXCOORD6;
			};

			v2f vert(a2v v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.rawVertex = v.vertex;

				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldBinormal = cross(o.worldNormal, o.worldTangent) * v.tangent.w;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float show = _BlockClip + length(_BlockClipCenter) - length(_BlockClipCenter - floor(i.rawVertex.xyz / _BlockUnit) * _BlockUnit);
				clip(-show);

				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				#ifdef USING_DIRECTIONAL_LIGHT
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
				#endif

				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));

				float3 TtoW0 = float3(i.worldTangent.x, i.worldBinormal.x, i.worldNormal.x);
				float3 TtoW1 = float3(i.worldTangent.y, i.worldBinormal.y, i.worldNormal.y);
				float3 TtoW2 = float3(i.worldTangent.z, i.worldBinormal.z, i.worldNormal.z);

				bump = normalize(half3(dot(TtoW0, bump), dot(TtoW1, bump), dot(TtoW2, bump)));

				fixed halfLambert = saturate(dot(worldLightDir, bump)) * (1 - _HalfLambertPower) + _HalfLambertPower;
				fixed4 texColor = tex2D(_MainTex, i.uv);
				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 diffuse = _LightColor0.rgb * albedo * halfLambert;
				fixed3 halfDir = normalize(worldLightDir + worldViewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(bump, halfDir)), _Gloss);
				
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;
				#else
					#if defined (POINT)
						float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos.xyz, 1)).xyz;
						fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
					#elif defined (SPOT)
						float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos.xyz, 1));
						fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
					#else
						fixed atten = 1.0;
					#endif
				#endif

				return fixed4((diffuse + specular) * atten, 1.0);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
