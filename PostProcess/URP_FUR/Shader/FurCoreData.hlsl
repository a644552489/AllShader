
struct Attributes
{
    float4 vertex    : POSITION;
    float2 uv        : TEXCOORD0;
    half2 lightmapUV : TEXCOORD1;
    float4 tangent   : TANGENT;
    float3 normal    : NORMAL;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 pos                   : SV_POSITION;
    float4 uv                            : TEXCOORD0;
    float4 posWorld                         : TEXCOORD1;
    float3 eyeVec                        : TEXCOORD2;
    float4 tangentToWorldAndPackedData[3]: TEXCOORD3;
    half4  ambientOrLightmapUV           : TEXCOORD6;
    float3 normalWS                      : TEXCOORD7;

    float4 lightmapUVOrVertexSH          : TEXCOORD9;
    float3 viewWS                        : TEXCOORD10;
    half4 fogFactorAndVertexLight        : TEXCOORD11;
    float4 screenPos                     : TEXCOORD12;
    UNITY_LIGHTING_COORDS(13,14)

    //TODO
    //     UNITY_SHADOW_COORDS(6)
    //     UNITY_FOG_COORDS(7)
    // #else
    //     UNITY_LIGHTING_COORDS(6,7)
    //     UNITY_FOG_COORDS(8)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

UNITY_INSTANCING_BUFFER_START(Props)
    UNITY_DEFINE_INSTANCED_PROP(float, FUR_OFFSET)
    UNITY_DEFINE_INSTANCED_PROP(float, _EdgeFade)

UNITY_INSTANCING_BUFFER_END(Props)

#include "UtilsInclude.hlsl"
// #define DIRLIGHTMAP_COMBINED


Varyings vert (Attributes v, half FUR_OFFSET =0)
{
    UNITY_SETUP_INSTANCE_ID(v);
    Varyings OUT;
    
    UNITY_INITIALIZE_OUTPUT(Varyings, OUT);
     UNITY_TRANSFER_INSTANCE_ID(v , OUT);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

     FUR_OFFSET = UNITY_ACCESS_INSTANCED_PROP(Props , FUR_OFFSET);
    
    //Transform vertexPos by normal
    //短绒毛
    half3 direction = lerp(v.normal, _Gravity * _GravityStrength + v.normal * (1 - _GravityStrength), FUR_OFFSET);
    //长毛
    // half3 direction = lerp(IN.normal, _Gravity * _GravityStrength + IN.normal, FUR_OFFSET);

 
    v.vertex.xyz += direction * _FurLength * FUR_OFFSET *0.001 ;

    OUT.posWorld = mul(unity_ObjectToWorld, v.vertex);
 
	float4 positionCS = UnityObjectToClipPos( v.vertex );

    OUT.screenPos = ComputeScreenPos(positionCS);
    
    OUT.pos =positionCS;
    OUT.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    OUT.viewWS = normalize( _WorldSpaceCameraPos - OUT.posWorld);
//    VertexNormalInputs normalInput = GetVertexNormalInputs( IN.normal, IN.tangent );
     half3 normalWS = UnityObjectToWorldNormal(v.normal);

    OUT.eyeVec = NormalizePerVertexNormal(OUT.posWorld.xyz -_WorldSpaceCameraPos);

  
    OUT.normalWS = normalWS;
    #ifdef _TANGENT_TO_WORLD
        float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
        float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWS, tangentWorld.xyz, tangentWorld.w);
        OUT.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
        OUT.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
        OUT.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
    #else
        OUT.tangentToWorldAndPackedData[0].xyz = 0;
        OUT.tangentToWorldAndPackedData[1].xyz = 0;
        OUT.tangentToWorldAndPackedData[2].xyz = normalWS;
    #endif




    OUT.ambientOrLightmapUV = VertexGIForward(v, OUT.posWorld, normalWS);
  // OUTPUT_LIGHTMAP_UV(IN.lightmapUV, unity_LightmapST, OUT.lightmapUVOrVertexSH.xy);
    OUTPUT_SH(normalWS, OUT.lightmapUVOrVertexSH.xyz);

 //   OUT.ambientOrLightmapUV = VertexGIForward(IN, OUT.posWorld, normalWS);
    //TODO Fog
    //TODO Shadow
    TRANSFER_VERTEX_TO_FRAGMENT(OUT);

    return OUT;
}

half4 frag (Varyings IN, half FUR_OFFSET = 0) : SV_Target
{

    //Data
    float3 Albedo = float3(0.5, 0.5, 0.5);
    float Metallic = 0;
    float3 Specular = 0.5;
    float Smoothness = 0.5;
    float Occlusion = 1;
    float3 Emission = 0;
    float Alpha = 1;
    float3 BakedGI = 0;

    InputData inputData;
	inputData.positionWS = IN.posWorld;
	inputData.viewDirectionWS = IN.viewWS;
//	inputData.shadowCoord = IN.shadowCoord;
//	inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
    inputData.normalWS = IN.normalWS;
    inputData.fogCoord = IN.fogFactorAndVertexLight.x;
	inputData.bakedGI = 0;
	#ifdef _GI_ON
	inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, IN.lightmapUVOrVertexSH.xyz, IN.normalWS );
	#endif
