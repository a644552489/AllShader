#ifndef FOG_COMMON_CGINC
#define FOG_COMMON_CGINC

#if defined(EMANLE_FOG)

#define UBPA_FOG_COORDS(ID)  float4 _fogCoord : TEXCOORD##ID;

// WorldSpaceViewDir : vertex to camera
// GetHeightExponentialFog need camera to vertex
#define UBPA_TRANSFER_FOG(Varyings, vertex) Varyings##._fogCoord = GetExponentialHeightFog(-WorldSpaceViewDir(vertex))

#define UBPA_APPLY_FOG(Varyings, positionWS, pixelColor)	\
	RENDING_MIX_AREA_FOG(Varyings, positionWS);				\
	pixelColor = fixed4(pixelColor.rgb * Varyings._fogCoord.a + Varyings._fogCoord.rgb, pixelColor.a)

#else
#define UBPA_FOG_COORDS(ID)   
#define UBPA_TRANSFER_FOG(Varyings, vertex)	;
#define UBPA_APPLY_FOG(Varyings, positionWS, pixelColor) ;

#endif

// unity not support struct
//struct Fog {
	// x : FogDensity * exp2(-FogHeightFalloff * (CameraWorldPosition.y - FogHeight))
	// y : FogHeightFalloff
	// [useless] z : CosTerminatorAngle
	// w : StartDistance
	float4 ExponentialFogParameters;

	// FogDensitySecond * exp2(-FogHeightFalloffSecond * (CameraWorldPosition.y - FogHeightSecond))
	// FogHeightFalloffSecond
	// FogDensitySecond
	// FogHeightSecond
	float4 ExponentialFogParameters2;

	// FogDensity in x
	// FogHeight in y
	// [useless] whether to use cubemap fog color in z
	// FogCutoffDistance in w
	float4 ExponentialFogParameters3;

	// xyz : directinal inscattering color
	// w : cosine exponent
	float4 DirectionalInscatteringColor;

	// xyz : directional light's direction. 方向光照射方向的反方向
	// w : direactional inscattering start distance
	float4 InscatteringLightDirection;

	// xyz : fog inscattering color
	// w : min transparency
	float4 ExponentialFogColorParameter;
//};
	sampler2D _FOGNOISETEX;

	uniform	float4 _FOGFLOWPARAMS;
	uniform	float4 _FOGFLOWPARAMS1;
	uniform	float4 _CLOUDCOLOR;
	uniform float4 _CloudParams;

static const float FLT_EPSILON2 = 0.01f;

float Pow2(float x) { return x * x; }

// UE 4.22 HeightFogCommon.ush
// Calculate the line integral of the ray from the camera to the receiver position through the fog density function
// The exponential fog density function is d = GlobalDensity * exp(-HeightFalloff * y)
float CalculateLineIntegralShared(float FogHeightFalloff, float RayDirectionY, float RayOriginTerms)
{
	float Falloff = max(-127.0f, FogHeightFalloff * RayDirectionY);    // if it's lower than -127.0, then exp2() goes crazy in OpenGL's GLSL.
	float LineIntegral = (1.0f - exp2(-Falloff)) / Falloff;
	float LineIntegralTaylor = log(2.0) - (0.5 * Pow2(log(2.0))) * Falloff;		// Taylor expansion around 0

	return RayOriginTerms * (abs(Falloff) > FLT_EPSILON2 ? LineIntegral : LineIntegralTaylor);
}

