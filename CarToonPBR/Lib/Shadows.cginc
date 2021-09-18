#ifndef __SHADOWS_CGINC__
#define __SHADOWS_CGINC__

uniform float4x4 _G_ShadowWorldToView;
uniform float4x4 _G_ShadowWorldToProj;
uniform float _G_ShadowProjParams;

uniform float _G_ShadowNormalBias;
uniform sampler2D _G_ShadowTexture;

float CalcDepth(float3 positionWS)
{
	// View空间是右手坐标系，Z是负数，因此符号取反
	//return -(mul(_G_ShadowWorldToView, float4(positionWS, 1.0)).z * _G_ShadowProjParams);
	float4 positionCS =  mul(_G_ShadowWorldToProj, float4(positionWS, 1.0));
	return positionCS.z / positionCS.w;
}

float4 GetShadowCoord(float3 positionWS)
{
	float4 result = float4(0.0, 0.0, 0.0, 0.0);
#ifdef USE_ACTOR_SHADOW_TEX
	result = mul(_G_ShadowWorldToProj, float4(positionWS, 1.0));
#endif
	return result;
}

// 采样阴影图，返回像素是否在阴影中
half SampleShadowMap(float3 positionWS, float4 shadowCoord)
{
	half result = 0.0;

#ifdef USE_ACTOR_SHADOW_TEX
	shadowCoord.xyz = shadowCoord.xyz / shadowCoord.w;
	if (shadowCoord.x <= 1.0 && shadowCoord.x >= -1.0 && shadowCoord.y <= 1.0 && shadowCoord.y >= -1.0)
	{
		float2 uv = 0.5 + 0.5 * shadowCoord.xy;
		float depth = tex2D(_G_ShadowTexture, uv);

		// 备注：Android平台会将_G_ShadowTexture的值设置成[0, 1]区域，因此shadowCoord.z也要设为[0, 1]
#if defined(SHADER_API_MOBILE)
		shadowCoord.z = 0.5 + 0.5 * shadowCoord.z;
#endif
		
#if UNITY_REVERSED_Z
		result = step(shadowCoord.z + _G_ShadowNormalBias, depth);
#else
		result = step(depth, shadowCoord.z + _G_ShadowNormalBias);
#endif
	}
#endif

	return result;
}

#endif
