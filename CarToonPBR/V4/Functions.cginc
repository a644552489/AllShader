#ifndef __FUNCTIONS_CGINC__
#define __FUNCTIONS_CGINC__

inline float3 GetFixedLightDirection(float4x4 transform)
{
	return mul(float4(0.051, 0.7, 0.71, 0.0), transform).xyz;
}

inline void GetPositionWSAndNormal(Varyings input, inout float3 positionWS, inout float3 normalWS)
{
#if USING_NORMAL_MAP
	positionWS = float3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);

	float3 normalTS = UnpackNormal(tex2D(_BumpMap, input.texcoord));
	normalWS = normalize(mul(normalTS, float3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz)));
#else
	positionWS = input.positionWS;
	normalWS = normalize(input.normalWS.xyz);
#endif
}

/////////////////////////////////////////////////////////////////////////
// ±ßÔµ¹â
half3 GetRimColor(half3 color, half NoV, half intensity, half rimPow)
{
	half rim = 1 - saturate(abs(NoV));
	rim = pow(rim, 1 / rimPow * 5) * intensity;
	return rim * color;
}

#endif
