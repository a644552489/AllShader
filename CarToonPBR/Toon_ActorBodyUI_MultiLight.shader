﻿Shader "Hidden/ZShader/Toon/Toon_ActorBodyUI_MultiLight"
{
	Properties
	{
		_MainColor("MainColor",Color) = (1,1,1,1)
		_BodyAlPah("角色透明度",Range(0,1)) = 1
		_TexAlaphDelta("贴图透明度调整值",Range(0, 1)) = 0
		_MainTex ("主要贴图 (RGB)", 2D) = "white" {}
		_FalloffSampler ("明暗部控制", 2D) = "white" {}
		_ShadowTex("阴影贴图 (RGB)",2D) = "white" {}
		_ShadowColor("阴影颜色",Color) = (1,1,1,1)

		_LightArea("阴影影响区域",Range(0,1)) = 0.6
		_ShadowWidthSmooth("阴影平滑距",Range(0,0.1)) = 0.05

		//[Toggle(USE_LIGHTMASK_ON)] _USE_LIGHTMASK_ON("使用Mask贴图",Float) = 0
		_LightMask("Mask贴图 (RGBA)",2D) = "red" {}

		_LightMask_R("Mask贴图 (R)",2D) = "white" {}
		_LightMask_G("Mask贴图 (G)",2D) = "gray" {}
		_LightMask_B("Mask贴图 (B)",2D) = "white" {}
		_LightMask_A("Mask贴图 (A)",2D) = "black" {}

		_SpecularColor("高光颜色",Color) = (1,1,1,1)
		_Gloss("高光Gloss",Range(0.001,5)) = 1
		_ShinnessMulti("高光强度",Range(0,5)) = 1

		_HairMatCapTex("头发扰动",2D) = "black"{}
		_TweakUv("扭动UV",Range(-0.5,0.5)) = 0
		_NormalMapForMatCap(" _NormalMapForMatCap",2D) = "bump" {}
		_MatcapColor("MatCap颜色",Color) = (0.5,0.5,0.5)

		//[Toggle(NORMAL_MAP_ON)] _UseNormalMap("使用法线贴图?",Float) = 0

		_BumpMap("Normal Map",2D) = "bump"{}
		_BumpScale("Normal Scale",Float) = 1
		
		//[Toggle(USE_RIM_LIGHT_ON)] USE_RIM_LIGHT_ON("使用边缘光?",Float) = 0
		_RimColor("外发光_颜色",Color) = (0,0,0.5,1)
		_RimPower("外发光_边缘",Range(0.001,3)) = 0.5 
		_RimStrength("外发光_强度",Float) = 0.5

		_RimLightMap("亮边_Fallout", 2D) = "white" {}
		_RimLightColor("亮边_颜色", Color) = (1,1,1,1)
		_RimStrengthV2("亮边_强度", Float) = 1
		_RimEdgeDelta("亮边_边界偏移", Range(0, 1)) = 0

		//由C#传入控制的闪白
		_SecondRimColor("被击 外发光",Color) = (1,1,1,1)
		_SecondRimStrenth("被攻 外发光",Range(0,1.0)) = 0

		//OutLine部分使用
		_Outline_Width ("Outline_Width", Float ) = 1
      	_MaxOutLine ("_MaxOutLine", Range(0,5) ) = 2
        _MinOutLine ("_MinOutLine", Range(0,2) ) = 0.5
        _Outline_Color ("Outline_Color", Color) = (0.5,0.5,0.5,1)

		// [Toggle(_Emissve_Float_ON)] _Illum_Float ("Illum Float 流动", Float) = 0
		// [Toggle(_Emissve_SIN_ON)] _Illum_SIN ("Illum SIN 变动", Float) = 0
		//流动
		_EmissiveTex ("Emissive (RGB)", 2D) = "white" {}
		_EmissiveColor("EmissiveColor",Color) = (1,0,0,1)
		_EmissiveOffsetX ("Emissive (RGB) Offset x", Float) = 0
		_EmissiveOffsetY ("Emissive (RGB) Offset Y", Float) = 0
		_EmissiveStrength ("Emissive Strength", Float) = 1

		//闪动
		_SinEmissiveColor("_SinEmissiveColor",Color) = (1,0,0,1)
		_SinEmissiveStrength("_SinEmissiveStrength",Float) = 6
		_SinEmissiveFrequent ("Emissive Frequent", Float) = 0
		_Alpha("透明度",Float)=1
		_Outline_Alpha("描边透明度",Float) = 1
		//==============================保存给编辑器用，不用作功能=================================
		_FixedLightColor("固定灯光颜色", Color) = (1,1,1)
		_FixedLightIntensity("固定灯光强度", Float) = 1
		_LightDir("灯光方向",Vector) = (0.5,0.5,0.5)
		_LightEular("灯光欧拉角",Vector) = (45,10,0,0) //保存欧拉角，在编辑器中转换为灯光方向
		// [Toggle]_IsUI("是否UI用",Float) = 0 
		// [Toggle]_IsUseDissolve("是否使用溶解特效",Float) = 0 //是否使用溶解特效消失，自定义UI使用
		//======================================================================================
	}
	SubShader
	{
		LOD 200
		
		Tags 
		{
			"ObjectType" = "Actor"			// 给程序里识别使用的类型
			"UIType" = "True"			// 给程序里识别使用的类型
			"RenderType"="Transparent" "Queue"="Transparent-1"
		} //减一是为了防止特效穿插
		Pass
		{
			Tags{ "LightMode" = "ForwardBase"}
			Blend SrcAlpha OneMinusSrcAlpha
			Stencil{
				Ref 2
				Comp Always
				Pass Replace
			}
			//ZTest Off
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			#pragma fragmentoption ARB_precision_hint_fastest

			#pragma shader_feature USE_SHADOWCOLOR_MUL_TEXCOLOR
			#pragma shader_feature NORMAL_MAP_ON
			#pragma shader_feature USE_LIGHTMASK_OFF USE_COMBINE_CHANNEL_ON USE_SPLIT_CHANNEL_ON 
			//只使用Mat高光，同时使用Mat高光和正常
			#pragma shader_feature USE_SPECULAR_ON USE_HAIR_SPECULAR_ON USE_ALL_SPECULAR_ON
			#pragma shader_feature USE_RIM_LIGHT_ON
			#pragma shader_feature _ _USE_RIM_LIGHT_ON_V2
			
			//流动
			#pragma shader_feature _Emissve_Float_ON
			//闪动 / 不动
			#pragma shader_feature _Emissve_SIN_ON
			#pragma shader_feature _USE_FIX_LIGHTDIR
			#define USE_ALPHABLEND
			#pragma multi_compile _NoneDissovle _UseDissovle _UseDissovleTwist
			#include "Toon_Actor_new.cginc"
			ENDCG
		}
		/*Pass
		{
			Tags{ "LightMode" = "ForwardAdd"}
			Blend SrcAlpha One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vertAdd
			#pragma fragment fragAdd
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			#pragma fragmentoption ARB_precision_hint_fastest

			#pragma shader_feature NORMAL_MAP_ON
			#pragma shader_feature _USE_FIX_LIGHTDIR
			#pragma shader_feature _ _USE_RIM_LIGHT_ON_V2

			#define USE_ALPHABLEND
			#pragma multi_compile _NoneDissovle _UseDissovle _UseDissovleTwist

            #pragma multi_compile_fwdadd_fullshadows
			#include "Toon_Actor_new.cginc"
			ENDCG
		}*/
		Pass{
			Name "OUTLNIE"
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Front
			//Offset 2, 1
			// Stencil{
			// 	Ref 1
			// 	Comp Always
			// 	Pass Replace
			// }
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#pragma fragmentoption ARB_precision_hint_fastest

			#include "ToonOutLineCG.cginc"
			ENDCG
		}
		
	}
	//Fallback "Legacy Shaders/Diffuse"
	CustomEditor "ToonActorNewShaderGUI"
}