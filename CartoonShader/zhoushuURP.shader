Shader "Custom/zhoushu" 
{
    Properties 
    {
        [HDR] [MainColor] _BaseColor("主颜色", Color) = (1, 1, 1, 1)


        [Header(Main Texture Setting)]
        [Space(5)]
     
        _BaseMap ("漫反射贴图", 2D) = "white" {}
        _BumpMap("法线贴图" , 2D) = "bump"{}
        _BumpItensity("法线强度",Range(0,1)) =1
        
      
        [Space(30)]

        [Header(Shadow Setting)]
        [Space(5)]
       [Toggle(ENABLE_FACE_SHADOW_MAP)] _EnableSDF("EnableSDF" , float) = 0
        _ShadowSmooth("_ShadowSmooth" , Range(0,1)) = 0
        _ShadowArea("_ShadowArea"  ,Range(0,1)) = 0


        _LightMap ("LightMap混合图", 2D) = "white" {}
        _ShapeShadowSmooth("固定阴影平滑" , Range(0,0.1)) =0
          _ShapeShadowPow("固定阴影强度" , Range(0,1))=0

            [Space(10)]
        _RampThreshold("光照阴影范围" , Range(0,1  )) =  0
        _RampSmooth("光照阴影平滑" , Range(0,0.1))=0
        _ShadowMultColor ("亮部颜色", Color) = (0.5, 0.5, 0.5, 1.0)
        _AddLightColor("亮部加色",Color) = (0,0,0,1)
        [Space(10)]
        _DarkShadowMultColor ("暗阴影颜色", Color) = (0.5, 0.5, 0.5, 1.0)
          _AddDarkLightColor("暗色加色",Color) = (0,0,0,1)
          _GIIndirDiffuse("GI强度" , Range(0,1))= 1



          [Space(30)]
            [Toggle] _EnableFace("EnableFace" , Float) = 0
            _HairShadowDistace("_HairShadowDistace" , float )= 0
       

        [Header(Specular Setting)]
        [Space(5)]
        [Toggle]_EnableSpecular ("Enable Specular", Float) = 1
    //    _SpecularShift("shift",2D) = "white"{}
        [HDR]_LightSpecColor ("Specular Color", color) = (0.8, 0.8, 0.8, 1)

        _SpecMulti ("Multiple Factor", range(0.001, 1.0)) = 1
        _MetalIntensity("_MetalIntensity" , Range(0,1))=0.01
        [Space(30)]

        [Header(RimLight Setting)]
        [Space(5)]

        [Toggle]_EnableRim ("Enable Rim", float) = 1
        [HDR]_RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimSmooth ("Rim Smooth", Range(0.001, 1.0)) = 0.01
        _RimPow ("Rim Pow", Range(0.0, 1.0)) = 1.0
  

        [Space(30)]

        [Header(Outline)]
        [Space(5)]
        _outlinecolor ("outline color", Color) = (0,0,0,1)
        _outlinewidth ("outline width", Range(0, 1)) = 0.01
        [Space(30)]
        [Header(Emission)]
        [Toggle] _Emission("Emission ", float) = 0
            _EmissionTex("EmissionTex" ,2D) = "white"{}
        [HDR] _EmissionColor("EmissionColor" , color) = (1,1,1,1)

            [Toggle]_ReciveShadow("_RecvieShadow" , Float)  = 0
            _ShadowStrength("ShadowStrength" , Range(0,1))=1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalRenderPipeline"
         
            "RenderType" = "Opaque"
        }



        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


        CBUFFER_START(UnityPerMaterial) 
        


        float _EnableFace;
        float4 _BaseMap_ST;
        float4 _BaseColor;

        half _BumpItensity;
        half _ShadowSmooth;
        half _ShadowArea;

  
        float4 _LightMap_ST;
   
     float _RampThreshold;
       float _RampSmooth;
       half _ShapeShadowSmooth;
       half  _ShapeShadowPow;

       float _ShadowStrength;

        uniform float4 _ShadowMultColor; //阴影颜色
        float4 _AddLightColor;
        uniform float4 _DarkShadowMultColor; //暗阴影颜色
        float4 _AddDarkLightColor;

        
        float _EnableRim;
        half4 _RimColor;
        float _RimSmooth;
        float _RimPow;

        float _EnableSpecular;
        float4 _LightSpecColor;

        float _SpecMulti;
        float _MetalIntensity;


      
        half3 _EmissionColor;
        float _Emission;
      

        uniform float4 _outlinecolor;
        uniform float _outlinewidth;
  


      
    
        half _GIIndirDiffuse;
        float _HairShadowDistace;

        float _ReciveShadow;

        CBUFFER_END
  

        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);

        TEXTURE2D(_LightMap);
        SAMPLER(sampler_LightMap);
   

        TEXTURE2D(_BumpMap);
        SAMPLER(sampler_BumpMap);

        TEXTURE2D(_EmissionTex);
        SAMPLER(sampler_EmissionTex);
        
        TEXTURE2D(_HairSoildColor);
        SAMPLER(sampler_HairSoildColor);
        TEXTURE2D(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);

        // TEXTURE2D(_SpecularShift);
        // SAMPLER(sampler_SpecularShift);
        // float4 _SpecularShift_ST;

        ENDHLSL

        Pass
        {
            Name "FORWARD"
            Tags{
        "LightMode" = "UniversalForward"
        }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影
            #pragma shader_feature_local ENABLE_FACE_SHADOW_MAP
   
        
            #pragma multi_compile_fog

            struct VertexInput //输入结构
            {
                float3 posOS : POSITION; // 顶点信息 Get✔
                half4 color: COLOR0;
                float2 uv0 : TEXCOORD0; // UV信息 Get✔
                float4 normalOS : NORMAL; // 法线信息 Get✔
                float4 tangentOS : TANGENT; // 切线信息 Get✔
 
            };

            struct VertexOutput //输出结构
            {
                float4 posCS : POSITION; // 屏幕顶点位置
                float4 color: COLOR0;
                float2 uv0 : TEXCOORD1; // UV0
                float3 posWS : TEXCOORD2; // 世界空间顶点位置
                float3 posVS: TEXCOORD3;
                float3 nDirWS : TEXCOORD4; // 世界空间法线方向
                float3 nDirVS :TEXCOORD5;
              float4 posNDC :TEXCOORD6;
               float4 posSS:TEXCOORD7;
              float3 posOS :TEXCOORD8;
                float3 tangentWS :TEXCOORD9;
                float3 bitangentWS :TEXCOORD10;

                half fogFactor :TEXCOORD11;
         
                DECLARE_LIGHTMAP_OR_SH(lightmapUV , vertexSH , 12);
            };


 

            VertexOutput vert(VertexInput v) //顶点shader
            {
                VertexOutput o = (VertexOutput)0; // 新建输出结构
                o.color = v.color;
                 
   
            
                VertexPositionInputs  vertexInput = GetVertexPositionInputs(v.posOS);


                o.tangentWS = TransformObjectToWorld(v.tangentOS);
                o.nDirWS = TransformObjectToWorldNormal(v.normalOS);
         
                half tangentSign = v.tangentOS.w * unity_WorldTransformParams.w;
                o.bitangentWS = cross(o.nDirWS , o.tangentWS)* tangentSign;
                o.posWS = TransformObjectToWorld(v.posOS);
                o.posVS = TransformWorldToView(o.posWS);
                o.posNDC = vertexInput.positionNDC;
                o.posCS = TransformWorldToHClip(o.posWS);
                o.nDirVS = TransformWorldToViewDir(o.nDirWS);
                o.posSS = ComputeScreenPos(o.posCS);
                o.posOS = v.posOS;
              
                 o.uv0 = v.uv0; // 传递UV

                 o.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);


             

                return o; // 返回输出结构
            }   

            half CalculateRamp(half ndlWrapped)
            {
             
                half ramp = smoothstep(_RampThreshold -_RampSmooth, _RampThreshold + _RampSmooth, ndlWrapped);
                return ramp;
            }



           float4 frag(VertexOutput i) : COLOR //像素shader
            {
            
                
                float3 nDir = normalize(i.nDirWS); // 获取nDir
                
                half3 BumpTex =( UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv0)  ));
                BumpTex.xy *= _BumpItensity;

                float3x3 TBN = float3x3(i.tangentWS, i.bitangentWS, i.nDirWS);
                nDir = normalize(mul(BumpTex, TBN))  ;
     
          
               float4 shadowCoord = TransformWorldToShadowCoord(i.posWS.xyz);

                

                Light mainLight = GetMainLight(shadowCoord);
                half shadow =lerp( (1-_ShadowStrength) ,1, mainLight.shadowAttenuation );
                 shadow = lerp (1, shadow, _ReciveShadow);
                    
                float3 lDir = normalize(mainLight.direction);
                //由于面部阴影受光照角度影响极易产生难看的阴影，因此可以虑将光照固定成水平方向，再微调面部法线即可得到比较舒适的面部阴影。
                //_FixLightY=0 即可将光照方向固定至水平。
          
                // 准备点积结果
                float nDotl = dot(nDir, lDir);
                float lambert =  nDotl * 0.5f + 0.5f; // 截断负值




                //采样BaseMap和LightMap，确定最初的阴影颜色ShadowColor和DarkShadowColor 。
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv0) * _BaseColor;
                half4 LightMapColor = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, TRANSFORM_TEX(i.uv0 ,_LightMap) );
                half3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
             
                half4 FinalColor =0;
          
                
        
         
               

                //Ramp阴影
                half3 ShadowColor = baseColor.rgb * _ShadowMultColor.rgb +_AddLightColor * (1- LightMapColor.r);
                half3 DarkShadowColor = baseColor.rgb * _DarkShadowMultColor.rgb +_AddDarkLightColor *(1- LightMapColor.r);
                
                half Ramp = CalculateRamp(lambert);
                //固定阴影
                half regularShadow =  smoothstep(_ShapeShadowPow - _ShapeShadowSmooth, _ShapeShadowPow + _ShapeShadowSmooth, LightMapColor.g);
                Ramp *= regularShadow;
             
                FinalColor.rgb = lerp(DarkShadowColor , ShadowColor, Ramp) * shadow;

            
             
        //脸部SDF 
