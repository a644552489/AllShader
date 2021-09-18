#ifndef __ACTOR_HAIR_PASS_CGINC__
#define __ACTOR_HAIR_PASS_CGINC__

#include "ActorInput.cginc"

//////////////////////////////////////////////
// 材质属性和贴图
uniform half4 _DyeColor;
uniform half _DyeIntensity;

uniform half3 _MaskDyeColor;
uniform half _MaskDyeIntensity;
uniform half _MaskDyeColorIntensity;

uniform half3 _FirstShadowMultColor;
uniform half _Mix_BaseTexture;
uniform half _Mix_KageTexture;

uniform half3 _SecondShadowColor;
uniform half _Mix_BaseTexture2;
uniform half _Mix_KageTexture2;

uniform sampler2D _ShadowMask;
uniform half _UseShadowMask;

uniform half _SpecularMultiplier;
uniform half3 _SpecularColor;
uniform half _SpecularMultiplier2;
uniform half3 _SpecularColor2;

uniform half _PrimaryShift;
uniform half _SecondaryShift;
uniform half4 _SpecularVector;

//////////////////////////////////////////////
// 功能函数
#include "Functions.cginc"

inline float3 ShiftTangent(float3 T, float3 N, float shift)
{
	float3 shiftedT = T + shift * N;
	return normalize(shiftedT);
}

float StrandSpecular(float3 T, float3 V, half3 L, half exponent, half4 specVec)
{
	float3 H = normalize(L + V);
	float dotTH = dot(T, H);
	float sinTH = sqrt(1 - dotTH * dotTH);
	float dirAtten = smoothstep(-1, 0, dotTH);
	return dirAtten * saturate(min(specVec.y, pow(sinTH, exponent) * specVec.x) - (1 - specVec.z));
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
	float3 secondLightDir = GetFixedLightDirection(UNITY_MATRIX_V);
	half attenuation = 0;

	// 与染色混合
	half4 albedo = lerp(mainColor, _DyeColor * mainColor, _DyeIntensity);

	// 处理发梢颜色
#if USING_MASK_DYE
	half3 maskDyeColor = lerp(albedo.rgb, _MaskDyeColor.rgb, _MaskDyeIntensity);
	albedo.rgb = lerp(maskDyeColor, albedo.rgb, saturate(lightMaskColor.a * lightMaskColor.a / _MaskDyeColorIntensity));
#endif

	// 漫反射
	float NoL = dot(normalWS, lightData.direction);
	half3 diffuse = lightData.color *  max(0, ceil(NoL));
	half3 color = albedo + min(1, 0.2 * albedo * diffuse);

	// 阴影mask
	half kageMask = max(1.2 * lightMaskColor.r - 0.2, 0);

	// 第一层阴影
	half factor = (0.5 * dot(normalWS, secondLightDir) + 0.5) - attenuation;
	half3 shadowColor = albedo * _FirstShadowMultColor;
	half shadowMask = (_Mix_KageTexture - factor) / ((1 - _Mix_KageTexture) - _Mix_BaseTexture) * kageMask;
	shadowMask = saturate(1 + shadowMask);
	color = lerp(color, shadowColor, shadowMask);

	// 第二层阴影
	factor = (0.5 * NoL + 0.5) - attenuation;
	half kageLerpColor = (_Mix_KageTexture2 - factor) / ((1 - _Mix_KageTexture2) - _Mix_BaseTexture2) * kageMask;
	kageLerpColor = saturate(1 + kageLerpColor);
	half3 kageMaskColor = tex2D(_ShadowMask, float2(1 - kageLerpColor, 0.25)).rgb;
	shadowColor = color * lerp(_SecondShadowColor, kageMaskColor, ceil(1 - kageLerpColor) * _UseShadowMask);
	color = lerp(color, shadowColor, kageLerpColor);

	// 高光
	half shiftTex = lightMaskColor.g - 0.5;
	float3 t1 = ShiftTangent(input.bitangentWS, normalWS, _PrimaryShift + shiftTex);
	float3 t2 = ShiftTangent(input.bitangentWS, normalWS, _SecondaryShift);
	half3 spec = _SpecularColor * StrandSpecular(t1, viewDirectionWS, secondLightDir, _SpecularMultiplier, _SpecularVector);
	spec = spec + _SpecularColor2 * StrandSpecular(t2, viewDirectionWS, secondLightDir, _SpecularMultiplier2, _SpecularVector);
	half3 specColor = lerp(spec, 0, shadowMask);
#if USING_MASK_DYE
	specColor = lerp(albedo * specColor, specColor, lightMaskColor.a + 0.2);
#endif
	color = color + mainColor.rgb * specColor * clamp(NoL, 0.1, 1) * 0.3 * lightMaskColor.b;

	// 边缘光
#if USING_RIM
	float NoV = dot(viewDirectionWS, normalWS);
	//half rim = saturate(1.0 - NoV - _RimSideWidth) * dot(normalWS, normalize(input.rimLightDir));
	//rim = pow(max(0.001, rim), _RimPower);
	//half3 rimColor = _RimColor * saturate(rim - 1e-3h);
	//color += rimColor;
	color += GetRimColor(_RimColor, NoV, _RimStrength, _RimPower);
#endif

#ifdef VERTEXLIGHT_ON
	color += color * input.vertexLighting;
#endif

	return half4(color, _BodyAlPah * mainColor.a) * _MainColor;
}

#endif
