// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/Hero/VF-CubeBumpSpe_zhanshiv2"
{
	Properties
	{
		_Color("Main Color", Color) = (1,1,1,1)
		_MainTex("Main Mapping(RGB)", 2D) = "white" {}

	_Bump("Bump", 2D) = "bump" {}
	//_tex1("tex1",2D) = "white" {}
	_BumpPow("Bump Pow", float) = 0.5

		_SpePow("Spe Pow", float) = 12.0
		_SpeRange("Spe Range", float) = 20.0
		_speColor("speColor", Color) = (1,1,1,1)
		_BSpePow("B_Spe Pow", float) = 12.0
		_BSpeColor("B_Spe Color", Color) = (1,1,1,1)
		_BSpeRange("B_Spe Range", float) = 20.0

		_Cubemap("CubeMap", CUBE) = ""{}
	_CubemapPow("CubemapPow", float) = 1.0

		_Spe("Spe", 2D) = "white" {}

	


	//_GlossMap ("Gloss Map", 2D) = "white" {}

	[Toggle] _texorcol("GlowCol?????", Float) = 0
		_Glow("Glow", 2D) = "white" {}
	_Glowcolor("Glowcolor",color) = (1,1,1,1)
		//[Space(20)]

		//_GlowAlpha ("Glow Alpha", 2D) = "white" {}
		_GlowOffsetX("Glow Offset x", float) = 0.0
		_GlowOffsetY("Glow Offset Y", float) = 0.0
		_GlowPow("Glow Pow", float) = 0.0



		_OutlineColor("Top Outline Color", Color) = (1,1,1,1)
		_Outlinescale("Top Outline scale",float) = 1.1
		_Outline("Top Outline width", float) =2.5
		_OutlineMask("Top OutlineMask Y",float) =2.5

		
		//_DisintegrateTex  ("Disintegrate", 2D) = "white" {}
		//_EdgeColor("Edge Color", Color) = (1.0,0.5,0.2,0.0)
		//_EdgeRange("Edge Range",Range(0.0,0.1)) = 0.002
		//_DisintegrateAmount("Disintegrate Amount", Range(-1.0,1.0)) = 0
	}

		SubShader
	{
		Tags
	{
		"Queue" = "Geometry"
		"RenderType" = "Opaque"
	}

		Pass
	{
		Tags
	{
		"LightMode" = "ForwardBase"
	}

		LOD 200

		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile_fwdbase
#pragma fragmentoption ARB_precision_hint_fastest
#pragma shader_feature _TEXORCOL_ON
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

		float4 _Color;
	float4 _speColor;
	float4 _Glowcolor;
	float4 _MainTex_ST;
	sampler2D _MainTex;
	//float4 _tex1_ST;
	//sampler2D _tex1;

	sampler2D _Bump;
	float _BumpPow;

	float _SpePow;
	float _SpeRange;
	float _BSpePow;
	float4 _BSpeColor;
	float _BSpeRange;

	samplerCUBE _Cubemap;
	float _CubemapPow;

	sampler2D _Spe;

	//sampler2D _GlossMap;

	sampler2D _Glow;
	//  sampler2D _GlowAlpha;
	float _GlowOffsetX;
	float _GlowOffsetY;
	float _GlowPow;


    float4 _OutlineColor;
	float _OutlineMask;
	float _Outline;
	float _Outlinescale;
	//  float4 _DisintegrateTex_ST;
	// sampler2D _DisintegrateTex;
	//float4 _EdgeColor;
	//float _DisintegrateAmount;
	//float _EdgeRange;

	struct vertexInput
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float2 texcoord : TEXCOORD0;
		float2 texcoord1 : TEXCOORD1;
		float4 tangent : TANGENT;
	};

	struct vertexOutput
	{
		float4 pos : SV_POSITION;
		float4 posWorld : TEXCOORD0;
		float3 normalDir : TEXCOORD1;
		float3 lightDir:TEXCOORD2;
		float3 viewDir : TEXCOORD3;
		float3 vertexLighting : TEXCOORD4;
		float2 uv2 : TEXCOORD5;
		float2 uv : TEXCOORD6;
		float4 R : TEXCOORD7;
	};

	vertexOutput vert(vertexInput input)
	{
		vertexOutput output;
		UNITY_INITIALIZE_OUTPUT(vertexOutput,output);

		//TRANSFER_VERTEX_TO_FRAGMENT(output);

		output.pos = UnityObjectToClipPos(input.vertex);
		output.posWorld = mul(unity_ObjectToWorld, input.vertex);    // w v
		output.normalDir = normalize(mul(float4(input.normal, 0.0), unity_WorldToObject).xyz);  // o n
		output.vertexLighting = float3(0,0,0);

#ifdef LIGHTMAP_OFF
		float3 shLight = ShadeSH9(float4(output.normalDir, 1.0));
		output.vertexLighting = shLight;
#endif    

		//    float3 posW = mul(unity_ObjectToWorld,input.vertex).xyz;   多余
		float3 I = output.posWorld.xyz - _WorldSpaceCameraPos.xyz;   //w  摄像机 - 顶点
		float3 N = mul((float3x3)unity_ObjectToWorld,input.normal);  //w n
		N = normalize(N);
		output.R.xyz = reflect(I,N);

		vertexInput v = input;

		TANGENT_SPACE_ROTATION;
		output.lightDir = mul(rotation, ObjSpaceLightDir(input.vertex));
		output.viewDir = mul(rotation, ObjSpaceViewDir(input.vertex));

		output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
		//output.uv2 = TRANSFORM_TEX(input.texcoord, _tex1);

		// for rim
		if (input.vertex.y >_OutlineMask)
		{
			output.R.w = 1;
		}
		else
		{
			output.R.w = 0;
		}

		return output;
	}

	float4 frag(vertexOutput input) : COLOR                      //在切线空间计算光源
	{
		float4 c = tex2D(_MainTex, input.uv) ;              // c  diffuse
		c.rgb *= _Color.rgb;
		float4 d = tex2D(_Spe, input.uv);                           // d  spec
		float4 e = texCUBE(_Cubemap, input.R.xyz) * _CubemapPow;        // e  cubmap         
		float3 norm = UnpackNormal(tex2D(_Bump, input.uv));         // norm  normal
		norm = float3(norm.x * _BumpPow, norm.y * _BumpPow, norm.z);
		//float4 tex1 = tex2D(_tex1, input.uv2);

		float moveTimeX = _Time * _GlowOffsetX;
		float moveTimeY = _Time * _GlowOffsetY;
		float2 texOffset = float2(input.uv.x + moveTimeX, input.uv.y + moveTimeY);

		//  float4 i = tex2D(_GlowAlpha, input.uv);                   // i glow.a

		// float4 h = tex2D(_GlossMap, input.uv);                    // h specu_glossmap

		float attenuation;
		attenuation = 1.0;
		//attenuation = LIGHT_ATTENUATION(input);

		float3 normalDirection = normalize(input.normalDir);    // o n
		float3 viewDirection = normalize(_WorldSpaceCameraPos - input.posWorld.xyz);  // c - v

		float3 diffuseReflection = attenuation * _LightColor0.rgb * saturate(dot(normalize(norm),  normalize(input.lightDir)));

		float3 refl = reflect(-input.lightDir, normalize(norm));
		float3 specularReflection = _LightColor0.rgb * pow(saturate(dot(normalize(refl), normalize(input.viewDir))), _SpeRange * c.a) * _SpePow * d*_speColor;
		// 背光面的高光（可以当补光用）                             
		float3 Brefl = reflect(input.lightDir, normalize(norm));
		float3 BspecularReflection = _LightColor0.rgb * pow(saturate(dot(normalize(Brefl), normalize(input.viewDir))), _BSpeRange) * _BSpeColor.rgb * _BSpePow * d;

		float4 light = float4(input.vertexLighting + diffuseReflection + specularReflection + BspecularReflection * 1, 0.0);
		float4 col;
#if _TEXORCOL_ON
		col = ((c * light) + (_Glowcolor * d.a * _GlowPow)) + (c * e);
#else
		float4 f = tex2D(_Glow, texOffset.xy);                    // f glow
		col = ((c * light) + (f * d.a * _GlowPow)) + (c * e);
#endif

		
		half normalDotEye = 1 - max(0, dot(normalDirection, viewDirection));
		normalDotEye = pow(normalDotEye, _Outline);
		half4 topRim = normalDotEye*c*input.R.w *_Outlinescale  *_OutlineColor;

		
		//return topRim;
		//return c;
		return col+ topRim;
		//float clipval = (tex2D (_DisintegrateTex, input.uv2).rgb *  normalize(_DisintegrateAmount)) - _DisintegrateAmount;

		/*
		float4 mask = tex1.b * normalize(_DisintegrateAmount);
		float clipval = mask.r - _DisintegrateAmount;

		clip(clipval);


		//return f*i*_GlowPow;
		//return float4(BspecularReflection,1);
		return tex1.g;

		if (_DisintegrateAmount == 0)
		{
			return col;
		}
		else
		{
			if (clipval < _EdgeRange)
			{
				col = _EdgeColor;
				return col;
			}
			else
			{
				return col;
			}
		}*/



	}
		ENDCG
	}

	}
		//Fallback "Legacy Shaders/VertexLit"
}