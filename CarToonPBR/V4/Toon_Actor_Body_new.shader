Shader "ZShader/Toon/Actor/V4/Body"
{
	Properties
	{
		_MainTex("主要贴图 (RGB)", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
	
		_SRSMap("Spec_Ref_Smoothness Map" , 2D) = "white"{}
		_SpecMap("SpecMap" , 2D) = "white"{}
		_RefMap("RefMap" , 2D) = "white"{}
		_SmoothnessMap("Smoothness Map" ,2D ) = "white"{}


		_Ref("Ref Color" , Color) = (1,1,1,1)
		_Smoothness("_Smoothness" , Range(0,1)) = 0


		_LightMaskTex("边缘光加亮(R) ToonKage(G) 高光Mask(B) 平滑度(A)", 2D) = "white" {}
		_EmissiveMaskTex("G：流动 A：闪动", 2D) = "black" {}

		_MainColor("MainColor", Color) = (1, 1, 1, 1)
		_SkinDyeColor("皮肤染色color", Color) = (1, 1, 1, 1)
		_BodyAlPah("角色透明度",Range(0, 1)) = 1
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.1

		_SkinShadowMultColor("皮肤阴影色", Color) = (1, 1, 1, 1)

		_FirstShadowMultColor("第一层阴影色", Color) = (1, 1, 1, 1)
		_Mix_BaseTexture("Mix_BaseTexture", Range(0.001, 0.9999)) = 0.32
		_Mix_KageTexture("Mix_KageTexture", Range(0.001, 0.9999)) = 0.6
		_SecondShadowColor("第二层阴影色", Color) = (0.5, 0.5, 0.5, 1)
		_Mix_BaseTexture2("Mix_BaseTexture1", Range(0.001, 0.9999)) = 0.48
		_Mix_KageTexture2("Mix_KageTexture1", Range(0.001, 0.9999)) = 0.5

		_ShadowMask("阴影过度图", 2D) = "white" {}
		_UseShadowMask("阴影过度色强度", Float) = 0

		[HDR]_MetalSpecColor("_MetalSpecColor", Color) = (1, 1, 1, 1)

		// 边缘光
		[HDR]_RimColor("边缘光Color", Color) = (1, 1, 1, 1)
		//_RimSideWidth("边缘光宽度", Range(0, 0.8)) = 0.45
		_RimPower("边缘光软硬", Range(0, 2)) = 0.3
		_RimStrength("边缘光强度", Float) = 0.5

		_EmissionIntensity("自发光强度", Float) = 0

		// 流动
		_EmissiveTex("Emissive (RGB)", 2D) = "white" {}
		_EmissiveColor("EmissiveColor",Color) = (1,0,0,1)
		_EmissiveOffsetX("Emissive (RGB) Offset x", Float) = 0
		_EmissiveOffsetY("Emissive (RGB) Offset Y", Float) = 0
		_EmissiveStrength("Emissive Strength", Float) = 1

		// 闪动
		_SinEmissiveColor("_SinEmissiveColor",Vector) = (1,0,0,1)
		_SinEmissiveStrength("_SinEmissiveStrength",Float) = 6
		_SinEmissiveFrequent("Emissive Frequent", Float) = 0

		_BloomVector("闲置(X) 自发光纯度(Y) 高光软硬(Z) 反射强度(W)", Vector) = (5 ,1, 1, 1)

		_EnvironmentMap("Environment Map", Cube) = "" {}

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

		[HDR]_Light1Color("副光颜色",Color)=(1,1,1,1)
		

		// 渲染状态
		//[HideInInspector] _Mode("Blend Mode", Float) = 0.0
		//[HideInInspector] _SrcBlend("Blend Source", Float) = 1.0
		//[HideInInspector] _DstBlend("Blend Dest", Float) = 0.0
		//[Enum(Off, 0, Front, 1, Back, 2)] _Cull("_Cull Mode",Float) = 2

		[Toggle]_UseSRSMap("打开SRSMap模式",Float) = 0
		[Toggle]_UseBlendSRSMap("混合SRS贴图",Float) = 0
	
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
			#pragma shader_feature _USE_SHADOWMAP

			//流动
			#pragma shader_feature _Emissve_Float_ON

			//闪动 / 不动
			#pragma shader_feature _Emissve_SIN_ON

			//打开SRSMap
			#pragma shader_feature _USESRSMAP_ON
			#pragma shader_feature _USEBLENDSRSMAP_ON
			// -------------------------------------
			// 全局 keywords
			#pragma multi_compile __ USE_ACTOR_SHADOW_TEX

			// -------------------------------------
			// 自定义宏
			#define _USE_RIM
			#define _USE_ALPHA_CUTOFF

			#include "ActorPass.cginc"
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
			Tags { "LightMode" = "ForwardBase" }
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
			#pragma shader_feature _USE_SHADOWMAP

			//流动
			#pragma shader_feature _Emissve_Float_ON

			//闪动 / 不动
			#pragma shader_feature _Emissve_SIN_ON

			//设置SRS贴图
			#pragma shader_feature _USESRSMAP_ON
			#pragma shader_feature _USEBLENDSRSMAP_ON
			// -------------------------------------
			// 全局 keywords
			//#pragma multi_compile __ USE_ACTOR_SHADOW_TEX

			// -------------------------------------
			// 自定义宏
			#define _USE_RIM
			#define _USE_ALPHA_CUTOFF

			#include "ActorPass.cginc"
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
			#pragma shader_feature _USE_SHADOWMAP

			//流动
			//#pragma shader_feature _Emissve_Float_ON

			//闪动 / 不动
			//#pragma shader_feature _Emissve_SIN_ON

			// -------------------------------------
			// 全局 keywords
			//#pragma multi_compile __ USE_ACTOR_SHADOW_TEX

			// -------------------------------------
			// 自定义宏
			#define _USE_RIM
			#define _USE_ALPHA_CUTOFF

			#include "ActorPass.cginc"
			ENDCG
		}
	}
	CustomEditor "ToonActorShaderGUI_V4"
}
