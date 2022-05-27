

#define MAX_VISIBLE_LIGHTS 4
#define HALF_MIN 5.96046448e-08

#define HALF_MIN_SQRT 0.0078125 

int _ADDITIONALLIGHTS;


float4 _AdditionalLightsPosition[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsColor[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsAttenuation[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsSpotDir[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsOcclusionProbes[MAX_VISIBLE_LIGHTS];


float DistanceAttenuation(float distanceSqr, half2 distanceAttenuation)
{
	// We use a shared distance attenuation for additional directional and puctual lights
	// for directional lights attenuation will be 1
	float lightAtten = rcp(distanceSqr);

	//#if SHADER_HINT_NICE_QUALITY
		// Use the smoothing factor also used in the Unity lightmapper.
	half factor = distanceSqr * distanceAttenuation.x;
	half smoothFactor = saturate(1.0h - factor * factor);
	smoothFactor = smoothFactor * smoothFactor;
	//#else
		// We need to smoothly fade attenuation to light range. We start fading linearly at 80% of light range
		// Therefore:
		// fadeDistance = (0.8 * 0.8 * lightRangeSq)
		// smoothFactor = (lightRangeSqr - distanceSqr) / (lightRangeSqr - fadeDistance)
		// We can rewrite that to fit a MAD by doing
		// distanceSqr * (1.0 / (fadeDistanceSqr - lightRangeSqr)) + (-lightRangeSqr / (fadeDistanceSqr - lightRangeSqr)
		// distanceSqr *        distanceAttenuation.y            +             distanceAttenuation.z
	 //   half smoothFactor = saturate(distanceSqr * distanceAttenuation.x + distanceAttenuation.y);
	//#endif

	return lightAtten * smoothFactor;
}

half AngleAttenuation(half3 spotDirection, half3 lightDirection, half2 spotAttenuation)
{
	// Spot Attenuation with a linear falloff can be defined as
	// (SdotL - cosOuterAngle) / (cosInnerAngle - cosOuterAngle)
	// This can be rewritten as
	// invAngleRange = 1.0 / (cosInnerAngle - cosOuterAngle)
	// SdotL * invAngleRange + (-cosOuterAngle * invAngleRange)
	// SdotL * spotAttenuation.x + spotAttenuation.y

	// If we precompute the terms in a MAD instruction
	half SdotL = dot(spotDirection, lightDirection);
	half atten = saturate(SdotL * spotAttenuation.x + spotAttenuation.y);
	return atten * atten;
}




void GetAdditionalPerObjectLight(int index, float3 posWS, out half3 direction, out half4 distanceAttenuation)
{
	half4 occlusionProbeChannels = _AdditionalLightsOcclusionProbes[index];

	float4 lightPositionWS = _AdditionalLightsPosition[index];

	half4 distanceAndSpotAttenuation = _AdditionalLightsAttenuation[index];
	half4 spotDirection = _AdditionalLightsSpotDir[index];

	float3 lightVector = lightPositionWS.xyz - posWS * lightPositionWS.w;
	float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);

	half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));
	half attenuation = DistanceAttenuation(distanceSqr, distanceAndSpotAttenuation.xy) * AngleAttenuation(spotDirection.xyz, lightDirection, distanceAndSpotAttenuation.zw);;



	direction = lightDirection;
	distanceAttenuation = attenuation;

}

half DirectBRDFSpecularx_P(float roughness, float roughness2MinusOne, float roughness2, float normalizationTerm, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
	float3 halfDir = normalize(float3(lightDirectionWS)+float3(viewDirectionWS));

	float NoH = saturate(dot(normalWS, halfDir));
	half LoH = saturate(dot(lightDirectionWS, halfDir));

	// GGX Distribution multiplied by combined approximation of Visibility and Fresnel
	// BRDFspec = (D * V * F) / 4.0
	// D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
	// V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
	// See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
	// https://community.arm.com/events/1155

	// Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
	// We further optimize a few light invariant terms
	// brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
	float d = NoH * NoH * roughness2MinusOne + 1.00001f;

	half LoH2 = LoH * LoH;
	normalizationTerm = roughness * 4.0h + 2.0;
	half specularTerm = roughness2 / ((d * d) * max(0.1h, LoH2) * normalizationTerm);

	// On platforms where half actually means something, the denominator has a risk of overflow
	// clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
	// sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
	specularTerm = specularTerm - HALF_MIN;
	specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif
	float nol = dot(lightDirectionWS, normalWS) * 0.5 + 0.5;
	return specularTerm * nol;
}

half PerceptualRoughnessToRoughness_P(half roughness)
{
	return roughness * roughness;
}

half3 computeGGX_P(

	half3 LDir,
	half3 LColor,
	half3 V,
	half3 N,
	half3 Lshadow,

	half3 specular,
	half roughness,

	half3 diffuse
)
{
	half3 brdf = diffuse;
	//todo  ggx input fixed and light color add or remove
	// #if defined (GGX_OPENGL)
	// GGX= RefectionGGXLightOpenGL(NoLLambertan,NoV,NoH,VoH,roughness,specular);
	// #elif defined(GGX_BABY)
	// GGX = computeSpecularLighting(NoLLambertan,NoV,NoH,VoH,roughness,specularEnvironmentR0,specularEnvironmentR90,AARoughnessFactors,LColor);
	// #elif defined(GGX_TB)             
	// GGX =  ReflectionGGXLight(LDir,LColor,1-roughness,V,N,Lshadow,metallic,specular);
 //    #elif defined(GGX_OP3)
 //
 //   GGX = LightingFuncGGX_OPT3(N, V, LDir roughness, specular);
 //
 //
	// #else//u3d ggx

	half x = max(PerceptualRoughnessToRoughness_P(roughness), HALF_MIN_SQRT);


	brdf += specular * DirectBRDFSpecularx_P(max(x * x, HALF_MIN), x * x - 1, x * x, 1, N, LDir, V).xxxx;
	//	#endif                
	brdf *= LColor * Lshadow;
	return brdf;
}
#define kDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)

half OneMinusReflectivityMetallic(half metallic)
{
	// We'll need oneMinusReflectivity, so
	//   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
	// store (1-dielectricSpec) in kDielectricSpec.a, then
	//   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
	//                  = alpha - metallic * alpha
	half oneMinusDielectricSpec = kDielectricSpec.a;
	return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}





half3 GeratorPointLight(float3 posWorld ,float2 uv ,float3 TangentNormal ,float3 surfaceAlbedo ,
	float metallic , float3 viewDir , float3 specular, float roughness )
{

	                half3 GGX_P =0;
	             
	                [unroll(4)]
	                for(int j = 0 ; j <_ADDITIONALLIGHTS ; j++)
	                {
	                    half3 dir=0;
	                    half4 atten=0;
	                    half AdditionNoL = 0;
	                    half tempLambert = 0;
	                       GetAdditionalPerObjectLight(j, posWorld, dir, atten);
	                        
	#if defined(_USINGSKIN_ON)
	                       AdditionNoL=    SkinRenderBlock(uv, TangentNormal, dir, _AdditionalLightsColor[j], atten, tempLambert);
	#else
	                       AdditionNoL = dot(TangentNormal, dir) * 0.5 + 0.5;
	#endif
	                       float3 diffuse = surfaceAlbedo * OneMinusReflectivityMetallic(metallic) * AdditionNoL;
	                      
	
	                       
	
	                        GGX_P +=  computeGGX_P( dir, _AdditionalLightsColor[j],viewDir,TangentNormal,
	                            atten,specular,roughness , diffuse);
	                
	                }

					return GGX_P;
}



