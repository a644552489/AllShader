#ifndef __ROLE_SHADOW__
#define __ROLE_SHADOW__

#include "UnityCG.cginc"
#include "Dissolve.cginc"

// 角色平面投射阴影

// --------------------------------------------- 开关定义 ---------------------------------------------------

// _CUSTOM_HEIGHT_ON 

// --------------------------------------------- 结构体 ---------------------------------------------------

struct appdata
{
	float4 vertex : POSITION;
};

struct v2fShadow
{
	float4 vertex : SV_POSITION;
	fixed4 color : COLOR;
};


// --------------------------------------------- 属性部分 ---------------------------------------------------

half4 _LightDir;
fixed4 _ShadowCol;
half _ShadowFalloff;
#if _CUSTOM_HEIGHT_ON
	half _CustomHeight; // 自定义平面阴影高度
#endif

// --------------------------------------------- 相关函数 ---------------------------------------------------

float3 ShadowProjectPos(float4 vertDir)
{
	float3 shadowPos;

	float3 wPos = mul(unity_ObjectToWorld, vertDir).xyz;
	#if _ENABLE_WORLDLIGHT // 使用世界平行灯方向
		float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
	#else
		float3 lightDir = normalize(_LightDir.xyz);
	#endif

	#if _CUSTOM_HEIGHT_ON
		half height = _CustomHeight;
	#else
		half height = _LightDir.w;
	#endif
	shadowPos.y = height;
	shadowPos.xz = wPos.xz - lightDir.xz * (wPos.y / (lightDir.y + height));
	shadowPos = lerp(shadowPos, wPos, step(wPos.y - height, 0));

	return shadowPos;
}

// --------------------------------------------- 顶点着色 ---------------------------------------------------

v2fShadow vert(appdata v)
{
	v2fShadow o;
	float3 shadowPos = ShadowProjectPos(v.vertex);
	o.vertex = UnityWorldToClipPos(shadowPos);
	#if _CUSTOM_HEIGHT_ON
		float3 center = float3(unity_ObjectToWorld[0].w, _CustomHeight, unity_ObjectToWorld[2].w);
	#else
		float3 center = float3(unity_ObjectToWorld[0].w, _LightDir.w, unity_ObjectToWorld[2].w);
	#endif
	half falloff = saturate(1 - distance(shadowPos, center) * _ShadowFalloff);
	o.color = _ShadowCol * falloff;
	return o;
}

// --------------------------------------------- 片元着色 ---------------------------------------------------

fixed4 frag(v2fShadow i) : SV_Target
{
#if ENABLE_DISSOLVE
	i.color.a = _DissolveParams.z;
#endif
	return i.color;
}

#endif
