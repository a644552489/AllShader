Shader "HLE/HLE_Common"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Normal ("Normal", 2D) = "bump" {}
		_CubeMap ("Cube Map", CUBE) = "" {}
		_SpecMap("Spec Map", 2D) = "white" {}
		_RefMap("Ref Map", 2D) = "white" {}
		_SmoothnessMap("Smoothness Map", 2D) = "white" {}
		_EmissiveMap("Emissive Map", 2D) = "white" {}
		_Spec ("Spec", Color) = (0, 0, 0, 0)
		_Ref("Ref", Color) = (0, 0, 0, 0)
		_Smoothness("Smoothness", Range(0, 1)) = 0
		_Emissive("Emissive", Color) = (0, 0, 0, 0)

		_Light1Color ("Light1 Color", Color) = (1, 1, 1, 1)
		_Intensity1 ("Light1 Intensity", Range(0, 10)) = 0
		[HideInInspector] _Light1Direction ("Light1 Direction", Vector) = (1, 1, 1, 1)
		_Light2Color ("Light2 Color", Color) = (1, 1, 1, 1)
		_Intensity2 ("Light2 Intensity", Range(0, 10)) = 0
		[HideInInspector] _Light2Direction ("Light2 Direction", Vector) = (0, 0, 0, 1)

		_Outline_Color("_OutLineColor" , Color) = (1,1,1,1)
		_Outline_Width("_OutLineWidth",Range(0,100)) = 1
		_MaxOutLine("_MaxOutLine", Range(0,5)) = 2
		_MinOutLine("_MinOutLine", Range(0,2)) = 0.5

		_RimColor("边缘光Color", Color) = (1, 1, 1, 1)
		
		_RimPower("边缘光软硬", Range(0, 2)) = 0.3
		_RimStrength("边缘光强度", Float) = 0.5

	
	}

	SubShader
	{
		Tags{"Queue" = "Geometry" "RenderType" = "Opaque" }
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				half3 tspace0 : TEXCOORD2;
				half3 tspace1 : TEXCOORD3;
				half3 tspace2 : TEXCOORD4;
				float3 posWorld : TEXCOORD5;
				SHADOW_COORDS(7)
			};

			//sampler2D unity_NHxRoughness;

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Normal;

			samplerCUBE _CubeMap;
			sampler2D _SpecMap, _RefMap, _SmoothnessMap, _EmissiveMap;
			fixed3 _Spec;
			fixed3 _Ref;
			half _Smoothness;
			fixed3 _Emissive;

			fixed3 _Light1Color;
			float _Intensity1;
			half3 _Light1Direction;
			fixed3 _Light2Color;
			float _Intensity2;
			half3 _Light2Direction;

			
uniform half3 _RimColor;

uniform half _RimPower;
uniform half _RimStrength;

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;

				half3 normal = UnityObjectToWorldNormal(v.normal);
                half3 tangent = UnityObjectToWorldDir(v.tangent.xyz);
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 bitangent = cross(normal, tangent) * tangentSign;

				o.tspace0 = half3(tangent.x, bitangent.x, normal.x);
                o.tspace1 = half3(tangent.y, bitangent.y, normal.y);
                o.tspace2 = half3(tangent.z, bitangent.z, normal.z);

				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}
			inline half2 Pow4(half2 x){return x*x*x*x;}
			half3 GetRimColor(half3 color, half NoV, half intensity, half rimPow)
			{
				half rim = 1 - saturate(abs(NoV));
				rim = pow(rim, 1 / rimPow * 5) * intensity;
				return rim * color;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 c = tex2D(_MainTex, i.uv);
				fixed3 n = UnpackNormal(tex2D(_Normal, i.uv));

				half3 normal;
                normal.x = dot(i.tspace0, n);
                normal.y = dot(i.tspace1, n);
                normal.z = dot(i.tspace2, n);

				normal = normalize(normal);
				
				UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWorld);
				
				half3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
				half3 lightDir = UnityWorldSpaceLightDir(i.posWorld);
				fixed3 lightColor = _Light1Color * _Intensity1;

				fixed3 specColor = _Spec * tex2D(_SpecMap, i.uv).r;
				fixed3 refColor = _Ref * tex2D(_RefMap, i.uv).r;
				half smoothness = _Smoothness * tex2D(_SmoothnessMap, i.uv).r;
				fixed3 emissiveColor = _Emissive * tex2D(_EmissiveMap, i.uv).r;
				half roughness = 1 - smoothness;
				
				half reflectivity = max(max(refColor.r, refColor.g), refColor.b);
				half oneMinusReflectivity = 1 - reflectivity;

				half3 reflDir = reflect(viewDir, normal);
				half nl = saturate(dot(normal, lightDir));
				half nv = saturate(dot(normal, viewDir));
				half nl2 = saturate(dot(normal, normalize(_Light2Direction)));

				half2 rlPow4AndFresnelTerm = Pow4(half2(dot(reflDir, lightDir), 1 - nv));
				half rlPow4 =rlPow4AndFresnelTerm.x;
				half fresnelTerm = rlPow4AndFresnelTerm.y;
				half grazingTerm = saturate(smoothness + reflectivity);


				half LUT_RANGE = 16.0;
				half specular = tex2D(unity_NHxRoughness, half2(rlPow4, roughness)).UNITY_ATTEN_CHANNEL * LUT_RANGE;
				


				fixed3 ambient = 0.5 * c.rgb;
				fixed3 diffuse = ambient +  nl * c.rgb * _LightColor0.rgb * attenuation ; //+ _Light2Color * _Intensity2 * nl2 * c.rgb;
	
		
				fixed3 spec = lightColor * nl * specular * specColor;
				
				half3 reflUVW = reflect(-viewDir, normal);
				
				
				half mip = roughness * (1.7 - 0.7 * roughness) * 6;
#if ((SHADER_TARGET < 25) && defined(SHADER_API_D3D9)) || defined(SHADER_API_D3D11_9X)
				fixed3 env = texCUBEbias(_CubeMap, half4(reflUVW, mip)).rgb;
#else
				fixed3 env = texCUBElod(_CubeMap, half4(reflUVW, mip)).rgb;
#endif
				fixed3 gi = env * lerp(refColor, grazingTerm, fresnelTerm);
			
				c.rgb = diffuse * oneMinusReflectivity + gi + spec;
				
				c.rgb += emissiveColor;

				
				
				c.rgb += GetRimColor(_RimColor , nv , _RimStrength , _RimPower);
				


				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, c);
				return c;
			}
			ENDCG
		}

			Pass
		{
			Name "OUTLNIE"
		//	Blend SrcAlpha OneMinusSrcAlpha
		//	ZWrite off
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#pragma fragmentoption ARB_precision_hint_fastest

			#include "UnityCG.cginc"
			#include "../ToonOutLineCG.cginc"
			ENDCG
		}

		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			ZTest LEqual
			Offset 2,-1

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster novertexlight nolightmap nodirlightmap nodynlightmap noshadowmask nolppv 

			#include "ActorShadow.cginc"
			ENDCG
		}

	}
}
