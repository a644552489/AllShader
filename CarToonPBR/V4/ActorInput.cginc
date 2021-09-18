#ifndef __ACTOR_INPUT_CGINC__
#define __ACTOR_INPUT_CGINC__

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

#include "../Lib/Shadows.cginc"

//////////////////////////////////////////////
// 支持的变体
/*
材质：
_USE_NORMAL_MAP
_USE_MASK_DYE
_USE_SHADOWMAP
_Emissve_Float_ON
_Emissve_SIN_ON

全局：
USE_ACTOR_SHADOW_TEX
*/

//////////////////////////////////////////////
// 宏定义
/*
_FACE
_HAIR
_USE_RIM
*/

//////////////////////////////////////////////
// 开关定义

// 法线开关
#define USING_NORMAL_MAP defined(_USE_NORMAL_MAP)

// 发梢渐变开关
#define USING_MASK_DYE defined(_USE_MASK_DYE)

// 边缘光开关
#define USING_RIM defined(_USE_RIM)

// 透贴开关
#define USING_ALPHA_CUTOFF defined(_USE_ALPHA_CUTOFF)

// 阴影
#define USING_SHADOWMAP defined(_USE_SHADOWMAP)

//////////////////////////////////////////////
// 结构体

// 顶点输入数据
struct Attributes
{
	float4 vertex		: POSITION;
	float2 texcoord0	: TEXCOORD0;
	float3 normalOS		: NORMAL;
	float4 tangentOS    : TANGENT;
	float4 color		: COLOR0;
};

// 片元输入数据
struct Varyings
{
	float4 pos		: SV_POSITION;
	float4 texcoord			: TEXCOORD0;

#if USING_NORMAL_MAP
	float4 normalWS			: TEXCOORD1;	// xyz:法线		w：世界坐标x
	float4 tangentWS		: TEXCOORD2;	// xyz:切线		w：世界坐标y
	float4 bitangentWS		: TEXCOORD3;	// xyz:副切线	w：世界坐标z
#else
	float3 positionWS		: TEXCOORD1;
	float3 normalWS			: TEXCOORD2;
#ifdef _HAIR
	float3 bitangentWS		: TEXCOORD3;
#endif
#endif

#if USING_RIM
	float3 rimLightDir		: TEXCOORD4;	// 边缘光方向
#endif

#if USING_SHADOWMAP
	float4 shadowCoord		: TEXCOORD5;
#endif

#ifdef VERTEXLIGHT_ON
	float3 vertexLighting	: TEXCOORD6;
#endif

	half4 color				: COLOR;

	SHADOW_COORDS(7)
};

struct VertexPositionInputs
{
	float3 positionWS; // World space position
	float3 positionVS; // View space position
	float4 pos; // Homogeneous clip space position
};

struct VertexNormalInputs
{
	float3 tangentWS;
	float3 bitangentWS;
	float3 normalWS;
};

struct LightData
{
	float3 direction;
	half3 color;
};

//////////////////////////////////////////////
// 材质贴图
uniform sampler2D _MainTex;
uniform sampler2D _BumpMap;
uniform samplerCUBE _CubeMap;
#if _USESRSMAP_ON
	#if _USEBLENDSRSMAP_ON
		uniform sampler2D _SRSMap;
	#endif
	uniform sampler2D _SpecMap;
	uniform sampler2D _RefMap;
	uniform sampler2D _SmoothnessMap;
#endif

uniform sampler2D _LightMaskTex;
uniform sampler2D _EmissiveMaskTex;
uniform sampler2D _EmissiveTex;

//////////////////////////////////////////////
// 材质属性
uniform half4 _MainColor;
uniform float4 _MainTex_ST;



//角色透明度
uniform half _BodyAlPah;

// 透明阀值
uniform half _Cutoff;

uniform float3 _FaceDir;

uniform half3 _RimColor;
//uniform half _RimSideWidth;
uniform half _RimPower;
uniform half _RimStrength;