/*
    half4 color = UniversalFragmentPBR(
    inputData, 
    _Albedo, 
    _Metallic, 
    _Specular, 
    _Smoothness, 
    _Occlusion, 
    _Emission, 
    _Alpha);
*/
    #ifdef _REFRACTION_ASE
		float4 projScreenPos = ScreenPos / ScreenPos.w;
		float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
		projScreenPos.xy += refractionOffset.xy;
		float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos ) * RefractionColor;
		color.rgb = lerp( refraction, color.rgb, color.a );
		color.a = 1;
	#endif

	#ifdef ASE_FOG
		#ifdef TERRAIN_SPLAT_ADDPASS
			color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
		#else
			color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
		#endif
	#endif

    //
    //Dither
    //UnityApplyDitherCrossFade(IN.pos.xy);
    half facing = dot(-IN.eyeVec, IN.tangentToWorldAndPackedData[2].xyz);
    facing = saturate(ceil(facing)) * 2 - 1;

    FRAGMENT_SETUP(s)
#if defined(_ALPHACLIP_ON)
  clip( s.alpha - 0.1);
#endif
    UNITY_SETUP_INSTANCE_ID(IN);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

    Light mainLight = GetMainLight ();
    UNITY_LIGHT_ATTENUATION(atten,IN, IN.posWorld.xyz);
  

    half occlusion = CalOcclusion(IN.uv.xy);

    //  #ifdef _GI_ON
    //  inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, IN.lightmapUVOrVertexSH.xyz, IN.normalWS);
    //  #endif
    //PBR
    BRDFData brdfData;
    half3 albedo = 0.5;
    half3 specular = .5;
    half brdfAlpha = 1;
    InitializeBRDFData(albedo,0,specular,0.5, brdfAlpha, brdfData);
	#ifdef _RECEIVE_SHADOWS
    half lightAttenuation = atten;
	#else
	half lightAttenuation = 1;
	#endif
    half NdotL = saturate(dot(inputData.normalWS, mainLight.direction));
    half3 radiance = mainLight.color * (lightAttenuation * NdotL);

    // half3 GIcolor = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
    // half3 BRDFColor = LightingPhysicallyBased(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS);
    //

    half4 c = FABRIC_BRDF_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, mainLight, inputData, lightAttenuation);


    //
    c.rgb += CalEmission(IN.uv.xy);

    FUR_OFFSET = UNITY_ACCESS_INSTANCED_PROP(Props, FUR_OFFSET);
   
 half  _EdgeFade = 0;
 _EdgeFade = UNITY_ACCESS_INSTANCED_PROP(Props, _EdgeFade);
  
    //UNITY_APPLY_FOG(i.fogCoord, c.rgb);
    // half alpha = tex2D(_LayerTex, TRANSFORM_TEX(IN.uv.xy, _LayerTex)).r;
     float2 uvoffset = tex2D(_FlowMap, IN.uv.xy).rg*2-1;
 

  
   // float3x3 tbn = float3x3(IN.tangentToWorldAndPackedData[0].xyz,IN.tangentToWorldAndPackedData[1].xyz,IN.tangentToWorldAndPackedData[2].xyz);
   // _flowMapNormal = mul(  _flowMapNormal , tbn);
        //  uvoffset *=5;
  //  float mask = tex2D(_Mask , IN.uv.xy).r;
    half alpha = tex2D(_LayerTex, TRANSFORM_TEX(IN.uv.xy, _LayerTex) + _UVOffset * uvoffset * FUR_OFFSET).r;
    // half alpha1 = tex2D(_LayerTex , IN.uv.xy* 3 +_UVOffset.xy *uvoffset *FUR_OFFSET).r;
    // alpha = lerp(alpha , alpha1, mask);
 
    alpha = step(lerp(_Cutoff, _CutoffEnd, FUR_OFFSET), alpha);
    alpha *= _Color.a;
    c.a = 1 - FUR_OFFSET * FUR_OFFSET;

    c.a += dot(-s.eyeVec , s.normalWorld) - _EdgeFade;


    c.a = max(0, c.a);
    c.a *= alpha;
 

	c = half4(c.rgb * lerp(lerp(_ShadowColor.rgb, 1, FUR_OFFSET), 1, _ShadowLerp), c.a);
    
    // float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
    // mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );

    // return half4(GIcolor+BRDFColor,1);
    // return half4(mainLight.color * mainLight.distanceAttenuation,1);
    // #ifdef MAIN_LIGHT_CALCULATE_SHADOWS
    // return 1;
    // #else 

    // #endif
    return c;
}
Varyings vert_LayerBase(Attributes IN)
{
    return vert(IN, 0);
}
Varyings vert_Layer(Attributes IN)
{
    return vert(IN, .0);
}
half4 frag_LayerBase(Varyings IN) : SV_Target
{
    return frag(IN, .0);
}
half4 frag_Layer(Varyings IN) : SV_Target
{
    return frag(IN, .0);
}

