Shader "ZShader/Toon/Actor/V3/Hair"
{
	Properties
	{
		_MainTex("主要贴图 (RGB)", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_LightMaskTex("Mask贴图 (R：阴影Mask G：高光区域 B：高光遮罩 A：发梢染色Mask)",2D) = "gray" {}

		_MainColor("MainColor", Color) = (1, 1, 1, 1)
		_BodyAlPah("角色透明度",Range(0, 1)) = 1
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.1

		_DyeColor("染色", Color) = (1, 1, 1, 1)
		_DyeIntensity("染色强度", Range(0, 1)) = 0

		_MaskDyeColor("发梢染色", Color) = (1,1,1,1)
		_MaskDyeIntensity("发梢染色强度", Range(0,1)) = 0
		_MaskDyeColorIntensity("发梢染色范围", Range(0.001, 1)) = 1

		_FirstShadowMultColor("一层阴影色", Color) = (1, 1, 1, 1)
		_Mix_BaseTexture("Mix_BaseTexture", Range(0.001, 0.9999)) = 0.32
		_Mix_KageTexture("Mix_KageTexture", Range(0.001, 0.9999)) = 0.6

		_SecondShadowColor("二层阴影色", Color) = (1, 1, 1, 1)
		_Mix_BaseTexture2("Mix_BaseTexture2", Range(0.001, 0.9999)) = 0.32
		_Mix_KageTexture2("Mix_KageTexture2", Range(0.001, 0.9999)) = 0.6

		_ShadowMask("阴影过度图", 2D) = "white" {}
		_UseShadowMask("阴影过度色强度", Float) = 0

		_SpecularMultiplier("Specular Multiplier", float) = 255.0
		_SpecularColor("一层高光色", Color) = (1, 1, 1, 1)
		_SpecularMultiplier2("Secondary Specular Multiplier", float) = 255.0
		_SpecularColor2("二层高光色", Color) = (1, 1, 1, 1)
	
		_PrimaryShift("Specular Primary Shift", float) = -0.3
		_SecondaryShift("Specular Secondary Shift", float) = 0.34
		_SpecularVector("强度(X)亮度上限(Y)软硬(Z)(W)", Vector) = (1 ,1, 1, 1)

		// 边缘光
		[HDR]_RimColor("边缘光Color", Color) = (1, 1, 1, 1)
		//_RimSideWidth("边缘光宽度", Range(0, 0.8)) = 0.45
		_RimPower("边缘光软硬", Range(0, 2)) = 0.3
		_RimStrength("边缘光强度", Float) = 0.5

		// 描边
		_Outline_Width("Outline_Width", Float) = 1
		_MaxOutLine("_MaxOutLine", Range(0,5)) = 2
		_MinOutLine("_MinOutLine", Range(0,2)) = 0.5
		_Outline_Color("Outline_Color", Color) = (0.5,0.5,0.5,1)
		_Outline_Alpha("描边透明度",Float) = 1

		//==============================保存给编辑器用，不用作功能=================================
		_IsUseFixedLight("使用固定灯光", Float) = 1.0
		_FixedLightIntensity("固定灯光强度", Float) = 1
		_FixedLightDir("灯光方向",Vector) = (0.5, 0.5, 0.5)
		[HideInInspector]_LightEular("灯光欧拉角", Vector) = (45, 10, 0, 0)

		_UseFixedLightColor("使用固定灯光颜色", Float) = 1.0
		_FixedLightColor("固定灯光颜色", Color) = (1, 1, 1)

		// 渲染状态
		//[HideInInspector] _Mode("Blend Mode", Float) = 0.0
		//[HideInInspector] _SrcBlend("Blend Source", Float) = 1.0
		//[HideInInspector] _DstBlend("Blend Dest", Float) = 0.0
	}
	SubShader
	{
		LOD 200

		Tags
		{
			"ObjectType" = "Actor"			// 给程序里识别使用的类型
			"UIType" = "True"				// 给程序里识别使用的类型
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
		} //减一是为了防止特效穿插

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			//Blend[_SrcBlend][_DstBlend]
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap noshadowmask novertexlight
			#pragma fragmentoption ARB_precision_hint_fastest

			// -------------------------------------
			// Unity defined keywords
			//#pragma multi_compile _ VERTEXLIGHT_ON

			// -------------------------------------
			// 自定义 keywords
			#pragma shader_feature _USE_NORMAL_MAP
			#pragma shader_feature _USE_MASK_DYE
			#pragma shader_feature _USE_SHADOWMAP

			// -------------------------------------
			// 全局 keywords
			#pragma multi_compile __ USE_ACTOR_SHADOW_TEX

			// -------------------------------------
			// 自定义宏
			#define _HAIR
			#define _USE_RIM
			#define _USE_ALPHA_CUTOFF

			#include "ActorHairPass.cginc"
			ENDCG
		}

		Pass
		{
			Name "OUTLNIE"
			Blend SrcAlpha OneMinusSrcAlpha
			//ZWrite off
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
	SubShader
	{
		LOD 150

		Tags
		{
			"ObjectType" = "Actor"			// 给程序里识别使用的类型
			"UIType" = "True"				// 给程序里识别使用的类型
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
		} //减一是为了防止特效穿插

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			//Blend[_SrcBlend][_DstBlend]
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap noshadowmask novertexlight
			#pragma fragmentoption ARB_precision_hint_fastest

			// -------------------------------------
			// Unity defined keywords
			//#pragma multi_compile _ VERTEXLIGHT_ON

			// -------------------------------------
			// 自定义 keywords
			#pragma shader_feature _USE_NORMAL_MAP
			#pragma shader_feature _USE_MASK_DYE
			#pragma shader_feature _USE_SHADOWMAP

			// -------------------------------------
			// 全局 keywords
			//#pragma multi_compile __ USE_ACTOR_SHADOW_TEX

			// -------------------------------------
			// 自定义宏
			#define _HAIR
			#define _USE_RIM
			#define _USE_ALPHA_CUTOFF

			#include "ActorHairPass.cginc"
			ENDCG
		}

		Pass
		{
			Name "OUTLNIE"
			Blend SrcAlpha OneMinusSrcAlpha
			//ZWrite off
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
	SubShader
	{
		LOD 100

		Tags
		{
			"ObjectType" = "Actor"			// 给程序里识别使用的类型
			"UIType" = "True"				// 给程序里识别使用的类型
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
		} //减一是为了防止特效穿插

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			//Blend[_SrcBlend][_DstBlend]
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0

			#pragma fragmentoption ARB_precision_hint_fastest

			// -------------------------------------
			// Unity defined keywords
			//#pragma multi_compile _ VERTEXLIGHT_ON

			// -------------------------------------
			// 自定义 keywords
			#pragma shader_feature _USE_NORMAL_MAP
			#pragma shader_feature _USE_MASK_DYE
			#pragma shader_feature _USE_SHADOWMAP

			// -------------------------------------
			// 全局 keywords
			//#pragma multi_compile __ USE_ACTOR_SHADOW_TEX

			// -------------------------------------
			// 自定义宏
			#define _HAIR
			#define _USE_RIM
			#define _USE_ALPHA_CUTOFF

			#include "ActorHairPass.cginc"
			ENDCG
		}
	}
	CustomEditor "ToonActorShaderGUI_V3"
}
