Shader "LXShader/Other/MultiPassFurModified"
{
    Properties
    {
 
      


        [Header(Main)]
        [MainColor]_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}

		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5

		_BumpScale("Noramal Scale", Range(0,1)) = 1.0
		_NormalMap("Normal Map", 2D) = "bump" {}

		[Enum(UV0,0,UV1,1)] _UVSec("UV Set for secondary textures", Float) = 0

		[Space(20)]
		_FabricScatterColor("Fabric Scatter Color", Color) = (1,1,1,1)
		_FabricScatterScale("Fabric Scatter Scale", Range(0, 10)) = 0
		
		[Space(20)]
		_LayerTex("Layer", 2D) = "white" {}
		_FurLength("Fur Length", Range(.0002, 50)) = .25
		_Cutoff("Alpha Cutoff", Range(0,1)) = 0.5 // how "thick"
		_CutoffEnd("Alpha Cutoff end", Range(0,1)) = 0.5 // how thick they are at the end
		//_EdgeFade("Edge Fade", Range(0,1)) = 0.4
		_Gravity("Gravity Direction", Vector) = (0,-1,0,0)
		_GravityStrength("Gravity Strength", Range(0,1)) = 0.25
  
        _UVOffset("UVOffset",Range(0.1,10) )=1
		[Header(Shadow)]
		_ShadowColor("Shadow Color", Color) = (0,0,0,0)
		_ShadowLerp("Shadow AO",Range(0,1)) = 1
 
		// Blending state
	    [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 10
        [Toggle] _ALPHACLIP("AlphaClip" , Float) = 0
    } 
    SubShader
    {
      
	    Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="AlphaTest +50" }
      
        HLSLINCLUDE
       	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
		#define UNITY_SETUP_BRDF_INPUT MetallicSetup
		#define _NORMALMAP_URP 1
		#define _FABRIC_URP 1


        TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
        TEXTURE2D(_LayerTex); SAMPLER(sampler_LayerTex);
 

        CBUFFER_START(UnityPerMaterial)
        half _UVOffset;
        half3 _FabricScatterColor;
		half  _FabricScatterScale;
        float4 _MainTex_ST;
        float4 _LayerTex_ST;
        half _Glossiness;
        half _FurLength;
        half _GravityStrength;
        half4 _Color;
        half3 _Gravity;
        half _CutoffEnd;
     //   half _EdgeFade;
        half        _OcclusionStrength;
        half        _Cutoff;
        half        _BumpScale;
		float _Metallic;

        // //PBR
        float3 _Albedo;
        
        float3 _Specular;
        float _Smoothness;
        float _Occlusion;
        float3 _Emission;
        float _Alpha;
        float4 _ShadowColor;
        half _ShadowLerp;

        CBUFFER_END
        
        ENDHLSL

        Pass
        {
           Name "FORWARD"

 
		    Tags { "LightMode" ="UniversalForward" }
            Blend[_SrcBlend][_DstBlend]

           HLSLPROGRAM
     
            // make fog work
		
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			#pragma multi_compile_instancing


            #pragma shader_feature _ALPHACLIP_ON


            #pragma vertex vert_LayerBase
            #pragma fragment frag_LayerBase

			#include "FurCoreData.hlsl"

           ENDHLSL
        }
		Pass {
                Name "ShadowCaster"
                Tags { "LightMode"="ShadowCaster" }
 
                ZWrite On
                ZTest LEqual
 
                HLSLPROGRAM
                // Required to compile gles 2.0 with standard srp library
                #pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x gles
                //#pragma target 4.5
 
                // Material Keywords
                #pragma shader_feature _ALPHATEST_ON
                #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
 
                // GPU Instancing
                #pragma multi_compile_instancing
                #pragma multi_compile _ DOTS_INSTANCING_ON
             
                #pragma vertex ShadowPassVertex
                #pragma fragment ShadowPassFragment
      
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

                float3 _LightDirection;

                struct Attributes
                {
                    float4 positionOS   : POSITION;
                    float3 normalOS     : NORMAL;
                    float2 texcoord     : TEXCOORD0;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct Varyings
                {
                    float2 uv           : TEXCOORD0;
                    float4 positionCS   : SV_POSITION;
                };

                float4 GetShadowPositionHClip(Attributes input)
                {
                    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                    return positionCS;
                }

                Varyings ShadowPassVertex(Attributes input)
                {
                    Varyings output;
                    UNITY_SETUP_INSTANCE_ID(input);

                    output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);
                    output.positionCS = GetShadowPositionHClip(input);
                    return output;
                }

                half4 ShadowPassFragment(Varyings input) : SV_TARGET
                {
                   // Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
                   float Alpha =  SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex)).a ;

                    clip(Alpha - 0.1);
                    return 0;
                }
              ENDHLSL
            }
		
    }
    FallBack"Diffuse"
}
