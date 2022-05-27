#ifndef TRT
    #define TRT







    float FilmSlope;
    float FilmToe;
    float FilmShoulder;
    float FilmBlackClip;
    float FilmWhiteClip;
    
    #define PI 3.1415926
    float4 reflectionSampler_HDR;

    #include "UnityCG.cginc"
    #include "AutoLight.cginc"
    #include "Lighting.cginc"





    #include "Include/Ro_ASE_Function/Ro_Ace.hlsl"
    #include "Include/Ro_ASE_Function/Ro_EnvimentLight.hlsl"
    #include "Include/Ro_ToolBag_Function/PointLight.hlsl"
    #include "Include/Ro_ASE_Function/Ro_ReflectionLighting.cginc"
    #include "Include/Ro_ASE_Function/lchsh9.cginc"

    DEFINE_SH9(g_sph)
    
    float3 computeEnvironmentIrradiance(float3 normal) {

        GetSH9(g_sph, normal, c);
        //������Ь
        //CMP_SH9_ORDER2(normal,g_sph,c) 
        //CMP_SH9_ORDER2(normalW ,g_sph,c);
        return c;   
    }


    struct appdata
    {
        float4 vertex : POSITION;
        float4 uv : TEXCOORD0;
        float4 in_TEXCOORD1 : TEXCOORD1;
        float3 normal:NORMAL;
        float4 tangent :TANGENT;
        float4 color:COLOR0;
    };

    struct v2f
    {

        float4 pos : SV_POSITION;
        float4 uv : TEXCOORD0;
        float4 posWS:TEXCOORD1;
        float4  color:TEXCOORD2;
        float3 tangentWS:TEXCOORD3;
        float3 bitangentWS:TEXCOORD4;
        float3 normalWS:TEXCOORD5;
        float3 vertexSH :TEXCOORD8;   
        float vs_TEXCOORD10 :TEXCOORD10;    
        float4 vs_TEXCOORD14 :TEXCOORD14; 
        SHADOW_COORDS(6)
    };

    sampler2D _MainTex;
    float4 _MainTex_ST,_NormalTex_ST;
    sampler2D _NormalTex;
    half _NormalStrength;





    float4 _TintColor;
    float4 lobbyFogColor;
    float4 _SpecCube0_HDR;
    float _SpecCubePower;

    samplerCUBE  reflectionSampler;
    sampler2D _MLut;
    sampler2D _NLutAniso;

    
    
    float _Specular;

    float _ColorIntensity;
    float _OpacityMaskClipValue;
    float _TextureLodBias;

    float _Shadow;
    float _RoughnessOffset_R;
    float _RoughnessOffset_TT;
    float _RoughnessOffset_TRT;
    float _PointLightFactor;
    float _HighlightEnhance;
    float4 _RColor;
    float4 _TTColor;
    float4 _TRTColor;
    float _Roughness;
    float _ShiftTangentScale;
    float _ShiftTangentOffset;
    float _RimLight;
    float _RimLightIntensity;
    float4 _RimLightColor;
    float _LightLayerMask,_Cutoff;

    float _ConvertColorSpace;

    
    //方向性溶解
    float _ChangeAmount;
    float _EdgeWidth, _EdgeColorIntensity;
    float _Spread, _Softness;
    float _Invertmask;
    sampler2D _Noise;
    sampler2D _Ramp;
    float _Noisescale;
    float _Worldcoordinates;
    float3 _Noisespeed;
    float _Wave1frequency;
    float _Wave1offset;
    float _Wave2Frequency;
    float _Wave2offset;
    float _Wave1amplitude;
    float _Wave2amplitude;
    float _Tintinsidecolor;
    float4 _Fillcolor;



    float4 _SkyEnvimentColor;

    float3 toGammaSpace(float3 color) 
    {
        return pow(color, (0.454545));
    }
    float3 applyImageProcessing(float3 result)
    {
        result.rgb = toGammaSpace(result.rgb);
        result.rgb = saturate(result.rgb);
        return result;
    }
 
    // 重映射函数
    float remap(float x, float oldmin, float oldMax, float newMin, float newMax)
    {
        return (x - oldmin) / (oldMax - oldmin) * (newMax - newMin) + newMin;
    }


    //方向溶解函数
    float4 VerticalDissolve(float3 worldPos,inout float4 col, float ChangeAmount, float Spread, sampler2D Noise, float Noisescale, float3 Noisespeed, float Wave1amplitude, float Wave1frequency, float Wave1offset, float Wave2Frequency, float Wave2offset, float Wave2amplitude,
    float Softness, float EdgeWidth, sampler2D Ramp, float EdgeColorIntensity, float4 Tintinsidecolor, float4 Fillcolor, float _Cutoff )
    {
        float3 rootPos = mul(unity_ObjectToWorld, float4(-1, 0, 0, 1));

        float gradient = distance(worldPos, rootPos) / 1.8 ;

        float remapData = remap(ChangeAmount, 0, 1.0, -Spread, 1.0);
        gradient = gradient - remapData;
        gradient /= Spread;
 

        float4 noise = tex2D(Noise, (Noisescale * (worldPos + (Noisespeed * _Time.y))).xy);
        noise = ((Wave1amplitude * sin((noise + ((worldPos.x) * Wave1frequency + Wave1offset)))) + worldPos.y + (sin((((worldPos.z) * Wave2Frequency + Wave2offset) + noise)) * Wave2amplitude));


        gradient = gradient * 2 - noise;
        float dis = saturate(1 - distance(Softness, gradient) / EdgeWidth);

        float2 rampUV = float2(1 - dis, 0.5);
        float4 edgeCol = tex2D(Ramp, rampUV);
        float  alpha = smoothstep(Softness, 0.5, gradient) ;
      
        fixed4 edgeColor = edgeCol * EdgeColorIntensity;
        float3 emission = lerp(0, edgeColor + Tintinsidecolor * Fillcolor, dis).rgb;
        col.a = alpha * col.a;

    //    clip(col.a - _Cutoff);

   

        float4 EmissionFinal = float4(emission, col.a);
        return EmissionFinal;
    }
    v2f vert (appdata v)
    {

        
        v2f o = (v2f)0;

        o.pos =UnityObjectToClipPos(v.vertex);

        float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

        o.posWS.xyz = worldPos.xyz;
        
        o.color = v.color;
        o.uv.xy = TRANSFORM_TEX(v.uv , _MainTex);

        
        fixed3  worldTangent =normalize( UnityObjectToWorldDir(v.tangent.xyz));
        o.tangentWS = worldTangent;



        float3 worldNormal =normalize( UnityObjectToWorldNormal(v.normal));

        


        float sign = v.tangent.w * unity_WorldTransformParams.w;
        o.bitangentWS =normalize( cross(worldNormal ,  worldTangent )  * sign);
        
        
        
        
        o.normalWS = worldNormal;
        TRANSFER_SHADOW(o);
        return o;
    }


    
    fixed4 frag (v2f i , float facing:VFACE) : SV_Target
    {
        UNITY_LIGHT_ATTENUATION(atten , i ,i.posWS );
        float4 col;
        float3 L  = normalize(UnityWorldSpaceLightDir(i.posWS)) ;
        

        half2 uv = i.uv.xy;
        uv = uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
        col = tex2D(_MainTex, uv);
        
         float4 EM = VerticalDissolve(i.posWS, col, _ChangeAmount, _Spread, _Noise, _Noisescale, _Noisespeed, _Wave1amplitude, _Wave1frequency, _Wave1offset, _Wave2Frequency, _Wave2offset, _Wave2amplitude, _Softness, _EdgeWidth, _Ramp, _EdgeColorIntensity, _Tintinsidecolor, _Fillcolor,_Cutoff  );


        float alpha = col.a;

        #if defined(CLIP)
            clip(alpha -_Cutoff);
        #else 
            clip(_Cutoff - alpha);
        #endif

        
        // half4 NormalTex = ( tex2D(_NormalTex, uv) ) ;
        // float TangentShiftMap  = NormalTex.z - 0.5;
        // float OccuulsionMap  = NormalTex.w;


        // float3 TangentNormal = UnpackNormal( NormalTex);
        // TangentNormal.xy*= _NormalStrength;

        // ///TBN
        // float faceSign = (facing >= 0 ? 1 : -1);
        
        // float3x3 tbn = float3x3(i.tangentWS.xyz, i.bitangentWS.xyz , i.normalWS.xyz * faceSign );
        // float3 Vnormal = tbn[2];

        // TangentNormal =normalize( mul(TangentNormal  , tbn));   

        // half3 Normal_ = TangentNormal;
        // ///shiftIntensity
        // half3 ShiftValue =   (TangentShiftMap * _ShiftTangentScale +_ShiftTangentOffset);
        // //TangentNormal = normalize ( ShiftValue * TangentNormal.xyz + i.bitangentWS.xyz);	
        // float3 N = normalize(TangentNormal);
        float3 NormalTex =UnpackNormal (tex2D(_NormalTex , uv * _NormalTex_ST.xy + _NormalTex_ST.zw) );
        NormalTex.xy *= _NormalStrength ;
         float3x3 tbn = float3x3(i.tangentWS, i.bitangentWS , i.normalWS  );

        float3 Vnormal = i.normalWS;
          NormalTex = normalize(mul(NormalTex ,tbn));

        float shift =( NormalTex.y - 0.5)* _ShiftTangentScale  + _ShiftTangentOffset  ;
        float3 Tangent = normalize(shift *NormalTex + i.bitangentWS );
       float3 N = Tangent;


            

        ///finalNormal


        half3 V = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);

        float NoV =  dot(V ,N);


        half F = frac( saturate(1- dot(V , i.normalWS.xyz))) ;
        F =exp2( log2(saturate(F)) * _RimLight);


        //final rim
        float3  RimColor = F * _RimLightColor* _RimLightIntensity ;
        half vertexColor  =  saturate( i.color.w * i.color.w);
        RimColor = vertexColor * RimColor;
        RimColor = RimColor *( alpha );



        col.xyz = col.xyz * _TintColor.xyz * alpha * _ColorIntensity;



        half roughness = saturate(_Roughness * _Roughness);

        

        float3 IBL;
        {
            IBL = computeEnvironmentIrradiance(N);
            IBL =IBL * _SkyEnvimentColor *col.rgb;                    
        }


        half3 R = reflect(-V , N);

        //SPl
        half4 SPL;
        {
            sampleReflectionTexture(roughness ,reflectionSampler ,R , 0 ,SPL ) ; 
            
            SPL = SPL *_SkyEnvimentColor  *_SpecCubePower ;
            
        } 






        float NoL = dot(L ,N);
        half halflambert =NoL *0.5+0.5 ;

        
        half3  HaL = normalize( -NoL *  N + L);
        half3  HaV =normalize( -NoV * N + V);

       float  HoL = dot(HaV, HaL);
       float  HoV = dot(HaV, HaV);
        float HalX = dot(HaL , HaL);

        float LutNaL =   HoL *rsqrt( max(HoV * HalX  , 0.01)) *0.5+0.5 ;
   




        
        half2 M_uv = half2(NoL , NoV ) * 0.5+0.5;

        half3 Mlut = tex2D(_MLut, M_uv.xy).xyz ;


        float3 offset = float3(_RoughnessOffset_R, _RoughnessOffset_TT, _RoughnessOffset_TRT) + float3(1.0, 1.0, 1.0);
        Mlut   =offset * Mlut.xyz + (-float3(_RoughnessOffset_R, _RoughnessOffset_TT, _RoughnessOffset_TRT));
        // #ifdef UNITY_ADRENO_ES3

        Mlut.xyz = saturate(Mlut.xyz) ;
        






    

