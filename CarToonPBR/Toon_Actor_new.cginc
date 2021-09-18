struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float4 tangent :TANGENT;
	float3 normal:NORMAL;
	float3 vertexColor : COLOR0;
};

struct v2f
{
	float2 uv : TEXCOORD0;
	float4 pos : SV_POSITION;

	float4 TtoW0:TEXCOORD1;
	float4 TtoW1:TEXCOORD2;
	float4 TtoW2:TEXCOORD3;
	float3 vertexColor :TEXCOORD4;

#if _Emissve_Float_ON
	float2 uv_emissve_float :TEXCOORD5;
#endif

//使用溶解扭曲
#if _UseDissovleTwist
	float4 projPos : TEXCOORD6;
#endif
};

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _ShadowTex;  //阴影图
float4 _ShadowColor;   //阴影颜色
float _Alpha;		   //透明度
float _BodyAlPah;      //角色透明度

#if USE_COMBINE_CHANNEL_ON
	sampler2D _LightMask;
#elif USE_SPLIT_CHANNEL_ON
	sampler2D _LightMask_R,_LightMask_G,_LightMask_B,_LightMask_A;
#endif

fixed4 _MainColor;
float _LightArea;         // diffuse 阈值
float _ShadowWidthSmooth; // 阴影平滑过渡

float4 _SpecularColor;
float _Gloss;
float _ShinnessMulti;

//是否使用MatCap高光
#ifndef USE_SPECULAR_ON
	sampler2D _NormalMapForMatCap,_HairMatCapTex;
	float4 _NormalMapForMatCap_ST;
	fixed _TweakUv;
	float4 _MatcapColor;
#endif

//使用使用法线贴图
#if NORMAL_MAP_ON
sampler2D _BumpMap;
float _BumpScale;
#endif

sampler2D _FalloffSampler;
//是否使用边缘光
#if USE_RIM_LIGHT_ON
fixed4 _RimColor;
fixed _RimPower,_RimStrength;
#endif
//是否使用另一版本的边缘光(V2)
#if _USE_RIM_LIGHT_ON_V2
sampler2D _RimLightMap;
fixed4 _RimLightColor;
fixed _RimContrast, _RimStrengthV2, _RimEdgeDelta;
#endif
//被攻边缘光
fixed4 _SecondRimColor;
half _SecondRimStrenth;

// 霸体边缘光
#if _ArmorBodyRim
fixed4 _ArmorBodyRimColor;
half _ArmorBodyRimStrenth;
#endif


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
#if _USE_FIX_LIGHTDIR
//从外部传入
float3 _LightDir;
fixed4 _FixedLightColor;
fixed4 _FixedLightIntensity;
#endif

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

// Constants
#define FALLOFF_POWER 0.3


//获取世界坐标下的法线，包含是否使用 Normap
float3 GetWorldNormal(float3 normal,float3x3 tangentTransform,float2 uv)
{
	float3 worldNormal;
	#ifndef NORMAL_MAP_ON
		worldNormal = normalize(normal);
	#else
		float3 bump = UnpackScaleNormal(tex2D(_BumpMap,uv),_BumpScale);
		worldNormal = normalize( mul(bump,tangentTransform));
	#endif
	return worldNormal;
}

//通过MatCap表现头发的各向异性高光
#if USE_HAIR_SPECULAR_ON || USE_ALL_SPECULAR_ON
fixed3 GetMatCapColor(v2f i,float3x3 tangentTransform,fixed4 mainCol,fixed4 lightMaskCol)
{	
	fixed3 finalSpecularCol_Hair = 0;
	fixed3 normal_MatCap = UnpackNormal(tex2D(_NormalMapForMatCap,TRANSFORM_TEX(i.uv,_NormalMapForMatCap)));
	normal_MatCap = mul(normal_MatCap,tangentTransform); //转到世界空间下
	fixed3 MV_Normal = mul(UNITY_MATRIX_V,float4(normal_MatCap,0)); //转到摄像机空间下
	fixed2 Twake_afterUv = (MV_Normal.xy *0.5 + 0.5-_TweakUv); //转换到纹理区间
	fixed4 matcapCol = tex2D(_HairMatCapTex, Twake_afterUv);
	finalSpecularCol_Hair = matcapCol * _MatcapColor * _ShinnessMulti * lightMaskCol.b * mainCol.a; //使用a 通道进行控制
	return finalSpecularCol_Hair;
}
#endif

