Shader "LXShader/Other/MultiPassFurModified"
{
    Properties
    {
       [Header(Macro)]
        [Toggle(_TANGENT_TO_WORLD)] _TangentToWorld("Tangent To World", Float) = 0
        [Toggle(_GI_ON)] _GI_ON("GIOn", Float) = 0
        [Toggle(_RECEIVE_SHADOWS)] _RECEIVE_SHADOWS("Receive Shadow", Float) = 0
		[KeywordEnum(On,Off)] _NORMALMAP_URP("Mormal Map", Float) = 0
        [Header(Main)]
        [MainColor]_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}

		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5

		_BumpScale("Noramal Scale", Range(0,1)) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}

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
        _FlowMap("Flow Map", 2D) = "white"{}
        _Mask("_Mask" , 2D) = "white"{}
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
        Tags { "RenderType"="Opaque"  "PerformanceChecks" = "False"  "Queue" = "AlphaTest +50"}

        LOD 100
        CGINCLUDE
        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"
		#define UNITY_SETUP_BRDF_INPUT MetallicSetup
		#define _NORMALMAP_URP 1
		#define _FABRIC_URP 1
		#define _FUR_URP 1

        sampler2D _LayerTex;
        sampler2D   _BumpMap;
        sampler2D _FlowMap;
        sampler2D _MainTex;
        sampler2D   _OcclusionMap;
        sampler2D _Mask;

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
        

        //
        ENDCG
        Pass
        {
           Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase"}

               Blend[_SrcBlend][_DstBlend]

            CGPROGRAM
     
            // make fog work
			#pragma multi_compile_fwdbase
			#pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma shader_feature _ _TANGENT_TO_WORLD
            //#pragma shader_feature _ _PARALLAXMAP
            #pragma shader_feature _ _GI_ON
			#pragma multi_compile _ LIGHTMAP_ON
            #pragma shader_feature _ALPHACLIP_ON
			#pragma shader_feature _NORMALMAP
            #pragma shader_feature _ _RECEIVE_SHADOWS

			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF

            // #define SHADER_TARGET 100
            
            #pragma vertex vert_LayerBase
            #pragma fragment frag_LayerBase

			#include "FurCoreData.hlsl"

            ENDCG
        }
        Pass
        {
           Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase"}
              Blend[_SrcBlend][_DstBlend]

            CGPROGRAM
            
            // make fog work
			#pragma multi_compile_fwdbase
			#pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma shader_feature _ _TANGENT_TO_WORLD
            //#pragma shader_feature _ _PARALLAXMAP
            #pragma shader_feature _ _GI_ON
			#pragma multi_compile _ LIGHTMAP_ON
		          #pragma shader_feature _ALPHACLIP_ON
			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _RECEIVE_SHADOWS
	
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature _ _GLOSSYREFLECTIONS_OFF
  
            #pragma vertex vert_LayerBase
            #pragma fragment frag_LayerBase

			#include "FurCoreData.hlsl"

            ENDCG
        }
			Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual Cull Off

			CGPROGRAM
			//#pragma target 5.0

			// -------------------------------------
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"
            struct v2f {

                V2F_SHADOW_CASTER;
                float2 uv :TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            v2f vert(appdata_base v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = TRANSFORM_TEX(v.texcoord , _MainTex);
                return o;                
            }
            float4 frag(v2f i):SV_Target
            {
                half4 texcol = tex2D(_MainTex,  i.uv);
                clip(texcol.a - 0.1);
                SHADOW_CASTER_FRAGMENT(i)    
            }
			


			ENDCG
		}
		
    }
    FallBack"Diffuse"
}
