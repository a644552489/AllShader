Shader "TA/Hair"
{
    Properties
    {

               
       
      
     

         _TintColor("主颜色_TintColor" , Color) = (1,1,1,1)
        _MainTex ("_MainTex", 2D) = "white" {}
         _ColorIntensity("颜色强度_ColorIntensity" , Range(0.5,3)) =1
        _NormalTex("_NormalTex (RG:法线,B:切线噪波,A:AO)",  2D )="bump"{}
          _NormalStrength("法线强度_NormalStrength" , Range(0.01,3)) =1
    
        _ShiftTangentScale("法线Z缩放_ShiftTangentScale" , float) =1
        _ShiftTangentOffset("法线Z偏移_ShiftTangentOffset" , float) =1
        [Space(20)]
        _MLut("_MLut",  2D )="white"{}
        _NLutAniso("_NLutAniso",  2D )="white"{}

              _RColor("反射颜色_RColor" , Color) = (1,1,1,1)
        _RoughnessOffset_R("反射偏移_RoughnessOffset_R (0.2)" , float) =1
                _TTColor("透射颜色_TTColor" , Color) = (1,1,1,1)
        _RoughnessOffset_TT("透射偏移_RoughnessOffset_TT (0.5)" , float) =1
                _TRTColor("折射颜色_TRTColor" , Color) = (1,1,1,1)
        _RoughnessOffset_TRT("折射偏移_RoughnessOffset_TRT (0.87)" , float) =1
       
     _HighlightEnhance("_HighlightEnhance" ,Range(0.2,100)) =1



        [Header(Reflection Sphere)]
 
        _SpecCubePower("反射强度_SpecCubePower" , Range(0,1)) =1
        _Roughness("反射粗糙_Roughness" , Range(0,1)) =1

        [Space(20)]




  
        


    
        [Header(Fresnel Light)]
        [Space(20)]
        _RimLight("边缘光范围_RimLight" ,float) =1

        _RimLightIntensity("边缘光强度_RimLightIntensity" ,float) =1
        _RimLightColor("边缘光颜色_RimLightColor" , Color) = (1,1,1,1)

        [Header(Shadow And Cut)]
                
        [Space(20)]
            _Shadow("阴影_Shadow" , Range(0,1))=0.5
        _Cutoff("Cutoff",Range(0,1)) = 0.5


        
        [Space(50)]
        [Header(Program Call)]
  
        //方向性溶解
        _ChangeAmount("剪切幅度",Range(0,1)) = 0
        _EdgeWidth("边缘的宽度",Range(0,20)) = 0.2
        _EdgeColorIntensity("边缘颜色的的强度",Range(0,20)) = 1
        _Spread("溶解边缘的扩散值",Range(0,1)) = 0.3
        _Softness("柔和程度",Range(0,0.5)) = 0.5
        _Noise("噪声扭曲贴图",2D) = "white"{}
        _Ramp("边缘色贴图",2D) = "white"{}
        _Noisescale("溶解扭曲缩放程度", Range( 0 , 30)) = 6
        _Noisespeed("动画动画速度", Vector) = (0,0,0,0)
        _Wave1amplitude("波浪1幅度", Range( 0 , 5)) = 0
        _Wave1frequency("波浪1频率", Range( 0 , 50)) = 0
        _Wave1offset("波浪1位移", Float) = 0
        _Wave2amplitude("波浪2幅度", Range( 0 , 5)) = 0.5
        _Wave2Frequency("波浪2频率", Range( 0 , 50)) = 0
        _Wave2offset("波浪2位移", Float) = -0.5
        
        [Toggle]_Tintinsidecolor("叠加颜色开关", Range( 0 , 1)) = 0
        [HDR]_Fillcolor("叠加颜色", Color) = (1,1,1,1)
      

    

    }
    SubShader
    {

  
        Tags{"IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        
        Pass
        {

            Tags
            {
                "LightMode" = "ForwardBase"
            }
            
            //  Tags {"Queue"="Geometry" "LightMode" = "ForwardBase"}
            
            
            ZWrite On
            Cull Off

            
            CGPROGRAM

            #define CLIP 

            #pragma shader_feature  ACE_OFF ACE_U3D ACE_UE4

            #pragma vertex vert
            #pragma fragment frag

            #include "TRT.hlsl"


            #pragma multi_compile_fwdbase  


            ENDCG
        }


        Pass
        {
            
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            
            //  Tags { "Queue"="Transparent" "IGNOREPROJECTOR"="True" "RenderType"="Transparent" }
            //  Cull Off
            Blend SrcAlpha OneMinusSrcAlpha  
            ZWrite Off
            Cull Off
            CGPROGRAM

            
            #pragma target 3.0
            #pragma multi_compile_fwdbase  
            #pragma shader_feature  ACE_OFF ACE_U3D ACE_UE4
            #pragma vertex vert
            #pragma fragment frag

			#define USE_TEX_ALPHA 1
            
            #include "TRT.hlsl"

            ENDCG
        }

        Pass 
        {
            Tags 
            {
                "LightMode"="ShadowCaster"
            }
            Offset 1, 1
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct app_data 
            {
                float4 vertex : POSITION;
                float2 uv :TEXCOORD0;
            };
            struct v2f_S 
            {
                float2 uv :TEXCOORD0;
                V2F_SHADOW_CASTER;
            };
            v2f_S vert (app_data v) 
            {
                v2f_S o;
                o.uv = v.uv;
                TRANSFER_SHADOW_CASTER(o)
                return o;
            }
            sampler2D _MainTex;
            float _Cutoff;
            float4 frag(v2f_S i) : COLOR 
            {
                half alpha = tex2D(_MainTex, i.uv).a;
                clip(alpha - _Cutoff);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }

        	Pass
		{
			Name "CustomShadow"
			Tags { "LightMode" = "CustomShadow" }
            
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#define _USE_CUSTOM_SHADOWMAP 1

			#include "UnityCG.cginc"
           #include"Assets/TestPro/DreamWorldShader/TA/RenderSystem/CustomShadowmap/Shader/CalcShadow.cginc"
            
            sampler2D _MainTex;
            float _Cutoff;
			struct Attributes
			{
				float4 positionOS : POSITION;
                float2 uv :TEXCOORD0;
            };

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float4 positionWS : TEXCOORD0;
                float2 uv :TEXCOORD1;
			};

			Varyings vert(Attributes input)
			{
				Varyings output = (Varyings)0;
                output.positionWS = mul(unity_ObjectToWorld, input.positionOS);
				output.positionCS = RENDERING_CUSTOM_SHADOWMAP_WORLD_TO_CLIP_POS(output.positionWS);
                output.uv = input.uv;
				return output;
			}

			float4 frag(Varyings input) : SV_Target
			{
                 float alpha =  tex2D(_MainTex , input.uv).a;
                 clip(alpha - _Cutoff);
				RENDERING_CUSTOM_SHADOWMAP_FRAGMENT(input.positionWS.xyz);
			}
			ENDCG
		}

    }
}