//===========================================================================================================
         #if ENABLE_FACE_SHADOW_MAP

                //采样阴影贴图
             
                float var_FaceShadow = LightMapColor.r;
                //灯光反转的贴图
                float revert_FaceShadow =SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap,TRANSFORM_TEX( half2(1-i.uv0.x , i.uv0.y),_LightMap ) ).r;
                
                //上方向
                float3 Up =unity_ObjectToWorld._13_23_33;

                //角色朝向
                float3 Front = -unity_ObjectToWorld._12_22_32 ;

                //角色右侧朝向
                float3 Right = cross(Up, Front);

                //阴影贴图左右正反切换的开关
                float switchShadow = dot(normalize(Right.xz), normalize(lDir.xz)) * 0.5 + 0.5 < 0.5;

                //阴影贴图左右正反切换
                float FaceShadow = lerp(1-var_FaceShadow.r,1- revert_FaceShadow, 1-switchShadow.r);

                //脸部阴影范围
                float FaceShadowRange = dot(normalize(Front.xz), normalize(lDir.xz));

                //使用阈值来计算阴影
                float lightAttenuation = 1-smoothstep(FaceShadowRange -_ShadowSmooth, FaceShadowRange, FaceShadow -_ShadowArea );


                half3 FaceColor = lerp(DarkShadowColor, ShadowColor, lightAttenuation);
           
              FinalColor.rgb = FaceColor   ;
     
           #endif



