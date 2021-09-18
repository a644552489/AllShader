/////////////////////////////////
/// Gamma空间下模拟线性渲染的shader
/// 整合官方的Standard依赖的代码到这个shader里面
/// 基本和线性下完全一致，肉眼不盯着看发现不了区别
/// 注释_FAKELINEAR 来切换本shader是走官方流程还是走
/// 模拟线性流程
/// 调的时候可以把本shader放到gamma和linear工程下
/// 比对着调差异
/// gamma下开启#define _FAKELINEAR 1  
/// linear下注释掉 #define _FAKELINEAR 1  
/// lightmap功能没测
/////////////////////////////////

Shader "PBR/Gamma/ActorBody_test"
{
    Properties
    {
        _MainColor("MainColor", Color) = (1,1,1,1)
		_BodyAlPah("角色透明度",Range(0,1)) = 1
        _MainTex("Albedo", 2D) = "white" {}

		//OutLine部分使用
		_Outline_Width ("Outline_Width", Float ) = 1
        _MaxOutLine ("_MaxOutLine", Range(0,5) ) = 2
        _MinOutLine ("_MinOutLine", Range(0,2) ) = 0.5
        _Outline_Color ("Outline_Color", Color) = (0.5,0.5,0.5,1)
		_Outline_Alpha("边缘透明度",Float)=1

		_FallOffMap("明暗部控制", 2D) = "white" {}
		_FallOffDelta("明部调整值", Range(0, 1)) = 0.5
		_FallOffScale("明暗部缩放",Float) = 1

		_RimColor("外发光_颜色",Color) = (0,0,0.5,1)
		_RimPower("外发光_边缘",Range(0.001,3)) = 0.5 
		_RimLightMap("rim light map", 2D) = "white" {}
		_RimLightColor("rim light color", Color) = (1,1,1,1)
		_RimStrength("亮边_强度", Float) = 1
		_RimEdgeDelta("rim edge delta", Range(0.0, 1.0)) = 0

		//由C#传入控制的闪白
		_SecondRimColor("被击 外发光",Color) = (1,1,1,1)
		_SecondRimStrenth("被攻 外发光",Range(0,1.0)) = 0

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
        _GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0

        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap("Metallic", 2D) = "white" {}

        //[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        //[ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0

        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}

        _Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
        _ParallaxMap ("Height Map", 2D) = "black" {}

        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion", 2D) = "white" {}

		_LightMask("Mask贴图 (RGBA)",2D) = "red" {}
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

		//========================================光照相关=========================================
		_GIIndirectDiffuseFactor("间接光强度系数", Float) = 1
		_GIIndirectDiffuseAdd("间接光补充", Color) = (0,0,0)
		_GIIndirectDiffuseAddFactor("间接光补充系数", Float) = 1
		//==============================保存给编辑器用，不用作功能=================================
		_FixedLightDir("灯光方向",Vector) = (0.5,0.5,0.5)
		_FixedLightColor("固定灯光颜色", Color) = (1,1,1)
		_FixedLightIntensity("固定灯光强度", Float) = 1
		_LightEular("灯光欧拉角",Vector) = (45,10,0,0) //保存欧拉角，在编辑器中转换为灯光方向

        // Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
    }

    CGINCLUDE
        #define UNITY_SETUP_BRDF_INPUT MetallicSetup
		//#if defined (SHADOWS_DEPTH) && !defined (SPOT)
		//#       define SHADOW_COORDS(idx1) unityShadowCoord2 _ShadowCoord : TEXCOORD##idx1;
		//#endif

        #include "UnityCG.cginc"
        #include "UnityShaderVariables.cginc"
        #include "UnityInstancing.cginc"
        #include "UnityStandardConfig.cginc"
        #include "UnityStandardUtils.cginc"
        #include "UnityGBuffer.cginc"
        #include "UnityStandardBRDF.cginc"

		#include "UnityGlobalIllumination.cginc"

        #include "AutoLight.cginc"

        #define _FAKELINEAR 1  

        #if defined(_FAKELINEAR)
            #define unity_ColorSpaceGrey1 fixed4(0.214041144, 0.214041144, 0.214041144, 0.5)
            #define unity_ColorSpaceDouble1 fixed4(4.59479380, 4.59479380, 4.59479380, 2.0)
            #define unity_ColorSpaceDielectricSpec1 half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)
            #define unity_ColorSpaceLuminance1 half4(0.0396819152, 0.458021790, 0.00609653955, 1.0) // Legacy: alpha is set to 1.0 to specify linear mode                       
        #else
            #ifdef UNITY_COLORSPACE_GAMMA
            #define unity_ColorSpaceGrey1 fixed4(0.5, 0.5, 0.5, 0.5)
            #define unity_ColorSpaceDouble1 fixed4(2.0, 2.0, 2.0, 2.0)
            #define unity_ColorSpaceDielectricSpec1 half4(0.220916301, 0.220916301, 0.220916301, 1.0 - 0.220916301)
            #define unity_ColorSpaceLuminance1 half4(0.22, 0.707, 0.071, 0.0) // Legacy: alpha is set to 0.0 to specify gamma mode
            #else // Linear values
            #define unity_ColorSpaceGrey1 fixed4(0.214041144, 0.214041144, 0.214041144, 0.5)
            #define unity_ColorSpaceDouble1 fixed4(4.59479380, 4.59479380, 4.59479380, 2.0)
            #define unity_ColorSpaceDielectricSpec1 half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)
            #define unity_ColorSpaceLuminance1 half4(0.0396819152, 0.458021790, 0.00609653955, 1.0) // Legacy: alpha is set to 1.0 to specify linear mode
            #endif
        #endif
	ENDCG

	SubShader
    {
        Tags {
			"ObjectType" = "Actor"			// 给程序里识别使用的类型 
			"RenderType"="Opaque" "PerformanceChecks"="False" "Queue"="AlphaTest"}
        LOD 200

        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

			Stencil
			{
				Ref 2
				Comp Always
				Pass Replace
			}

            CGPROGRAM
            #pragma target 3.0

            //#pragma multi_compile _ _NORMALMAP
            //#pragma multi_compile _ _ALPHAPREMULTIPLY_ON
            //#pragma shader_feature _EMISSION
            //#pragma multi_compile _ _METALLICGLOSSMAP
            //#pragma shader_feature ___ _DETAIL_MULX2
            //#pragma multi_compile _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            //#pragma multi_compile _ _SPECULARHIGHLIGHTS_OFF
            //#pragma multi_compile _ _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature _ _PARALLAXMAP
			#pragma shader_feature _ _STANDARDFAKE_IGNORE_AMBIENT
			#pragma shader_feature _ _USE_FIX_LIGHT
			#pragma shader_feature _ _Emissve_Float_ON
			#pragma shader_feature _ _Emissve_SIN_ON
			#pragma multi_compile _ USE_RIM_LIGHT_ON

            #pragma multi_compile_fwdbase
            //#pragma multi_compile_fog
            //#pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertBase
            #pragma fragment fragBase
			#include "PBR_Gamma_Actor_test.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        /*Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend [_SrcBlend] One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 3.0

            //#pragma multi_compile _ _NORMALMAP
            //#pragma multi_compile _ _ALPHAPREMULTIPLY_ON
            //#pragma multi_compile _ _METALLICGLOSSMAP
            //#pragma multi_compile _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            //#pragma multi_compile _ _SPECULARHIGHLIGHTS_OFF
            //#pragma shader_feature ___ _DETAIL_MULX2
            #pragma multi_compile _ _PARALLAXMAP

            #pragma multi_compile_fwdadd_fullshadows
            //#pragma multi_compile_fog
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertAdd
            #pragma fragment fragAdd
			#include "PBR_Gamma_Actor.cginc"

            ENDCG
        }*/

         // ------------------------------------------------------------------
         //  Shadow rendering pass
         //Pass {
         //    Name "ShadowCaster"
         //    Tags { "LightMode" = "ShadowCaster" }

         //    ZWrite On ZTest LEqual

         //    CGPROGRAM
         //    #pragma target 2.0

         //    #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
         //    #pragma shader_feature _METALLICGLOSSMAP
         //    #pragma skip_variants SHADOWS_SOFT
         //    #pragma multi_compile_shadowcaster

         //    #pragma vertex vertShadowCaster
         //    #pragma fragment fragShadowCaster

         //    //#include "UnityStandardShadow.cginc"

         //    ENDCG
         //}
		Pass{
			Name "OUTLNIE"
			Cull Front
			//Tags { "RenderType"="Opaque" "Queue"="AlphaTest"}
			Blend One Zero
			//Blend SrcAlpha OneMinusSrcAlpha
			//Blend One One
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

	SubShader
    {
        Tags {
			"ObjectType" = "Actor"			// 给程序里识别使用的类型 
			"RenderType"="Opaque" "PerformanceChecks"="False" "Queue"="AlphaTest"}
        LOD 100

        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma target 3.0

            //#pragma multi_compile _ _METALLICGLOSSMAP
            //#pragma multi_compile _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            //#pragma multi_compile _ _SPECULARHIGHLIGHTS_OFF
            //#pragma multi_compile _ _GLOSSYREFLECTIONS_OFF
			#pragma shader_feature _ _STANDARDFAKE_IGNORE_AMBIENT
			#pragma shader_feature _ _USE_FIX_LIGHT
			#pragma shader_feature _ _Emissve_Float_ON
			#pragma shader_feature _ _Emissve_SIN_ON

            #pragma multi_compile_fwdbase
            //#pragma multi_compile_fog
            //#pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE
			#ifndef UNITY_PBS_USE_BRDF3
			#define UNITY_PBS_USE_BRDF3
			#endif
            #pragma vertex vertBase
            #pragma fragment fragBase
			#include "PBR_Gamma_Actor_test.cginc"

            ENDCG
        }
    }
    CustomEditor "PBRGammaActorShaderGUI_test"
}

