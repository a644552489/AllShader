

sampler2D _MainTex;
float4 _MainTex_ST;
half _AlphaIsMask;

float _BodyAlPah;      //角色透明度
float _TexAlaphDelta;

sampler2D _ShadowTex;
float4 _ShadowColor;

#if USE_COMBINE_CHANNEL_ON
	sampler2D _LightMask;
#elif USE_SPLIT_CHANNEL_ON
	sampler2D _LightMask_R,_LightMask_G,_LightMask_B,_LightMask_A;
#endif

fixed4 _MainColor;
float _LightArea;         // diffuse 阈值
float _ShadowWidthSmooth; // 阴影平滑过渡

fixed4 _SecondRimColor;
half _SecondRimStrenth;

//自发光流动
#if _Emissve_Float_ON
sampler2D _EmissiveTex;
float4 _EmissiveTex_ST;
fixed _EmissiveStrength;
fixed _EmissiveOffsetX,_EmissiveOffsetY;
float4 _EmissiveColor;
#endif

//自发光闪动
#if _Emissve_SIN_ON	
fixed _SinEmissiveStrength;
float4 _SinEmissiveColor;
fixed _SinEmissiveFrequent;
#endif

//固定灯光
//从外部传入
uniform half _IsUseFixedLight;
uniform float3 _LightDir;

//如果使用了溶解
#ifndef _NoneDissovle
float _DisolveValue;
sampler2D _DisolveTex;
float _DisolveLineWidth;
float4 _DisolveLineFirstColor,_DisolveLineSecondColor;
#ifdef _UseDissovleTwist
	sampler2D _GlobalGrabTexture;
	sampler2D _TwistTex;
	float _TwistStregth;
#endif
#endif

struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float3 normal:NORMAL;
	float3 vertexColor : COLOR0;
};

struct v2f
{
	float2 uv : TEXCOORD0;
	float4 pos : SV_POSITION;

	float3 worldNormal:TEXCOORD1;
    float3 worldPos:TEXCOORD2;
	float3 vertexColor :TEXCOORD4;

#if _Emissve_Float_ON
	float2 uv_emissve_float :TEXCOORD5;
#endif

//使用溶解扭曲
#if _UseDissovleTwist
	float4 projPos : TEXCOORD6;
#endif
};

// 设置自发光
fixed4 SetEmmisveColor(v2f i,fixed4 lightMaskCol,fixed4 finalColor)
{
//流动
	#if _Emissve_Float_ON
		fixed moveTimeX = _Time.x * _EmissiveOffsetX;
		fixed moveTimeY = _Time.y * _EmissiveOffsetY;
		float2 emissveUv = float2(i.uv_emissve_float.x + moveTimeX,i.uv_emissve_float.y + moveTimeY);
		fixed4 EmissiveColor = lightMaskCol.g * tex2D(_EmissiveTex,emissveUv) * _EmissiveColor * _EmissiveStrength;
		finalColor += EmissiveColor;
	#endif

	//直接自发光
	#if _Emissve_SIN_ON
		// 乘以一个控制值
		fixed EmissiveAlpha = sin(_SinEmissiveFrequent *  _Time.x) *0.5 + 0.5;
		fixed4 SinEmissiveColor = lightMaskCol.a * _SinEmissiveColor * _SinEmissiveStrength * EmissiveAlpha;
		finalColor += SinEmissiveColor;
	#endif 
	return finalColor;
}



v2f vert (appdata v)
{
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);

#if _Emissve_Float_ON
	o.uv_emissve_float = TRANSFORM_TEX(v.uv,_EmissiveTex);
#endif

#if _UseDissovleTwist
	o.projPos = ComputeGrabScreenPos(o.pos);
#endif 
	o.worldPos = mul(unity_ObjectToWorld,v.vertex);
	o.worldNormal = UnityObjectToWorldNormal(v.normal);

	o.vertexColor = v.vertexColor;
	return o;
}

fixed4 frag (v2f i) : SV_Target
{
	float3 worldPos = i.worldPos;
	float3 worldNormal = normalize(i.worldNormal);

	//是否使用固定光照，如果在UI上，一般直接写入灯光的方向
	float3 LightDir = lerp(UnityWorldSpaceLightDir(worldPos), _LightDir, _IsUseFixedLight);

	fixed4 mainCol = tex2D(_MainTex, i.uv);
	//是否使用 单纯的阴影颜色 乘 主贴图
	#if USE_SHADOWCOLOR_MUL_TEXCOLOR
		fixed4 shadowCol = mainCol * _ShadowColor;
	#else
		fixed4 shadowCol = tex2D(_ShadowTex,i.uv) * _ShadowColor;
	#endif

	fixed4 lightMaskCol = fixed4(0.5,0.5,1,0);
	//是否使用 Mask图
	#if USE_COMBINE_CHANNEL_ON
	lightMaskCol = tex2D(_LightMask,i.uv);
	#elif USE_SPLIT_CHANNEL_ON
	lightMaskCol.r = tex2D(_LightMask_R,i.uv).r;
	lightMaskCol.g = tex2D(_LightMask_G,i.uv).r;
	lightMaskCol.b = tex2D(_LightMask_B,i.uv).r;
	lightMaskCol.a = tex2D(_LightMask_A,i.uv).r;
	#endif

	//===============================漫反射======================================
    half halfLambert = dot(worldNormal,LightDir) * 0.5 + 0.5;
	fixed diffuseMask = (halfLambert + (lightMaskCol.r) * i.vertexColor.r ) * 0.5;//贴图 R 通道 *  顶点 R通道 共同控制
	//fixed3 diffuseColor = (diffuseMask >= _LightArea) ? mainCol.rgb : shadowCol.rgb;
	fixed diffuseStep =  smoothstep(0,_ShadowWidthSmooth,saturate(diffuseMask - _LightArea));
	half3 finalDiffuseColor  = lerp(shadowCol,mainCol.rgb,diffuseStep);

	//===============================边缘光=====================================
    half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
	half NDOTV = dot(worldNormal,viewDir);
    
	//===========第二层边缘光在代码控制，用来控制被攻击时候的闪白===
	half secondRim = 1 - saturate(abs(NDOTV));
	half3 secondRimColor = secondRim * _SecondRimColor * _SecondRimStrenth ;

	//==============加起所有着色后的颜色======
	fixed4 finalColor = fixed4(secondRimColor + finalDiffuseColor,1);
	finalColor = finalColor * _MainColor;

	//自发光
	finalColor = SetEmmisveColor(i,lightMaskCol,finalColor);
	//设置溶解
	//finalColor = SetDissovle(i,0,finalColor);
	return finalColor;
}

v2f veryLowVert(appdata v)
{
	v2f o = (v2f)0;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	return o;
}

fixed4 veryLowfrag(v2f i):SV_Target
{
	fixed4 mainCol = tex2D(_MainTex, i.uv);
	mainCol.a = _BodyAlPah * saturate(mainCol.a + _TexAlaphDelta);
	mainCol.a = lerp(mainCol.a, 1, _AlphaIsMask);
	return mainCol;
}

