#ifndef __ACTOR_PASS_CGINC__
#define __ACTOR_PASS_CGINC__

#include "ActorInput.cginc"

//////////////////////////////////////////////
// 材质属性和贴图
uniform half3 _SkinDyeColor;

uniform half3 _MetalSpecColor;
uniform half3 _SkinShadowMultColor;

uniform half3 _FirstShadowMultColor;
uniform half _Mix_BaseTexture;
uniform half _Mix_KageTexture;

uniform half3 _SecondShadowColor;
uniform half _Mix_BaseTexture2;
uniform half _Mix_KageTexture2;

uniform sampler2D _ShadowMask;
uniform half _UseShadowMask;

uniform half _EmissionIntensity;

uniform half4 _BloomVector;

UNITY_DECLARE_TEXCUBE(_EnvironmentMap);

//////////////////////////////////////////////

// 功能函数
#include "Functions.cginc"

// 根据粗糙度获取Cubmap的mip级别
half GetPerceptualRoughnessToMipmapLevel(half perceptualRoughness, uint mipMapCount)
{
	perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
	return perceptualRoughness * mipMapCount;
}

// 环境反射（URP函数）
half3 GlossyEnvironmentReflection(float3 reflectVector, half perceptualRoughness)
{
	half4 encodedIrradiance = 0;
#ifndef _FACE
	half mip = GetPerceptualRoughnessToMipmapLevel(perceptualRoughness, 8);
	encodedIrradiance = UNITY_SAMPLE_TEXCUBE_LOD(_EnvironmentMap, reflectVector, mip);
#endif
	return encodedIrradiance ;
}

half3 GetKageColor(half3 color, half kageMask, half NoL, half NoL1, half attenuation, half useSkinColor)
{
	half3 albedo = color * (1.0 + color) * 0.5;
#ifdef _FACE
	half factor = (0.5 * NoL - 0.5) - attenuation;
	half3 realShadowColor = albedo * _FirstShadowMultColor;
	half3 result = lerp(color, realShadowColor, saturate(ceil(-factor - kageMask)));
#else
	kageMask = max(1.2 * kageMask - 0.2, 0);
	half3 shadowColor = albedo * lerp(_SkinShadowMultColor, _FirstShadowMultColor, useSkinColor);
	half3 secondShadowColor = lerp(_SkinShadowMultColor.rgb, _SecondShadowColor, useSkinColor);

	// 第一层阴影
	half factor = (0.5 * NoL1 + 0.5) - attenuation;
	half shadowMask = (_Mix_KageTexture - factor) / ((1 - _Mix_KageTexture) - _Mix_BaseTexture) * kageMask;
	color = lerp(color, shadowColor, saturate(1 + shadowMask));

	// 第二层阴影
	factor = (0.5 * NoL + 0.5) - attenuation;
	half kageLerpColor = (_Mix_KageTexture2 - factor) / ((1 - _Mix_KageTexture2) - _Mix_BaseTexture2) * kageMask;
	kageLerpColor = saturate(1 + kageLerpColor);
	half3 kageMaskColor = tex2D(_ShadowMask, float2(1 - kageLerpColor, 0.25)).rgb;
	shadowColor = color * lerp(secondShadowColor, kageMaskColor, (1 - kageLerpColor) * _UseShadowMask);
	half3 result = lerp(color, shadowColor, kageLerpColor);
#endif

	return result;
}

// 自发光
half3 GetEmissionColor(float2 uv, half flowMask, half emissiveMask)
{
	half emissiveColor = half3(0, 0, 0);

	// 流动自发光
#ifdef _Emissve_Float_ON
	float2 moveTime = _Time.xy * float2(_EmissiveOffsetX, _EmissiveOffsetY);
	half3 texColor = tex2D(_EmissiveTex, uv + moveTime).rgb;
	emissiveColor = flowMask * texColor * _EmissiveColor * _EmissiveStrength;
#endif

	// 自发光
#ifdef _Emissve_SIN_ON
	half emissiveAlpha = sin(_SinEmissiveFrequent * _Time.y) * 0.5 + 0.5;
	emissiveColor += emissiveMask * emissiveAlpha * _SinEmissiveColor * _SinEmissiveStrength;
#endif

	return emissiveColor;
}

