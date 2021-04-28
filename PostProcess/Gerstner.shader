Shader "Unlit/Gerstner"
{
    Properties
    {
       [HDR]_Tint("颜色", Color) = (1,1,1,1)
        _MainTex ("主贴图", 2D) = "white" {}
      //_q("_q" ,float) = 1
      //    _p("_p" ,float) = 1
        //  _direction("_dir" , float) = 1
      //  _v("_v" ,float) =1
      //  _m("_m" , float ) =1
        _WaveMap("波浪法线" , 2D) = "white"{}
        [NoScaleOffset]_ReflectionMap("反射探针Cube" , Cube) = ""{}
       _NoiseTex("噪波贴图"  ,2D) = "white"{}
           _SpeedX("速度X" , Range(-1,1)) = 0.5
            _SpeedY("速度Y" , Range(-1,1)) = 0.5
               _BumpPower("法线强度" ,Range(0,2))=1
               _Fresnel("菲涅尔高光分布" , float) = 20
        _Edge("边缘白沫" , float) =1
        _Gloss("高光粗糙" ,Range(0,1)) = 1
        _GlossPower("高光强度" , Range(0,2)) = 2
        _Distortion("反射扰动" , Range(-1,1)) = 1
        _LerpFactor("扭曲强度" , float) =5
        _Vector3("高光方向" ,vector) = (1,1,1)
        _ReflecitonPower("反射强度",float) = 1
        _BombColor("_BombColor" , Color)=(1,1,1,1)
        _BombPower("泡沫强度",float)= 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" 	 }
        LOD 100

        GrabPass{
           "_GrabTex"
        }

        Pass
        {
         //   Cull Off
            ZWrite Off
        //    Blend SrcAlpha OneMinusSrcAlpha 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include"Lighting.cginc"
            #define pi 3.14159
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent :TANGENT;
              
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
   
                float4 vertex : SV_POSITION;
                float4 scrPos:TEXCOORD2;
                float4 TBN0:TEXCOORD3;
                float4 TBN1:TEXCOORD4;
                float4 TBN2:TEXCOORD5;
    
                float4 grabpos:TEXCOORD6;
                float2 noise_uv:TEXCOORD7;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _direction;
            float _q;
            float _p;
            float _v;
            float _m;
           float _Gloss;
            sampler2D _WaveMap;
            float4 _WaveMap_ST;
            sampler2D _CameraDepthTexture;
    
            float4 _GrabTex_TexelSize;
           float  _Edge;
           float _Distortion;
           float _SpeedX;
           float _SpeedY;
           float _BumpPower;
           samplerCUBE _ReflectionMap;
           float4 _Tint;
           sampler2D _GrabTex;
           float _LerpFactor;
           sampler2D _NoiseTex;
           float4 _NoiseTex_ST;
           float _Fresnel;
           float3 _Vector3;
           float _GlossPower;
           float _ReflecitonPower;
           float4 _BombColor;
           half _BombPower;
            float GenstnerWave(float dir ,float3 worldPos)
            {
                float direction = dir;
                float t = _Time.y   ;
                float rotX = worldPos.x * cos(direction) - worldPos.z * sin(direction);
                float rotZ = worldPos.x * sin(direction) + worldPos.z * cos(direction);
                  worldPos = float3(rotX, worldPos.y, rotZ);
              float x = worldPos.z;
                float offset = abs(sin(0.5 * pi * (t + x*_m)));
                float func = abs((0.5 * (x*_m + t + 1) - floor(0.5 * (x*_m + t + 1)) - 0.5) * _q);
                
                float df =_m* pi*cos((pi * x*_m + pi*t)/2) *sin((pi*x*_m + pi*t)/2);
                float dx = 2 * abs(sin((pi * x *_m + pi *t)/2));
                float i = df/dx * offset *_v +2;
                float wave =  pow(func*offset, _p) * i/3;
                return wave;    
            }

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o)

               float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBitangent = cross(worldNormal , worldTangent) * v.tangent.w;
                //TBN
                o.TBN0 = float4(worldTangent.x , worldBitangent.x , worldNormal.x ,worldPos.x);
                o.TBN1 = float4(worldTangent.y , worldBitangent.y ,worldNormal.y ,worldPos.y);
                o.TBN2 = float4(worldTangent.z , worldBitangent.z ,worldNormal.z ,worldPos.z);

              //  float wave = GenstnerWave(_dir+0.3 ,worldPos);
            //    float wave1 = GenstnerWave(_dir - 0.2, worldPos);
             //   float wave2 = GenstnerWave(_dir + 1.5, worldPos);
    
          //     v.vertex.z += wave;
          //    v.vertex.z += wave1;
           //    v.vertex.z += wave2;
                
               o.vertex = UnityObjectToClipPos(v.vertex);
               o.scrPos =ComputeScreenPos(o.vertex);
               o.grabpos = ComputeGrabScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.scrPos.z);

               o.noise_uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw= TRANSFORM_TEX(v.uv , _WaveMap);
        
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TBN0.w,i.TBN1.w,i.TBN2.w);
                float3 viewDir =normalize( UnityWorldSpaceViewDir(worldPos));
                half3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 worldNormal = fixed3(i.TBN0.z, i.TBN1.z, i.TBN2.z);

                float2 Speed = _Time.y * float2(_SpeedX, _SpeedY);
                half3 bump1 = UnpackNormal(tex2D(_WaveMap ,i.uv.zw + Speed )).rgb;
                half3 bump2 = UnpackNormal(tex2D(_WaveMap ,i.uv.zw - Speed  )).rgb;
                fixed3 bump = normalize(bump1 + bump2);
             
                


                float2 noiseUV = float2((i.noise_uv.x + _Time.y * _SpeedX) + bump1.x, (i.noise_uv.y + _Time.y *_SpeedY) + bump1.y);
                float  noise = tex2D(_NoiseTex, noiseUV).r;

                float2 offset = bump.xy * _LerpFactor ;
               i.grabpos.xy = offset * i.grabpos.z + i.grabpos.xy;
    
               worldNormal -= float3(noise * _Distortion,0,noise * _Distortion );

                bump = normalize(half3(dot(i.TBN0.xyz, bump), dot(i.TBN1.xyz, bump), dot(i.TBN2.xyz, bump))) * _BumpPower;
         
                fixed3 col = tex2D(_MainTex, i.uv.xy).xyz * _Tint.xyz;
            
              
                fixed3 halfvec = (_Vector3 + worldLight) ;
                 fixed DotNH =dot(halfvec, bump)*0.5 +0.5;
                 fixed DotNHP = smoothstep(_Gloss, 1, DotNH);
                 fixed specular = DotNHP* _GlossPower;
               
     
                fixed fresnel =pow( 1-saturate(dot(viewDir , bump)), _Fresnel);
                
               float depth =SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,i.scrPos);
                float sceneZ =LinearEyeDepth(depth);
               float partZ =i.scrPos.z - _Edge;
               float foamLine =1- saturate(_Edge * (sceneZ - i.scrPos.w)) ;

              

            
               
               float3 surfacenoise = step(noise,  foamLine* _BombPower) * _BombColor ;
               
          

               fixed3 diffuse = DotNH * col;
            
               diffuse += surfacenoise ;
            

              fixed3 refract =  tex2D(_GrabTex, i.grabpos.xy / i.grabpos.w ).rgb;
           
               fixed3  reflectDir = reflect(-viewDir, worldNormal );
               fixed4 ref = texCUBE(_ReflectionMap, reflectDir  );
               float3 reflection = DecodeHDR(ref, unity_SpecCube0_HDR) ;
               reflection = pow(reflection, 2)* _ReflecitonPower;

               half3 finalColor = specular*(fresnel) + reflection + diffuse +refract ;
            
            //   return whitebomb;
            return fixed4(finalColor,_Tint.w);
            }
            ENDCG
        }
    } 
}