uniform half _IsUseFixedLight;
uniform float3 _FixedLightDir;
uniform half _FixedLightIntensity;

uniform half _UseFixedLightColor;
uniform half3 _FixedLightColor;

// 自发光流动
uniform float4 _EmissiveTex_ST;
uniform half _EmissiveStrength;
uniform half _EmissiveOffsetX, _EmissiveOffsetY;
uniform half3 _EmissiveColor;

// 闪动
uniform half _SinEmissiveStrength;
uniform half _SinEmissiveFrequent;
uniform half3 _SinEmissiveColor;

#if _USESRSMAP_ON

//反射
uniform half3 _Ref;
//平滑
uniform half _Smoothness;
uniform half4 _Light1Color;

#endif
//////////////////////////////////////////////
// 功能函数
VertexPositionInputs GetVertexPositionInputs(float4 positionOS)
{
	VertexPositionInputs input;
	input.positionWS = mul(unity_ObjectToWorld, positionOS).xyz;
	input.positionVS = UnityObjectToViewPos(positionOS);
	input.pos = UnityObjectToClipPos(positionOS);
	return input;
}

VertexNormalInputs GetVertexNormalInputs(float3 normalOS, float4 tangentOS)
{
	VertexNormalInputs tbn;
	tbn.normalWS = UnityObjectToWorldNormal(normalOS);
	tbn.tangentWS = UnityObjectToWorldDir(tangentOS.xyz);

	half sign = tangentOS.w * unity_WorldTransformParams.w;
	tbn.bitangentWS = cross(tbn.normalWS, tbn.tangentWS) * sign;

	return tbn;
}

LightData GetDefaultLightData(float3 positionWS)
{
	LightData data = (LightData)0;
	data.direction = lerp(UnityWorldSpaceLightDir(positionWS).xyz, _FixedLightDir, _IsUseFixedLight);
	//data.direction.y = 0.0;
	data.color = lerp(_LightColor0.rgb, _FixedLightIntensity * _FixedLightColor, _UseFixedLightColor);
	return data;
}

//////////////////////////////////////////////
// 顶点函数
Varyings vert(Attributes v)
{
	VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex);

	float3 normalOS = v.normalOS;
#ifdef _FACE
	normalOS = _FaceDir;
#endif
	VertexNormalInputs normalInput = GetVertexNormalInputs(normalOS, v.tangentOS);

	Varyings output = (Varyings)0;
	output.pos = vertexInput.pos;
	output.texcoord.xy = TRANSFORM_TEX(v.texcoord0, _MainTex);
#ifdef _Emissve_Float_ON
	output.texcoord.zw = TRANSFORM_TEX(v.texcoord0, _EmissiveTex);
#endif

	output.color = v.color;

#if USING_NORMAL_MAP
	output.normalWS = float4(normalInput.normalWS, vertexInput.positionWS.x);
	output.tangentWS = float4(normalInput.tangentWS.xyz, vertexInput.positionWS.y);
	output.bitangentWS = float4(normalInput.bitangentWS, vertexInput.positionWS.z);
#else
	output.positionWS = vertexInput.positionWS;
	output.normalWS = normalInput.normalWS;

#ifdef _HAIR
	// 头发需要副切线计算高光
	output.bitangentWS = normalInput.bitangentWS;
#endif
#endif

#if USING_RIM
	output.rimLightDir = mul(float4(-0.8, 0.1, -0.7, 0.0), UNITY_MATRIX_V).xyz;
#endif

	// 计算阴影坐标
#if USING_SHADOWMAP
	output.shadowCoord = GetShadowCoord(vertexInput.positionWS);
#endif

#ifdef VERTEXLIGHT_ON
	output.vertexLighting = Shade4PointLights(unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, vertexInput.positionWS, normalInput.normalWS);
#endif
	
	TRANSFER_SHADOW(output);

	return output;
}

#endif