// 设置自发光
fixed4 SetEmmisveColor(v2f i,fixed4 lightMaskCol,fixed4 finalColor)
{
//流动
	#if _Emissve_Float_ON
		fixed moveTimeX = _Time.x * _EmissiveOffsetX;
		fixed moveTimeY = _Time.y * _EmissiveOffsetY;
		float2 emissveUv = float2(i.uv_emissve_float.x + moveTimeX,i.uv_emissve_float.y + moveTimeY);
		fixed4 EmissiveColor = lightMaskCol.g * tex2D(_EmissiveTex,emissveUv) * _EmissiveColor * _EmissiveStrength;
		finalColor.rgb += EmissiveColor.rgb;
	#endif

	//直接自发光
	#if _Emissve_SIN_ON
		// 乘以一个控制值
		fixed EmissiveAlpha = sin(_SinEmissiveFrequent *  _Time.x) *0.5 + 0.5;
		fixed4 SinEmissiveColor = lightMaskCol.a * _SinEmissiveColor * _SinEmissiveStrength * EmissiveAlpha;
		finalColor.rgb += SinEmissiveColor.rgb;
	#endif 
	return finalColor;
}

//计算溶解
//包含扭曲或者不扭曲的人物溶解
fixed4 SetDissovle(v2f i,fixed4 rimColor,fixed4 finalColor)
{
	#ifndef _NoneDissovle
		fixed dissolve = tex2D(_DisolveTex,i.uv).r;
		fixed dissovle_area = dissolve - _DisolveValue;
		fixed4 dissvoleColor = lerp(_DisolveLineFirstColor,_DisolveLineSecondColor,dissovle_area); 
		//没有扭曲
		#if _UseDissovle
			if(dissovle_area <= 0)
			{
				return 0;
			}
			fixed4 alhpaColor = finalColor + rimColor;
			fixed4 alhpaFinalCol = lerp(alhpaColor,dissvoleColor * 2,smoothstep(0.0,_DisolveLineWidth,dissovle_area)) ;
			finalColor = lerp(alhpaFinalCol,finalColor,step(_DisolveLineWidth,dissovle_area));
		#endif

		//带扭曲的方案
		#if _UseDissovleTwist
			fixed2 twistUv = i.projPos / i.projPos.w;
			fixed twistR = tex2D(_TwistTex,i.uv).r * 2 -1; //使扭曲 映射到 -1,1的区间
			twistUv += twistUv * twistR * _TwistStregth;
			fixed4 twistCol = tex2D(_GlobalGrabTexture,twistUv);
			
			if(dissovle_area <= 0)
				return twistCol;	

			twistCol = rimColor + twistCol;
			fixed4 twistFinalCol = lerp(twistCol,dissvoleColor * 2,smoothstep(0.0,_DisolveLineWidth,dissovle_area)) ;
			finalColor = lerp(twistFinalCol,finalColor,step(_DisolveLineWidth,dissovle_area));
		#endif
	#endif
	return finalColor;
}