//===========================================================================================================
  
        half3 bakeGI = SampleSH(nDir);
                half3 indirectDiffuse = bakeGI * baseColor.rgb *_GIIndirDiffuse ;
                FinalColor.rgb += indirectDiffuse;


        //Custom RimLight 
//===========================================================================================================
  
  
            float2 L_View = normalize(mul((float3x3)UNITY_MATRIX_V, lDir).xy)*(1/i.posNDC.w);
            float2 N_View = normalize(mul(UNITY_MATRIX_VP,half4( nDir,1.0)).xy)*(1/i.posNDC.w) ;
           
         
            
          //  float lDotN = saturate(dot(N_View, -L_View)  );
            float2 screenPos= i.posSS.xy/ i.posSS.w;
        //    float aspect1 = _ScreenParams.x / _ScreenParams.y;
        


            float depth =(i.posSS.z / i.posSS.w);
            
            float linearDepth = LinearEyeDepth(depth  , _ZBufferParams) ; //离相机越近越小


            N_View = half2(N_View.x , 0)/_ScreenParams.x ;
            float2 scale =  ( (_RimPow *15 )  *N_View   ) ;
          
            float2 ssUV1 = ( screenPos +  scale ) ;
           

            float depthDiff = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture , sampler_CameraDepthTexture, ssUV1 ).r, _ZBufferParams) ;
			
            depthDiff = depthDiff - linearDepth  ;

            float intensity = step(0.5 , depthDiff);
	
            float4 rimColor = intensity * _RimColor * _EnableRim;
          
  
           
            FinalColor.rgb += rimColor.rgb;
  
  