// UE 4.22 HeightFogCommon.ush
// @param WorldPositionRelativeToCamera = WorldPosition - InCameraPosition
half4 GetExponentialHeightFog(float3 WorldPositionRelativeToCamera) // camera to vertex
{


	


	const half MinFogOpacity = ExponentialFogColorParameter.w;

	// Receiver 指着色点
	float3 CameraToReceiver = WorldPositionRelativeToCamera;
	float CameraToReceiverLengthSqr = dot(CameraToReceiver, CameraToReceiver);
	float CameraToReceiverLengthInv = rsqrt(CameraToReceiverLengthSqr); // 平方根的倒数
	float CameraToReceiverLength = CameraToReceiverLengthSqr * CameraToReceiverLengthInv;
	half3 CameraToReceiverNormalized = CameraToReceiver * CameraToReceiverLengthInv;

	// FogDensity * exp2(-FogHeightFalloff * (CameraWorldPosition.y - FogHeight))
	float RayOriginTerms = ExponentialFogParameters.x;
	float RayOriginTermsSecond = ExponentialFogParameters2.x;
	float RayLength = CameraToReceiverLength;
	float RayDirectionY = CameraToReceiver.y;

	// Factor in StartDistance
	// ExponentialFogParameters.w 是 StartDistance
	float ExcludeDistance = ExponentialFogParameters.w;

	if (ExcludeDistance > 0)
	{
		// 到相交点所占时间
		float ExcludeIntersectionTime = ExcludeDistance * CameraToReceiverLengthInv;
		// 相机到相交点的 y 偏移
		float CameraToExclusionIntersectionY = ExcludeIntersectionTime * CameraToReceiver.y;
		// 相交点的 y 坐标
		float ExclusionIntersectionY = _WorldSpaceCameraPos.y + CameraToExclusionIntersectionY;
		// 相交点到着色点的 y 偏移
		float ExclusionIntersectionToReceiverY = CameraToReceiver.y - CameraToExclusionIntersectionY;

		// Calculate fog off of the ray starting from the exclusion distance, instead of starting from the camera
		// 相交点到着色点的距离
		RayLength = (1.0f - ExcludeIntersectionTime) * CameraToReceiverLength;
		// 相交点到着色点的 y 偏移
		RayDirectionY = ExclusionIntersectionToReceiverY;
		// ExponentialFogParameters.y : height falloff
		// ExponentialFogParameters3.y ： fog height
		// height falloff * height
		float Exponent = max(-127.0f, ExponentialFogParameters.y * (ExclusionIntersectionY - ExponentialFogParameters3.y));
		// ExponentialFogParameters3.x : fog density
		RayOriginTerms = ExponentialFogParameters3.x * exp2(-Exponent);

		// ExponentialFogParameters2.y : FogHeightFalloffSecond
		// ExponentialFogParameters2.w : fog height second
		float ExponentSecond = max(-127.0f, ExponentialFogParameters2.y * (ExclusionIntersectionY - ExponentialFogParameters2.w));
		RayOriginTermsSecond = ExponentialFogParameters2.z * exp2(-ExponentSecond);
	}

	// Calculate the "shared" line integral (this term is also used for the directional light inscattering) by adding the two line integrals together (from two different height falloffs and densities)
	// ExponentialFogParameters.y : fog height falloff
	float ExponentialHeightLineIntegralShared = CalculateLineIntegralShared(ExponentialFogParameters.y, RayDirectionY, RayOriginTerms)
		+ CalculateLineIntegralShared(ExponentialFogParameters2.y, RayDirectionY, RayOriginTermsSecond);
	// fog amount，最终的积分值
	float ExponentialHeightLineIntegral = ExponentialHeightLineIntegralShared * RayLength;

	// 雾色
	half3 InscatteringColor = ExponentialFogColorParameter.xyz;
	half3 DirectionalInscattering = 0;

	// if InscatteringLightDirection.w is negative then it's disabled, otherwise it holds directional inscattering start distance
	if (InscatteringLightDirection.w >= 0)
	{
		float DirectionalInscatteringStartDistance = InscatteringLightDirection.w;
		// Setup a cosine lobe around the light direction to approximate inscattering from the directional light off of the ambient haze;
		half3 DirectionalLightInscattering = DirectionalInscatteringColor.xyz * pow(saturate(dot(CameraToReceiverNormalized, InscatteringLightDirection.xyz)), DirectionalInscatteringColor.w);

		// Calculate the line integral of the eye ray through the haze, using a special starting distance to limit the inscattering to the distance
		float DirExponentialHeightLineIntegral = ExponentialHeightLineIntegralShared * max(RayLength - DirectionalInscatteringStartDistance, 0.0f);
		// Calculate the amount of light that made it through the fog using the transmission equation
		half DirectionalInscatteringFogFactor = saturate(exp2(-DirExponentialHeightLineIntegral));
		// Final inscattering from the light
		DirectionalInscattering = DirectionalLightInscattering * (1 - DirectionalInscatteringFogFactor);
	}

	// Calculate the amount of light that made it through the fog using the transmission equation
	// 最终的系数
	half ExpFogFactor = max(saturate(exp2(-ExponentialHeightLineIntegral)),MinFogOpacity) ;


	// ExponentialFogParameters3.w : FogCutoffDistance
	if (ExponentialFogParameters3.w > 0 && CameraToReceiverLength > ExponentialFogParameters3.w)
	{
		ExpFogFactor = 1;
		DirectionalInscattering = 0;
	}

	half3 FogColor = (InscatteringColor) * (1 - ExpFogFactor) + DirectionalInscattering;

	
	return half4(FogColor , ExpFogFactor ) ;
}