//顶点着色
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


	float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
	float3 worldNormal = UnityObjectToWorldNormal(v.normal);
	float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
	float3 BiNormal =  cross(worldNormal,worldTangent) * v.tangent.w;
	o.TtoW0 = float4(worldTangent.x,BiNormal.x,worldNormal.x,worldPos.x);
	o.TtoW1 = float4(worldTangent.y,BiNormal.y,worldNormal.y,worldPos.y);
	o.TtoW2 = float4(worldTangent.z,BiNormal.z,worldNormal.z,worldPos.z);
	o.vertexColor = v.vertexColor;
	return o;
}
//片元
fixed4 frag (v2f i) : SV_Target
{
	
	float3 worldTangent = float3(i.TtoW0.x,i.TtoW1.x,i.TtoW2.x);
	float3 WorldBiNormal = float3(i.TtoW0.y,i.TtoW1.y,i.TtoW2.y);
	float3 worldNormal = float3(i.TtoW0.z,i.TtoW1.z,i.TtoW2.z);
	float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);;
	float3x3 tangentTransform = float3x3(worldTangent,float3(WorldBiNormal),float3(worldNormal));

	worldNormal = GetWorldNormal(worldNormal,tangentTransform,i.uv);

	//是否使用固定光照，如果在UI上，一般直接写入灯光的方向
	#if _USE_FIX_LIGHTDIR
		float3 LightDir = _LightDir;
		fixed3 LightColor = _FixedLightColor.rgb;
	#else
		fixed3 LightColor = _LightColor0;
		float3 LightDir = UnityWorldSpaceLightDir(worldPos);
	#endif 
	
	half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
	half3 halfDir = normalize(viewDir + LightDir);	

	
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
//return float4(lightMaskCol.b,lightMaskCol.b, lightMaskCol.b, 1);

	//halfLambert 
	half halfLambert = dot(worldNormal,LightDir) * 0.5 + 0.5;
	
	fixed3 finalColorRGB = 0;

	//======================================高光部分=================================
	//高光部分，包含，单纯的高光，单纯的MatCap,以及 同时包含 高光和MatCap
	fixed3 finalSpecularCol = 0;
	fixed3 finalSpecularCol_Hair = 0;
	fixed specular = 0;
	#if USE_SPECULAR_ON // 高光
		specular = pow(max(0,dot(worldNormal,halfDir)), _Gloss * 256);
		finalSpecularCol = _SpecularColor * _ShinnessMulti * specular * lightMaskCol.b ;
	#elif USE_HAIR_SPECULAR_ON //MATCAP 高光
		finalSpecularCol_Hair = GetMatCapColor(i,tangentTransform,mainCol,lightMaskCol);

		finalColorRGB +=finalSpecularCol_Hair;
	#elif USE_ALL_SPECULAR_ON //MATCAP + 高光
		specular = pow(max(0,dot(worldNormal,halfDir)), _Gloss * 256);
		finalSpecularCol = _SpecularColor * _ShinnessMulti * specular * lightMaskCol.b * (1-mainCol.a);
		finalSpecularCol_Hair = GetMatCapColor(i,tangentTransform,mainCol,lightMaskCol);

		finalColorRGB +=finalSpecularCol_Hair;
	#endif

	
	//===============================漫反射======================================
	//贴图 R 通道 *  顶点 R通道 共同控制
	fixed diffuseMask = (halfLambert + (lightMaskCol.r) * i.vertexColor.r ) * 0.5;
	//fixed3 diffuseColor = (diffuseMask >= _LightArea) ? mainCol.rgb : shadowCol.rgb;
	fixed diffuseStep =  smoothstep(0,_ShadowWidthSmooth,saturate(diffuseMask - _LightArea));
	half3 finalDiffuseColor  = lerp(shadowCol,mainCol.rgb,diffuseStep);

	//===============================明部亮部===================================
	half NDOTV = dot(worldNormal,viewDir);
	half falloffU = clamp( 1 - abs( NDOTV ), 0.02, 0.98 );
	//half4 falloffSamplerColor = FALLOFF_POWER * tex2D( _FalloffSampler, float2( falloffU, 0.25f ) );
	//half3 shadowColor = mainCol.rgb * mainCol.rgb;
	//half3 finalDiffuseColor = lerp( mainCol.rgb, shadowColor, falloffSamplerColor.r );
	//finalDiffuseColor *= ( 1.0 + falloffSamplerColor.rgb * falloffSamplerColor.a );
	//===============================边缘光=====================================
	half _rim = 1 - saturate(abs(NDOTV));
	half3 rimColor =0;
	#if USE_RIM_LIGHT_ON
		half rim = pow(_rim,1 / _RimPower * 5 ) * _RimStrength;
		rimColor = rim * _RimColor;
		finalColorRGB += rimColor;
	#endif

	#if _USE_RIM_LIGHT_ON_V2
		//half falloffU = clamp( 1 - abs( NDOTV ), 0.02, 0.98 );
		//falloffU = tex2D( _RimLightMap, float2( falloffU, 0.25f ) ).r;
		//half modelHeightFactor = i.pos.y/_ScreenParams.y;
		//finalColorRGB = lerp(finalColorRGB, _RimLightColor.rgb, falloffU * _RimLightColor.a * modelHeightFactor * _RimStrengthV2);

		// Rimlight
		half rimlightDot = saturate( 0.5 * ( dot( worldNormal, LightDir ) + 1.0 ) );
		falloffU = saturate( rimlightDot * falloffU );
		falloffU = tex2D( _RimLightMap, float2( falloffU + _RimEdgeDelta, 0.25f ) ).r;
		half modelHeightFactor = i.pos.y/_ScreenParams.y;
		half3 rimLightColor = _RimLightColor.rgb * _RimLightColor.a * _RimStrengthV2 * modelHeightFactor; // * 2.0;
		finalColorRGB += falloffU * rimLightColor;
	#endif

	//===========第二层边缘光在代码控制，用来控制被攻击时候的闪白===
	half secondRim = _rim;
	half3 secondRimColor = secondRim * _SecondRimColor * _SecondRimStrenth ;
	finalColorRGB += secondRimColor;

	// ==========霸体边缘光
	#if _ArmorBodyRim
		half armorBodyRim = pow(_rim,2.5);
		half3 armorBodyRimColor = armorBodyRim *_ArmorBodyRimColor* _ArmorBodyRimStrenth;
		finalColorRGB += armorBodyRimColor;
	#endif	

	//==============加起所有着色后的颜色======
	fixed3 allLightColor = (finalDiffuseColor + finalSpecularCol) * LightColor;