//===========================================================================================================
//         i.posSS /= i.posSS.w;
// 	     float N = sign( -normalize(mul(UNITY_MATRIX_VP,half4( nDir,1.0)).x) )  ;
// 		 float2 originPos = i.posSS.xy / _ScreenParams.zw;
//          float rim = (_RimPow *15 / i.posCS.w) / _ScreenParams.x;
//          float2 offsetPos = half2(rim , 0) * N ;
// 		 offsetPos = originPos  - offsetPos;
//        float origindepth =  Linear01Depth(SAMPLE_TEXTURE2D(_CameraDepthTexture , sampler_CameraDepthTexture, originPos ).r, _ZBufferParams) ;
//        float offsetdepth =  Linear01Depth(SAMPLE_TEXTURE2D(_CameraDepthTexture , sampler_CameraDepthTexture, offsetPos ).r, _ZBufferParams) ;
//     float depthDiff = offsetdepth - origindepth;
// return depthDiff;
//===========================================================================================================
          
              float2 scrPos = i.posSS.xy / i.posSS.w;
              //获取屏幕信息
         
              //计算View Space的光照方向
              //由于阴影近小远大 因此需要 1/NDC.w
              float3 viewLightDir = normalize(TransformWorldToViewDir(lDir)) * (1/ i.posNDC.w );
              float aspectX = _ScreenParams.x / _ScreenParams.y;
             float aspectY = _ScreenParams.y / _ScreenParams.x;
              //计算采样点，其中_HairShadowDistace用于控制采样距离
        
              float2 samplingPoint = scrPos + _HairShadowDistace * viewLightDir.xy * 0.01 * half2(  1 ,aspectX  ); // * float2(1 / _ScreenParams.x, 1 / _ScreenParams.y)  ;
            
              float depthZ = (i.posCS.z / i.posCS.w) * 0.5 + 0.5;
  
              float hairDepth = SAMPLE_TEXTURE2D(_HairSoildColor, sampler_HairSoildColor, samplingPoint).g ;
            
              float mask = smoothstep(1.65+ 0.01,1.6-0.01 , i.posOS.z );

              float depthCorrect = depthZ *mask  < hairDepth + 0.01 ? 0.5 : 1;
             // //若采样点在阴影区内,则取得的value为1,作为阴影的话还得用1 - value;
        //      float hairShadow = 1 - SAMPLE_TEXTURE2D(_HairSoildColor, sampler_HairSoildColor, samplingPoint).r *0.5;
                depthCorrect = lerp(1 , depthCorrect , _EnableFace);
              //将作为二分色依据的ramp乘以shadow值
   
              FinalColor *= depthCorrect  ;
          




    // Specular-----------------------------------------------------------------------------------  
      
                half3 halfViewLightWS = normalize(viewDirWS + mainLight.direction.xyz);

              //  half spec = pow(saturate(dot(i.nDirWS, halfViewLightWS)), _Shininess);
                half nh = saturate(dot(nDir, halfViewLightWS));
                half specSize = 1-(_SpecMulti * LightMapColor.b);
           
                nh = nh * (1.0 / ( 1.0 -specSize)) - (specSize / ( 1.0-specSize));

                float specSmoothness = fwidth(nh);
     

                half spec = smoothstep(0, specSmoothness, nh) *step(0.1, LightMapColor.r);



      //-------------------------------------------------------------------------------------   
             //   spec = step(1.0f - LightMapColor.b, spec);
               
                half4 specularColor = _EnableSpecular * _LightSpecColor  * LightMapColor.r * spec * _MetalIntensity * shadow;
     

     

                // Rim Light
     
               
             //   float4 rim =(smoothstep(_RimPow - _RimSmooth, _RimPow+_RimSmooth, 1- saturate(dot(viewDirWS,  nDir)))) * _RimColor * _EnableRim;
              
                half4 Emission;
                Emission = SAMPLE_TEXTURE2D(_EmissionTex, sampler_EmissionTex, i.uv0);
                Emission.rgb = _Emission  * _EmissionColor.rgb ;
                Emission.a = baseColor.a ;

            
              
       
               
                FinalColor +=  specularColor  + Emission   ;// + SpecRimEmission.a * SpecRimEmission;
               
            
               FinalColor.rgb = MixFog(FinalColor.rgb, i.fogFactor);
                return FinalColor;
            }
            ENDHLSL
        }


   Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

       
                
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
            #define _DETAIL
            #endif

            // GLES2 has limited amount of interpolators
            #if defined(_PARALLAXMAP) && !defined(SHADER_API_GLES)
            #define REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR
            #endif

            #if (defined(_NORMALMAP) || (defined(_PARALLAXMAP) && !defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR))) || defined(_DETAIL)
            #define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
            #endif

            struct Attributes
            {
                float4 positionOS     : POSITION;
                float4 tangentOS      : TANGENT;
                float2 texcoord     : TEXCOORD0;
                float3 normal       : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD1;
                half3 normalWS     : TEXCOORD2;

                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
                half4 tangentWS    : TEXCOORD4;    // xyz: tangent, w: sign
                #endif

                half3 viewDirWS    : TEXCOORD5;

                #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                half3 viewDirTS     : TEXCOORD8;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            Varyings DepthNormalsVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.uv         = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);

                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
                output.normalWS = half3(normalInput.normalWS);
                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                    float sign = input.tangentOS.w * float(GetOddNegativeScale());
                    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                #endif

                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
                    output.tangentWS = tangentWS;
                #endif

                #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
                    output.viewDirTS = viewDirTS;
                #endif

                return output;
            }


            half4 DepthNormalsFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

              half4 col =   SAMPLE_TEXTURE2D( _BaseMap,  sampler_BaseMap,input.uv).a *_BaseColor;
                 clip(col.a - _Cutoff);

                #if defined(_GBUFFER_NORMALS_OCT)
                    float3 normalWS = normalize(input.normalWS);
                    float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
                    float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
                    half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
                    return half4(packedNormalWS, 0.0);
                #else
                    float2 uv = input.uv;
                    #if defined(_PARALLAXMAP)
                        #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                            half3 viewDirTS = input.viewDirTS;
                        #else
                            half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, input.viewDirWS);
                        #endif
                        ApplyPerPixelDisplacement(viewDirTS, uv);
                    #endif

                    #if defined(_NORMALMAP) || defined(_DETAIL)
                        float sgn = input.tangentWS.w;      // should be either +1 or -1
                        float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                        float3 normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);

                        #if defined(_DETAIL)
                            half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
                            float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
                            normalTS = ApplyDetailNormal(detailUv, normalTS, detailMask);
                        #endif

                        float3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
                    #else
                        float3 normalWS = input.normalWS;
                    #endif

                    return half4(NormalizeNormalPerPixel(normalWS), 0.0);
                #endif
            }

            ENDHLSL
        }


        Pass
        {
       Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
        
            ZWrite On
            ColorMask 0
        
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
                    
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment


        struct Attributes
        {
            float3 positionOS: POSITION;
            half4 color: COLOR0;
            half3 normalOS: NORMAL;
            half4 tangentOS: TANGENT;
            float2 texcoord: TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionCS: POSITION;
            float4 color: COLOR0;
            float4 uv: TEXCOORD0;
        
      
        

        };
     Varyings DepthOnlyVertex(Attributes input)
        {
            Varyings output = (Varyings)0;
            output.color = input.color;

           VertexPositionInputs vertexInput  = GetVertexPositionInputs(input.positionOS);
            output.positionCS = vertexInput.positionCS;
       
            output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);


       
            return output;
        }


        half4 DepthOnlyFragment(Varyings input): SV_TARGET
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            #if ENABLE_ALPHA_CLIPPING
                clip(SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).b - _Cutoff);
            #endif


            return 0;
        }
            // Again, using this means we also need _BaseMap, _BaseColor and _Cutoff shader properties
            // Also including them in cbuffer, except _BaseMap as it's a texture.

            ENDHLSL



        }

            Pass
        {
            Name "Outline"
            Tags
            {
            }
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv0 : TEXCOORD0; // UV信息 Get✔
            };

            struct VertexOutput
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0; // UV0
            };

