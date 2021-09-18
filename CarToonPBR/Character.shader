// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "YuLongZhi/Character"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Bump("Bump", 2D) = "bump" {}
		_BumpScale("BumpScale", Range(1, 20)) = 1
		_Light1Direction ("Light1Direction", Vector) = (0,0,0,1)
		_Light1Color("Light1Color", Color) = (1, 1, 1, 1)
		_Intensity1("Intensity1(0 close)", Range(0, 10)) = 0
		_Specular ("Specular", Range(0.01, 2)) = 0
		_Gloss ("Gloss(0 close)", Range(0,10)) = 0
		_SpecularMap("Specular", 2D) = "white"{}
		_Light2Direction("Light2Direction", Vector) = (0, 0, 0, 1)
		_Light2Color("Light2Color", Color) = (1, 1, 1, 1)
		_Intensity2("Intensity2(0 close)", Range(0, 10)) = 0
		_CubeMap("Sky Box", CUBE) = ""{}
		_RefMap("Ref", 2D) = "white"{}
		_RefIntensity("Ref Intensity(0 close)", Range(0, 10)) = 0
		_Metallic("Metallic", Range(0, 1)) = 0
	}
	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
		}
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma fragmentoption ARB_precision_hint_fastest
			
			#include "UnityCG.cginc"
			#include "UnityStandardUtils.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float3 viewDirWorld : COLOR1;
				float3 ref : COLOR2;
				float3 inDir : COLOR3;
				float3 nWorld : COLOR4;
				float4 TtoW0 : TEXCOORD2;
				float4 TtoW1 : TEXCOORD3;
				float4 TtoW2 : TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Bump;
			float _BumpScale;
			float3 _Light1Direction;
			float3 _Light1Color;
			float _Intensity1;
			float _Specular;
			float _Gloss;
			sampler2D _SpecularMap;
			float4 _SpecularMap_ST;
			float3 _Light2Direction;
			float3 _Light2Color;
			float _Intensity2;
			samplerCUBE  _CubeMap;
			float4 _CubeMap_ST;
			sampler2D _RefMap;
			float4 _RefMap_ST;
			float _RefIntensity;
			float _Metallic;
			
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				float3 posWorld = mul(unity_ObjectToWorld, v.vertex);
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);
				o.nWorld = normalWorld;

				o.viewDirWorld = normalize(_WorldSpaceCameraPos.xyz - posWorld.xyz);// world space

				o.inDir = normalize(posWorld.xyz - _WorldSpaceCameraPos.xyz);
				o.ref = reflect(o.inDir, normalWorld);

                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				float3 worldBinormal = cross(normalWorld, worldTangent) * v.tangent.w;

				//切线空间到世界空间矩阵
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, normalWorld.x, posWorld.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, normalWorld.y, posWorld.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, normalWorld.z, posWorld.z);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				float4 n = tex2D(_Bump, i.uv);
				/*n.xy = (n.wy * 2 - 1);
				n.xy *= _BumpScale;
				n.z = sqrt(1.0 - saturate(dot(n.xy, n.xy)));*/
				n.xyz = UnpackScaleNormal(n, _BumpScale);

				float3 nWorld = normalize(float3(dot(i.TtoW0.xyz, n), dot(i.TtoW1.xyz, n), dot(i.TtoW2.xyz, n)));//切线空间到世界空间

				float3 ld1 = normalize(_Light1Direction);//假灯1
				float3 h1 = normalize(ld1 + nWorld);
	
				float diff1 = max(0, dot(nWorld, ld1));
	
				float nh1 = max(0, dot(nWorld, h1));
				float spec1 = pow(nh1, _Specular*128.0) * _Gloss;

				float3 ld2 = normalize(_Light2Direction);//假灯2
				float3 h2 = normalize(ld2 + i.viewDirWorld);

				float diff2 = max(0, dot(nWorld, ld2));

				float nh2 = 0;
				if (dot(i.nWorld, h2) > 0.5)
				{
					nh2 = 1;
				}
				else
				{
					nh2 = 0;
				}

				diff2 = diff2;

				float4 s = tex2D(_SpecularMap, i.uv);

				float4 refW = tex2D(_RefMap, i.uv);
				//float ww = (refW.r + refW.g + refW.b) / 3;

				float3 refd1 = reflect(i.inDir, nWorld);
				float4 refcol = texCUBE(_CubeMap, refd1);
				refcol.rgb = DecodeHDR(refcol, unity_SpecCube0_HDR);
				refcol = refcol * _RefIntensity * refW.r;

				float4 resultRGBnl = col;
				float3 CubemapM = col * refcol;
				float3 CubemapN = lerp(refcol, col + refcol * unity_ColorSpaceDielectricSpec.rgb, col.a);
				refcol = fixed4(lerp(CubemapN, CubemapM, _Metallic).rgb, col.a + refcol.a);

				col = lerp(resultRGBnl, refcol, refW.r);//反光效果

				col.rgb = col + col * _Light1Color * diff1 * _Intensity1 + _Light1Color * s.rgb * spec1 + col * _Light2Color * diff2 * _Intensity2;

				return col;
			}
			ENDCG
		}
	}
}