half2 N_uv = float2(LutNaL, abs(NoL));
half3 Nlut = tex2D(_NLutAniso , N_uv) ;




 
        atten = lerp(_Shadow , 1 , atten);

        float3 finalAmbient = GradientSkyColor(Vnormal ) * col.rgb;

        half3 MN_lut = Nlut * Mlut.xyz   * _HighlightEnhance ;

        half3 Rchannel = MN_lut.x * _RColor.xyz;
        half3 G = MN_lut.y * _TTColor.xyz;
        half3 B = MN_lut.z * _TRTColor.xyz;
        half lambertant = max(NoL * 0.5+0.5,0);

     
        MN_lut = (Rchannel+G+B) +(col.rgb *lambertant  ) ;

        MN_lut =MN_lut  * _LightColor0.rgb * atten;
         


        half3 PointLight =   GeratorPointLight(i.posWS.xyz,uv, N, col.rgb, 0, V, 0, _Roughness);
        
      

        half3 finalColor = SPL.xyz  + IBL + (MN_lut) + RimColor + finalAmbient +PointLight;

        finalColor += EM;
        finalColor = ACESFilm(finalColor);

#ifdef USE_TEX_ALPHA
		return half4(finalColor, alpha);
#else
		return half4(finalColor, 1);
#endif
    }
#endif