inline float4 CalculateOutlineVertexClipPosition(float4 vertex ,float3 normal)
{                                                                                                //y = near plane
    float4 nearUpperRight = mul(unity_CameraInvProjection ,float4(1,1,UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));
    float aspect = abs(nearUpperRight.y / nearUpperRight.x);
    VertexPositionInputs VertexInputs = GetVertexPositionInputs(vertex);
    //修正像素比例
    float aspect1 = _ScreenParams.x / _ScreenParams.y;
    float4 o_vertex = VertexInputs.positionCS;
    float4 posNDC = VertexInputs.positionNDC;
    float3 viewNormal = mul((float3x3)UNITY_MATRIX_IT_MV , normal);
;
    float3 clipNormal = mul((float3x3) UNITY_MATRIX_P,viewNormal);
    float2 projectedNormal = normalize(clipNormal.xy);
    //由于顶点从裁剪空间转换到屏幕空间需要做齐次除法/w 为了防止值被修改因此先给他乘一个w
    //将法线转换到NDC空间
     projectedNormal *= min(o_vertex.w  , 2);
     //远小近大
     //projectedNormal *= ( posNDC.w);
     //当屏幕比例不为1：1时，对x进行修正
    projectedNormal.y *= aspect1;
     o_vertex.xy += _outlinewidth * projectedNormal.xy * saturate(1 - abs(normalize(viewNormal).z)) * 0.01;
     return o_vertex;

 }

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = CalculateOutlineVertexClipPosition(v.vertex , v.normal);
                o.uv0 = TRANSFORM_TEX(v.uv0 , _BaseMap);
                return o;
            }

            float4 frag(VertexOutput i) : COLOR
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv0);
                half4 FinalColor = _outlinecolor * baseColor;
                return FinalColor;
            }
            ENDHLSL
        }


        UsePass "Universal Render Pipeline/Lit/ShadowCaster"


    }
}