//return float4(finalSpecularCol, 1);
	fixed4 finalColor = fixed4(finalColorRGB + allLightColor ,1);
	finalColor = finalColor * _MainColor;

	//自发光
	finalColor = SetEmmisveColor(i,lightMaskCol,finalColor);
	//#ifdef USE_ALPHABLEND
		finalColor.a = _Alpha;
	//#endif
	//设置溶解
	finalColor = SetDissovle(i,fixed4(rimColor,1),finalColor);
	finalColor.a =_BodyAlPah * _MainColor.a;
	return finalColor;
}

//顶点着色
v2f vertAdd (appdata v)
{
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = TRANSFORM_TEX(v.uv, _MainTex);

#if _UseDissovleTwist
	o.projPos = ComputeGrabScreenPos(o.pos);
#endif 


	float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
	float3 worldNormal = UnityObjectToWorldNormal(v.normal);
	float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
	float3 BiNormal =  cross(worldNormal,worldTangent) * v.tangent.w;
	o.TtoW0 = float4(worldTangent.x,BiNormal.x,worldNormal.x,worldPos.x);
	o.TtoW1 = float4(worldTangent.y,BiNormal.y,worldNormal.y,worldPos.y);
	o.TtoW2 = float4(worldTangent.z,BiNormal.z,worldNormal.z,worldPos.z);
	o.vertexColor = v.vertexColor;
	return o;
}
//片元
fixed4 fragAdd (v2f i) : SV_Target
{
	
	float3 worldTangent = float3(i.TtoW0.x,i.TtoW1.x,i.TtoW2.x);
	float3 WorldBiNormal = float3(i.TtoW0.y,i.TtoW1.y,i.TtoW2.y);
	float3 worldNormal = float3(i.TtoW0.z,i.TtoW1.z,i.TtoW2.z);
	float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);;
	float3x3 tangentTransform = float3x3(worldTangent,float3(WorldBiNormal),float3(worldNormal));

	worldNormal = GetWorldNormal(worldNormal,tangentTransform,i.uv);

	//是否使用固定光照，如果在UI上，一般直接写入灯光的方向
	#if _USE_FIX_LIGHTDIR
		float3 LightDir = _LightDir;
		fixed3 LightColor = _FixedLightColor.rgb;
	#else
		fixed3 LightColor = _LightColor0;
		float3 LightDir = UnityWorldSpaceLightDir(worldPos);