uniform sampler2D _AreaMaskTex;
uniform float4x4 _AreaMaskTransform;

float4 WorldToArea(float4 positionWS)
{
	positionWS = mul(_AreaMaskTransform, positionWS);
#if UNITY_UV_STARTS_AT_TOP
	float scale = -1.0;
#else
	float scale = 1.0;
#endif
	float4 o = positionWS * 0.5 ;
	o.xy = float2(o.x, o.y * scale) + o.w;
	o.zw = positionWS.zw;
	return o;
}

half GetBlendAreaMask(float3 positionWS  ,inout half4 baseColor )
{ 

	

	float4 positionSS = WorldToArea(float4(positionWS , 1));


	float2 uv = (positionSS.xy  / positionSS.w);

	
	half mask = 0.0;

	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0)
		mask = tex2D(_AreaMaskTex, uv).r;


	

	return mask;
}


half4 SetFogFlow(float3 positionWS , float4 baseColor , float mask  )
{
	float Opacity = (1 - ExponentialFogColorParameter.w);

	float t = saturate(positionWS.y / _FOGFLOWPARAMS.w);

	 mask = lerp(mask , 0 , saturate(t) * Opacity);


//	baseColor.a = saturate(baseColor.a +  mask);
//	baseColor.rgb = baseColor.rgb * (1 - baseColor.a);

	float2 uv = float2(positionWS.x, positionWS.z)*0.01;

	float2 noiseUV = uv * _FOGFLOWPARAMS.x+ _Time.x  * half2(_FOGFLOWPARAMS.y , _FOGFLOWPARAMS.z);
	half3 noiseColor =( tex2D(_FOGNOISETEX, noiseUV).rgb);
	float fogDensity = saturate((_CloudParams.y - positionWS.y -noiseColor.r *10 )/ (_CloudParams.y - _CloudParams.x));
	fogDensity = saturate(fogDensity * fogDensity);

	fogDensity = lerp(  1, fogDensity , Opacity);
	
 //    float edge = smoothstep(_CloudParams.z , 1 , mask);

	float Area = saturate(noiseColor.r * Opacity )  ;

	

	float visual = lerp( mask , Area , _FOGFLOWPARAMS1.y);
	

	Area = lerp(0 ,visual , mask);



	baseColor.a = saturate(  fogDensity + Area );


	 baseColor.rgb = lerp(baseColor.rgb , 0 , baseColor.a);

	
	return baseColor;





	// float CloudArea = saturate(noiseColor.r * Opacity );

	// CloudArea =( lerp(CloudArea * _FOGFLOWPARAMS1.x, CloudArea * _FOGFLOWPARAMS1.y, mask));


	// half CloudMask = lerp(baseColor.a , 0, CloudArea) ;

	// noiseColor = lerp(ExponentialFogColorParameter.rgb , _CLOUDCOLOR.rgb, CloudArea );
	// noiseColor = lerp(baseColor.rgb,  noiseColor , CloudArea)   ;


	// noiseColor = lerp(noiseColor, ExponentialFogColorParameter.rgb, saturate(t) * Opacity) ;

	// half4 Cloud = half4(noiseColor, CloudMask);



	// return Cloud;
}

#define RENDING_MIX_AREA_FOG(varyings, positionWS)								\
	half fogMask = GetBlendAreaMask(positionWS ,varyings._fogCoord );			\
	half4 Flow = SetFogFlow(positionWS ,varyings._fogCoord ,fogMask );			  \
	varyings._fogCoord = float4(  Flow.rgb  , Flow.a );

#endif// !FOG_COMMON_CGINC