//////////////////////////////////////////////
// 片元函数
half4 frag(Varyings input) : SV_Target
{
	float3 positionWS, normalWS;
	GetPositionWSAndNormal(input, positionWS, normalWS);
	float3 viewDirectionWS = normalize(_WorldSpaceCameraPos.xyz - positionWS);
	LightData lightData = GetDefaultLightData(positionWS);
	 
	half4 mainColor = tex2D(_MainTex, input.texcoord.xy);
	half4 lightMaskColor = tex2D(_LightMaskTex, input.texcoord.xy);

#if USING_SHADOWMAP
	half attenuation = SampleShadowMap(positionWS, input.shadowCoord);
#else
	half attenuation =1- SHADOW_ATTENUATION(input);
#endif

	// 副光
	float4x4 rotateMatrix = {
		UNITY_MATRIX_V[0][0],0,UNITY_MATRIX_V[0][2],0,
		0, 1, 0,									0,
		UNITY_MATRIX_V[2][0],0,UNITY_MATRIX_V[2][2],0,
		0, 0, 0,									1
	};
	float3 secondLightDir = GetFixedLightDirection(rotateMatrix);

#ifndef _FACE
	mainColor.rgb = lerp(mainColor.rgb * _SkinDyeColor, mainColor.rgb, input.color.r);
#endif

	half3 color = mainColor.rgb;

	// 漫反射
	float NoL =saturate(dot(normalWS, lightData.direction));
	half3 diffuse = lightData.color * ceil(NoL) ;
	half3 diffuseAlbedo = mainColor.rgb / _BloomVector.x;
	
	#ifdef _FACE
		color += 0.2 * diffuseAlbedo * diffuse;
	#else
		#if _USESRSMAP_ON
			half3 lightdir = normalize(half3(1,1,1));
			half nl =saturate( dot(normalWS , lightdir));
			color = (color * NoL  * _LightColor0.rgb  +0.5 *color + color * nl * _Light1Color.rgb  ) ;
		
		#else
			color += min(0.3, diffuseAlbedo * diffuse * lerp(0.2, 1, input.color.r));
		#endif
	#endif
		

	float3 R = reflect(-viewDirectionWS, normalWS);
#if _USESRSMAP_ON
	//SRS图
	half specCol =   tex2D(_SpecMap , input.texcoord.xy).r;
	half3 refCol = _Ref *  tex2D(_RefMap , input.texcoord.xy).r;
	half smoothness = _Smoothness * tex2D(_SmoothnessMap , input.texcoord.xy).r;
	
	#if _USEBLENDSRSMAP_ON
		specCol = tex2D(_SRSMap , input.texcoord.xy).r;
		refCol = _Ref * tex2D(_SRSMap , input.texcoord.xy).g;
		smoothness = _Smoothness * tex2D(_SRSMap , input.texcoord.xy).b;

	#endif
	half rough = 1-smoothness;
	half reflectivity = max(max(refCol.r , refCol.g) , refCol.b);
	half oneMinusReflectivity = 1- reflectivity;
	color *= oneMinusReflectivity;
	
	

	// 环境反射
	half nv = saturate(dot(normalWS , viewDirectionWS));

	half3 refDir = reflect( viewDirectionWS , normalWS);
	half2 rlPow4AndFresnelTerm = Pow4(half2(dot(refDir, lightData.direction), 1 - nv));
	half rlPow4 = rlPow4AndFresnelTerm.x;
	half fresnelTerm = rlPow4AndFresnelTerm.y;
	half grazingTerm = saturate(smoothness + reflectivity);

	half3 refColor = GlossyEnvironmentReflection(R, 1 - smoothness) ; //lightMaskColor.a);
	//refColor *= 1.5 * lightMaskColor.b * mainColor.rgb * _BloomVector.w;
	half3 gi =	refColor * lerp(refCol , grazingTerm , fresnelTerm);
	color +=gi;

#else
	// 环境反射

	half3 refColor = GlossyEnvironmentReflection(R, 1 - lightMaskColor.a);
	refColor *= 1.5 * lightMaskColor.b * mainColor.rgb * _BloomVector.w;
	color += refColor;
	
#endif

	half kageMask = lightMaskColor.y;
#ifdef _FACE
	// 左右翻转
	half LR = cross(normalWS, lightData.direction).y;
	half2 flipUV = float2(1 - input.texcoord.x, input.texcoord.y);
	half4 lightMapColorR = tex2D(_LightMaskTex, flipUV.xy);
	kageMask = LR > 0 ? kageMask : lightMapColorR.y;
#endif
	
   //卡通阴影
	half NoL1 = dot(normalWS, secondLightDir);
	color = GetKageColor(color, kageMask, NoL, NoL1, attenuation, input.color.r);

	
	// 高光
	float3 h = normalize(secondLightDir + viewDirectionWS);
	float nh = max(0, dot(normalWS, h));
	half lh = saturate(dot(secondLightDir, nh));
	half perceptualRoughness = 0;

#if _USESRSMAP_ON
	 perceptualRoughness =( 1-smoothness);// lightMaskColor.a);
#else
	 perceptualRoughness = (1 - lightMaskColor.a);
#endif

	half roughness = perceptualRoughness * perceptualRoughness;
	half a = roughness;
	half a2 = a * a;
	half d = nh * nh * (a2 - 1.h) + 1.00001h;
	half specularTerm = a / (max(0.32h, lh) * (3.5h + roughness) * d) - 1e-3h;

#if _USESRSMAP_ON
	half LUT_RANGE = 16.0;
	half specular = tex2D(unity_NHxRoughness, half2(rlPow4, rough)).UNITY_ATTEN_CHANNEL * LUT_RANGE;
	
	half3 specColor = NoL *  specular * specCol * _MetalSpecColor;
		
#else
		half3 specColor = specularTerm * _MetalSpecColor * lightMaskColor.b * NoL;
#endif
	color +=  specColor ;

	
	// 边缘光
#if USING_RIM
//	fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
//	float NoV = dot(viewDirectionWS, normalWS);
//#ifdef _FACE
//	half rim = saturate(1.0 - NoV - _RimSideWidth + lightMaskColor.r) * dot(normalWS, normalize(input.rimLightDir));
//#else
//	half rim = saturate(1.0 - NoV - _RimSideWidth) * dot(normalWS, normalize(input.rimLightDir));
//#endif
//	rim = pow(max(0.001, rim * saturate(NoL1)), _RimPower);
//	half3 rimColor = min(2.5, ambient * ambient * (_RimColor + mainColor.rgb)) * saturate(rim - 1e-3h);
//	color += rimColor;
	float NoV = dot(viewDirectionWS, normalWS);
	color += GetRimColor(_RimColor, NoV, _RimStrength, _RimPower);
#endif

#ifdef VERTEXLIGHT_ON
	color += color * input.vertexLighting;
#endif

	// 自发光
#ifndef _FACE
	color.rgb += pow(mainColor.rgb, _BloomVector.y)* lightMaskColor.r * _EmissionIntensity * 3.0;

	half4 emissiveMask = tex2D(_EmissiveMaskTex, input.texcoord.xy);
	color.rgb += GetEmissionColor(input.texcoord.zw, emissiveMask.g, emissiveMask.a);
#endif

#if USING_ALPHA_CUTOFF
	clip(mainColor.a - _Cutoff);
#endif
  

	return half4(color, _BodyAlPah * mainColor.a) * _MainColor;
}

#endif