//float3 LightDir = _WorldSpaceLightPos0.xyz - worldPos.xyz * _WorldSpaceLightPos0.w;
	#endif 
//return float4(normalize(LightDir), 1);
	
	half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
	half3 halfDir = normalize(viewDir + LightDir);	

	
	fixed4 mainCol = tex2D(_MainTex, i.uv);

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

	//halfLambert 
	half halfLambert = dot(worldNormal,LightDir) * 0.5 + 0.5;
	
	fixed3 finalColorRGB = 0;

	//======================================高光部分=================================
	//高光部分，包含，单纯的高光，单纯的MatCap,以及 同时包含 高光和MatCap
	fixed3 finalSpecularCol = 0;
	fixed3 finalSpecularCol_Hair = 0;
	fixed specular = 0;

	#if USE_SPECULAR_ON // 高光
		specular = pow(max(0,dot(worldNormal,halfDir)), _Gloss * 256);
		finalSpecularCol = _SpecularColor * _ShinnessMulti * specular * lightMaskCol.b;
	#elif USE_HAIR_SPECULAR_ON //MATCAP 高光
		finalSpecularCol_Hair = GetMatCapColor(i,tangentTransform,mainCol,lightMaskCol);

		finalColorRGB +=finalSpecularCol_Hair;
	#elif USE_ALL_SPECULAR_ON //MATCAP + 高光
		specular = pow(max(0,dot(worldNormal,halfDir)), _Gloss * 256);
		finalSpecularCol = _SpecularColor * _ShinnessMulti * specular * lightMaskCol.b * (1-mainCol.a);
		finalSpecularCol_Hair = GetMatCapColor(i,tangentTransform,mainCol,lightMaskCol);

		finalColorRGB +=finalSpecularCol_Hair;
	#endif

	half3 rimColor =0;
	half NDOTV = dot(worldNormal,viewDir);
	half falloffU = clamp( 1 - abs( NDOTV ), 0.02, 0.98 );
	#if _USE_RIM_LIGHT_ON_V2
		// Rimlight
		half rimlightDot = saturate( 0.5 * ( dot( worldNormal, LightDir ) + 1.0 ) );
		falloffU = saturate( rimlightDot * falloffU );
		falloffU = tex2D( _RimLightMap, float2( falloffU, 0.25f ) ).r;
		half modelHeightFactor = i.pos.y/_ScreenParams.y;
		half3 rimLightColor = _RimLightColor.rgb * _RimLightColor.a * _RimStrengthV2 * modelHeightFactor; // * 2.0;
		finalColorRGB += falloffU * rimLightColor;
	#endif

//return float4(rimlightDot, rimlightDot,rimlightDot, 1);

	//==============加起所有着色后的颜色======
	//fixed3 allLightColor = (finalDiffuseColor + finalSpecularCol) * LightColor;
	//fixed4 finalColor = fixed4(finalColorRGB + allLightColor ,1);
	fixed3 allLightColor = (finalSpecularCol) * LightColor;
	fixed4 finalColor = fixed4(finalColorRGB+allLightColor ,1);
	finalColor = finalColor * _MainColor;

	//#ifdef USE_ALPHABLEND
		finalColor.a = _Alpha;
	//#endif
	//设置溶解
	finalColor = SetDissovle(i,fixed4(rimColor,1),finalColor);
	finalColor.a =_BodyAlPah;
	return finalColor;
}