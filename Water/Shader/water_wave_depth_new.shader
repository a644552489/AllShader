// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
Shader "Hsx/water_wave_depth"
{
    Properties 
    {		
        [HideInInspector] _WaterColor("WaterColor",Color) = (0,.25,.4,1)//海水颜色
        [HideInInspector] _FarColor("反射颜色",Color)=(.2,1,1,.3)//反射颜色
        [HideInInspector] _BumpMap("BumpMap", 2D) = "white" {}//法线贴图
        [HideInInspector] _BumpPower("BumpPower",Range(-1,1))=.6//法线强度
        [HideInInspector] _WaveSize("WaveSize",Range(0.01,1))=.25//波纹大小
        [HideInInspector] _WaveOffset("WaveOffset(xy&zw)",vector)=(.1,.2,-.2,-.1)//波纹流动方向

        [HideInInspector] _EdgeColor("EdgeColor",Color)=(0,1,1,0)//海浪颜色
        [HideInInspector] _EdgeTex("EdgeTex",2D)="white" {}//海浪贴图
        [HideInInspector] _EdgePower ("边缘海浪强度", Range(0, 4)) = 1.0
        [HideInInspector] _WaveTex("WaveTex",2D)="white" {}//海浪周期贴图
        [HideInInspector] _WaveSpeed("WaveSpeed",Range(0,10))=1//海浪速度
        [HideInInspector] _NoiseTex("Noise", 2D) = "white" {} //海浪躁波
        [HideInInspector] _NoiseRange ("NoiseRange", Range(0,10)) = 1//海浪躁波强度
        [HideInInspector] _EdgeRange("EdgeRange",Range(0.1,10))=.4//边缘混合度 [目前只有相机深度图用到]

        _LightColor("灯光颜色",Color)=(1,1,1,1)//光源颜色
        _LightVector("xyz：灯光方向, w：灯光强度",vector)=(.5,.5,.5,100)//光源方向

        // [Space(20)]
        [HideInInspector] [KeywordEnum(CubeMap, SimpleTexture, OFF)] _Reflect ("反射贴图模式", Float) = 0
        [HideInInspector] _Cubemap ("Cubemap", CUBE) = ""{}//反射
        [HideInInspector] _EnvMapSampler ("反射图(可以是天空贴图之类的)", 2D) = "black" {}
        [HideInInspector] _ReflAmount ("反射强度", Range(0, 2)) = 0.5
        [HideInInspector] _ReflDistortionPower ("反射扰动强度", Range(0, 0.2)) = 0
        // _Fresnel("菲涅尔系数", Range(0, 2)) = 0.5

        // [Space(20)]
        [HideInInspector] [KeywordEnum(CAMERA, OFFLINE, MODELCOLOR, OFF)] _Depth ("深度图模式", Float) = 0
        [HideInInspector] _DepthTex ("离线深度图", 2D) = "black" {}
        // [Toggle(_DEPTH_ON)] _DEPTH_ON ("_Depth", Float) = 0

        // [Space(10)]
        // _Test ("_Test", Range(0,20)) = 1
		[Toggle(_DepthTexOn)] _DepthTexOn("只显示深度图", Float) = 0
		[Toggle(_ReflectTexOn)] _ReflectTexOn("只显示反射图", Float) = 0


    }
    
    SubShader
    {
        Tags{ 
            "RenderType" = "Opaque" 
            "Queue" = "Transparent"
        }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 200
        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            // 相机深度图、离线深度图、关闭深度图、顶点色
            #pragma multi_compile __ _DEPTH_CAMERA _DEPTH_OFFLINE _DEPTH_MODELCOLOR _DEPTH_OFF
            #pragma multi_compile __ _REFLECT_CUBEMAP _REFLECT_SIMPLETEXTURE _REFLECT_OFF
            #pragma multi_compile __ _DepthTexOn _ReflectTexOn
            #pragma target 3.0
            #include "UnityCG.cginc"

            fixed4 _WaterColor;
            fixed4 _FarColor;

            sampler2D _BumpMap;
            half _BumpPower;
			fixed4 _BumpMap_TexelSize;

            half _WaveSize;
            half4 _WaveOffset;

            #if _REFLECT_CUBEMAP
                samplerCUBE _Cubemap;
            #elif _REFLECT_SIMPLETEXTURE
                uniform sampler2D _EnvMapSampler;
                half _ReflDistortionPower;
            #endif
            #if !REFLECT_OFF
                half _ReflAmount;
                // half _Fresnel; // 是否有必要 ???
            #endif
            // float _Test;

            #if !_DEPTH_OFF
                fixed4 _EdgeColor;
                sampler2D _EdgeTex , _WaveTex , _NoiseTex;
                half _EdgePower;
                half4 _NoiseTex_ST;
                half _WaveSpeed;
                half _NoiseRange;

                #if _DEPTH_CAMERA
                    sampler2D_float _CameraDepthTexture;
                    half _EdgeRange;
                #elif _DEPTH_OFFLINE
                    sampler2D _DepthTex;
                #endif
            #endif

            fixed4 _LightColor;
            half4 _LightVector;

            struct a2v 
            {
                float4 vertex:POSITION;
                float4 texcoord:TEXCOORD1;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                fixed4 color : COLOR;
            };
            struct v2f
            {
                half4 pos : POSITION;
                half3 lightDir:TEXCOORD0;
                half4 screenPos:TEXCOORD1;
                half4 uv : TEXCOORD2;
                #if !_DEPTH_OFF  
                    half2 uv_noise : TEXCOORD3;
                #endif
                half4 TtoW0 : TEXCOORD4;  
                half4 TtoW1 : TEXCOORD5;  
                half4 TtoW2 : TEXCOORD6; 

                half2 uv_main : TEXCOORD7;
                float4 color : COLOR;
            };

            //unity没有取余的函数，自己写一个
            half2 fract(half2 val)
            {
                return val - floor(val);
            }

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				float scale = -1.0;
//#if UNITY_UV_STARTS_AT_TOP
//				scale = -1.0;
//#else
//				scale = -1.0;
//#endif
//				//float4 o = pos /** 0.5f;
//				//o.xy = float2(o.x, o.y*scale) + o.w;*/
//				//o.uv_main = v.texcoord.xy;//* _BumpMap_ST.xy + _BumpMap_ST.zw;
				o.uv_main = v.texcoord.xy * scale;

//				//dx中纹理从左上角为初始坐标，需要反向
//#if UNITY_UV_STARTS_AT_TOP
//				//if (_BumpMap_TexelSize.y < 0)
//#else
//					o.uv_main.y = 1 - o.uv_main.y;
//#endif	

                TANGENT_SPACE_ROTATION;  
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));  
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;  

                float3x3 WtoT = mul(rotation, (float3x3)unity_WorldToObject);  
                o.TtoW0 = float4(WtoT[0].xyz, worldPos.x);  
                o.TtoW1 = float4(WtoT[1].xyz, worldPos.y);  
                o.TtoW2 = float4(WtoT[2].xyz, worldPos.z);  

                float4 wPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv.xy = worldPos.xz * _WaveSize + _WaveOffset.xy * _Time.y;
                o.uv.zw = worldPos.xz * _WaveSize * 2 + _WaveOffset.zw * _Time.y;
                #if !_DEPTH_OFF  
                    o.uv_noise = TRANSFORM_TEX (v.texcoord , _NoiseTex);
                #endif

                o.screenPos = ComputeScreenPos(o.pos);
                COMPUTE_EYEDEPTH(o.screenPos.z);
                
                #if _DEPTH_MODELCOLOR
                    o.color = v.color;
                #endif

                return o;
            }
            
            fixed4 frag(v2f i):COLOR 
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);  //世界空间位置
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos)); //世界空间摄像机方向
                fixed3 lightDir = normalize(_LightVector.xyz);//世界空间灯光方向

                //海水颜色
                fixed4 col=_WaterColor;

                //计算法线
                half3 nor = UnpackNormal((tex2D(_BumpMap,fract(i.uv.xy)) + tex2D(_BumpMap,fract(i.uv.zw)))*0.5); 
                nor.xy *= _BumpPower;
                half3 worldNormal = normalize(mul(nor, float3x3(i.TtoW0.xyz, i.TtoW1.xyz, i.TtoW2.xyz)));//世界空间的法线

                //计算高光
                half spec =saturate(dot(worldNormal,normalize(lightDir + worldViewDir)));  
                spec = pow(spec, _LightVector.w); 

                //计算菲涅耳反射
                #if _REFLECT_CUBEMAP
                    // cubemap
                    half fresnel = 1 - saturate(dot(worldNormal, worldViewDir)); 
                    fixed3 worldRefl = reflect (-worldViewDir, worldNormal);  // 是否丢到顶点着色器里面去计算 ???
                    fixed3 reflCol = texCUBE(_Cubemap, worldRefl).rgb * _ReflAmount; 
                    // _FarColor.rgb *= reflCol;
                    _FarColor.rgb = reflCol;
                    col = lerp(col, _FarColor, fresnel);
                    
                #elif _REFLECT_SIMPLETEXTURE
                    //// 简单反射图
                    //// float4 changeViewDir = normalize(float4(worldViewDir.x, worldViewDir.y, worldViewDir.z * _Test, 0)); // trick: z*10是为了加深z方向的扭曲强度
                    //float2 reflexUV = float2((worldViewDir.x + 1) * 0.5, (worldViewDir.y + 1) * 0.5); // trick: 如(x+1)*0.5 是为了将原点偏移到中心(0.5,0.5), 以保证旋转时反射图采样总是在中心位置
                    //float reflectTex = tex2D(_EnvMapSampler, reflexUV + worldNormal * _ReflDistortionPower) * _ReflAmount;
                    //_FarColor.rgb *= reflectTex;
                    //// float3 changeNormalDir = float3(0, 0, 0.3); // trick: 法线方向永远偏向上
                    //half fresnel = 1 - saturate(dot(worldNormal, worldViewDir)); 
                    //float4 finalReflectCol = reflectTex * fresnel;
                    //col += finalReflectCol;
                    //// // return finalReflectCol;

					// 法二：
					float2 reflexUV = (i.screenPos / i.screenPos.w);
					fixed3 reflCol = tex2D(_EnvMapSampler, reflexUV + worldNormal * _ReflDistortionPower) * _ReflAmount;
					//_FarColor.rgb *= reflCol;
					half fresnel = 1 - saturate(dot(worldNormal, worldViewDir));
					//col = lerp(col, _FarColor, fresnel);
					col = lerp(col, fixed4(reflCol, 1.0), fresnel);

					#if _ReflectTexOn
						return fixed4(reflCol, 1.0);
					#endif
                #endif
                
                //计算海水边缘以及海浪
                #if !_DEPTH_OFF
                    half depth = 0;
                    #if _DEPTH_CAMERA
                        // 相机深度图
                        depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)));  
                        depth = saturate((depth-i.screenPos.z)*_EdgeRange);
                        
                    #elif _DEPTH_OFFLINE
                        // 离线烘焙出来的水平高度图
                        depth = tex2D(_DepthTex, i.uv_main).r;
                        // depth = saturate(depth) * _EdgeRange;
                        
                    #elif _DEPTH_MODELCOLOR
                        depth = i.color.r;
                    #endif

                    #if _DepthTexOn
                        return fixed4(depth, depth, depth, 1.0);
                    #endif

                    fixed noise = tex2D(_NoiseTex, i.uv_noise).r;
                    fixed wave=tex2D(_WaveTex, fract(half2(_Time.y*_WaveSpeed+ depth + noise * _NoiseRange,0.5))).r;
                    fixed edge = saturate((tex2D(_EdgeTex,i.uv.xy*5).a + tex2D(_EdgeTex,i.uv.zw *2).a)*0.5) * wave;

                    // fixed edge = saturate((tex2D(_EdgeTex, i.uv_noise).a)) * wave;  // 可合并 把noiseTex 的 tiling 改为40 即可
                    col.rgb +=_EdgeColor * edge *(1-depth) * _EdgePower; 
                    
                    // 边缘透明
                    col.a = lerp(0, col.a, depth);
                #endif

                col.rgb+= _LightColor * spec;  
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return col;  
            }
            ENDCG
        }
    }

    //反射版本
    SubShader
    {
        Tags{ 
            "RenderType" = "Opaque" 
            "Queue" = "Transparent"
        }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100
        Pass{
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            // 相机深度图、离线深度图、关闭深度图、顶点色
            #pragma multi_compile __ _DEPTH_CAMERA _DEPTH_OFFLINE _DEPTH_MODELCOLOR _DEPTH_OFF
            #pragma multi_compile __ _DepthTexOn _ReflectTexOn
            #pragma target 3.0
            #include "UnityCG.cginc"

            fixed4 _WaterColor;
            fixed4 _FarColor;

            sampler2D _BumpMap;
            half _BumpPower;
			fixed4 _BumpMap_TexelSize;

            half _WaveSize;
            half4 _WaveOffset;

            #if !REFLECT_OFF
                half _ReflAmount;
                // half _Fresnel; // 是否有必要 ???
            #endif
            // float _Test;

            #if !_DEPTH_OFF
                fixed4 _EdgeColor;
                sampler2D _EdgeTex , _WaveTex , _NoiseTex;
                half _EdgePower;
                half4 _NoiseTex_ST;
                half _WaveSpeed;
                half _NoiseRange;

                #if _DEPTH_CAMERA
                    sampler2D_float _CameraDepthTexture;
                    half _EdgeRange;
                #elif _DEPTH_OFFLINE
                    sampler2D _DepthTex;
                #endif
            #endif

            fixed4 _LightColor;
            half4 _LightVector;

            struct a2v 
            {
                float4 vertex:POSITION;
                float4 texcoord:TEXCOORD1;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                fixed4 color : COLOR;
            };
            struct v2f
            {
                half4 pos : POSITION;
                half3 lightDir:TEXCOORD0;
                half4 screenPos:TEXCOORD1;
                half4 uv : TEXCOORD2;
                #if !_DEPTH_OFF  
                    half2 uv_noise : TEXCOORD3;
                #endif
                half4 TtoW0 : TEXCOORD4;  
                half4 TtoW1 : TEXCOORD5;  
                half4 TtoW2 : TEXCOORD6; 

                half2 uv_main : TEXCOORD7;
                float4 color : COLOR;
            };

            //unity没有取余的函数，自己写一个
            half2 fract(half2 val)
            {
                return val - floor(val);
            }

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				float scale = -1.0;
//#if UNITY_UV_STARTS_AT_TOP
//				scale = -1.0;
//#else
//				scale = -1.0;
//#endif
//				//float4 o = pos /** 0.5f;
//				//o.xy = float2(o.x, o.y*scale) + o.w;*/
//				//o.uv_main = v.texcoord.xy;//* _BumpMap_ST.xy + _BumpMap_ST.zw;
				o.uv_main = v.texcoord.xy * scale;

//				//dx中纹理从左上角为初始坐标，需要反向
//#if UNITY_UV_STARTS_AT_TOP
//				//if (_BumpMap_TexelSize.y < 0)
//#else
//					o.uv_main.y = 1 - o.uv_main.y;
//#endif	

                TANGENT_SPACE_ROTATION;  
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));  
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;  

                float3x3 WtoT = mul(rotation, (float3x3)unity_WorldToObject);  
                o.TtoW0 = float4(WtoT[0].xyz, worldPos.x);  
                o.TtoW1 = float4(WtoT[1].xyz, worldPos.y);  
                o.TtoW2 = float4(WtoT[2].xyz, worldPos.z);  

                float4 wPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv.xy = worldPos.xz * _WaveSize + _WaveOffset.xy * _Time.y;
                o.uv.zw = worldPos.xz * _WaveSize * 2 + _WaveOffset.zw * _Time.y;
                #if !_DEPTH_OFF  
                    o.uv_noise = TRANSFORM_TEX (v.texcoord , _NoiseTex);
                #endif

                o.screenPos = ComputeScreenPos(o.pos);
                COMPUTE_EYEDEPTH(o.screenPos.z);
                
                #if _DEPTH_MODELCOLOR
                    o.color = v.color;
                #endif

                return o;
            }
            
            fixed4 frag(v2f i):COLOR 
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);  //世界空间位置
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos)); //世界空间摄像机方向
                fixed3 lightDir = normalize(_LightVector.xyz);//世界空间灯光方向

                //海水颜色
                fixed4 col=_WaterColor;

                //计算法线
                half3 nor = UnpackNormal((tex2D(_BumpMap,fract(i.uv.xy)) + tex2D(_BumpMap,fract(i.uv.zw)))*0.5); 
                nor.xy *= _BumpPower;
                half3 worldNormal = normalize(mul(nor, float3x3(i.TtoW0.xyz, i.TtoW1.xyz, i.TtoW2.xyz)));//世界空间的法线

                //计算高光
                half spec =saturate(dot(worldNormal,normalize(lightDir + worldViewDir)));  
                spec = pow(spec, _LightVector.w); 
                
                //计算海水边缘以及海浪
                #if !_DEPTH_OFF
                    half depth = 0;
                    #if _DEPTH_CAMERA
                        // 相机深度图
                        depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)));  
                        depth = saturate((depth-i.screenPos.z)*_EdgeRange);
                        
                    #elif _DEPTH_OFFLINE
                        // 离线烘焙出来的水平高度图
                        depth = tex2D(_DepthTex, i.uv_main).r;
                        // depth = saturate(depth) * _EdgeRange;
                        
                    #elif _DEPTH_MODELCOLOR
                        depth = i.color.r;
                    #endif

                    #if _DepthTexOn
                        return fixed4(depth, depth, depth, 1.0);
                    #endif

                    fixed noise = tex2D(_NoiseTex, i.uv_noise).r;
                    fixed wave=tex2D(_WaveTex, fract(half2(_Time.y*_WaveSpeed+ depth + noise * _NoiseRange,0.5))).r;
                    fixed edge = saturate((tex2D(_EdgeTex,i.uv.xy*5).a + tex2D(_EdgeTex,i.uv.zw *2).a)*0.5) * wave;

                    // fixed edge = saturate((tex2D(_EdgeTex, i.uv_noise).a)) * wave;  // 可合并 把noiseTex 的 tiling 改为40 即可
                    col.rgb +=_EdgeColor * edge *(1-depth) * _EdgePower; 
                    
                    // 边缘透明
                    col.a = lerp(0, col.a, depth);
                #endif

                col.rgb+= _LightColor * spec;  
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return col;  
            }
            ENDCG
        }
    }
    FallBack Off
    CustomEditor "WaterShaderGUI"
}