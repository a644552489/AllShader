

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

//ʹ���ܽ�Ť��
#if _UseDissovleTwist
	float4 projPos : TEXCOORD6;
#endif
};

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _ShadowTex;  //��Ӱͼ
float4 _ShadowColor;   //��Ӱ��ɫ
float _Alpha;		   //͸����
float _BodyAlPah;      //��ɫ͸����

samplerCUBE _CubeMap;
fixed _CubeReflTex_scale;
float _CubeRoughness;

#if USE_COMBINE_CHANNEL_ON
	sampler2D _LightMask;
#elif USE_SPLIT_CHANNEL_ON
	sampler2D _LightMask_R,_LightMask_G,_LightMask_B,_LightMask_A;
#endif

fixed4 _MainColor;
float _LightArea;         // diffuse ��ֵ
float _ShadowWidthSmooth; // ��Ӱƽ������

float4 _SpecularColor;
float _Gloss;
float _ShinnessMulti;

//�Ƿ�ʹ��MatCap�߹�
#ifndef USE_SPECULAR_ON
	sampler2D _NormalMapForMatCap,_HairMatCapTex;
	float4 _NormalMapForMatCap_ST;
	fixed _TweakUv;
	float4 _MatcapColor;
#endif

//ʹ��ʹ�÷�����ͼ
#if NORMAL_MAP_ON
sampler2D _BumpMap;
float _BumpScale;
#endif

//�Ƿ�ʹ�ñ�Ե��
#if USE_RIM_LIGHT_ON
fixed4 _RimColor;
fixed _RimPower,_RimStrength;
#endif
//������Ե��
fixed4 _SecondRimColor;
half _SecondRimStrenth;

// �����Ե��
#if _ArmorBodyRim
fixed4 _ArmorBodyRimColor;
half _ArmorBodyRimStrenth;
#endif


//�Է�������
#if _Emissve_Float_ON
sampler2D _EmissiveTex;
float4 _EmissiveTex_ST;
fixed _EmissiveStrength;
fixed _EmissiveOffsetX,_EmissiveOffsetY;
float4 _EmissiveColor;
#endif

//�Է�������
#if _Emissve_SIN_ON	
fixed _SinEmissiveStrength;
float4 _SinEmissiveColor;
fixed _SinEmissiveFrequent;
#endif

//�̶��ƹ�
uniform half _IsUseFixedLight;
uniform float3 _LightDir;

//���ʹ�����ܽ�
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


//��ȡ���������µķ��ߣ������Ƿ�ʹ�� Normap
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

//ͨ��MatCap����ͷ���ĸ������Ը߹�
#if USE_HAIR_SPECULAR_ON || USE_ALL_SPECULAR_ON
fixed3 GetMatCapColor(v2f i,float3x3 tangentTransform,fixed4 mainCol,fixed4 lightMaskCol)
{	
	fixed3 finalSpecularCol_Hair = 0;
	fixed3 normal_MatCap = UnpackNormal(tex2D(_NormalMapForMatCap,TRANSFORM_TEX(i.uv,_NormalMapForMatCap)));
	normal_MatCap = mul(normal_MatCap,tangentTransform); //ת������ռ���
	fixed3 MV_Normal = mul(UNITY_MATRIX_V,float4(normal_MatCap,0)); //ת��������ռ���
	fixed2 Twake_afterUv = (MV_Normal.xy *0.5 + 0.5-_TweakUv); //ת������������
	fixed4 matcapCol = tex2D(_HairMatCapTex, Twake_afterUv);
	finalSpecularCol_Hair = matcapCol * _MatcapColor * _ShinnessMulti * lightMaskCol.b * mainCol.a; //ʹ��a ͨ�����п���
	return finalSpecularCol_Hair;
}
#endif

// �����Է���
fixed4 SetEmmisveColor(v2f i,fixed4 lightMaskCol,fixed4 finalColor)
{
//����
	#if _Emissve_Float_ON
		fixed moveTimeX = _Time.x * _EmissiveOffsetX;
		fixed moveTimeY = _Time.y * _EmissiveOffsetY;
		float2 emissveUv = float2(i.uv_emissve_float.x + moveTimeX,i.uv_emissve_float.y + moveTimeY);
		fixed4 EmissiveColor = lightMaskCol.g * tex2D(_EmissiveTex,emissveUv) * _EmissiveColor * _EmissiveStrength;
		finalColor.rgb += EmissiveColor.rgb;
	#endif

	//ֱ���Է���
	#if _Emissve_SIN_ON
		// ����һ������ֵ
		fixed EmissiveAlpha = sin(_SinEmissiveFrequent *  _Time.x) *0.5 + 0.5;
		fixed4 SinEmissiveColor = lightMaskCol.a * _SinEmissiveColor * _SinEmissiveStrength * EmissiveAlpha;
		finalColor.rgb += SinEmissiveColor.rgb;
	#endif 
	return finalColor;
}

//�����ܽ�
//����Ť�����߲�Ť���������ܽ�
fixed4 SetDissovle(v2f i,fixed4 rimColor,fixed4 finalColor)
{
	#ifndef _NoneDissovle
		fixed dissolve = tex2D(_DisolveTex,i.uv).r;
		fixed dissovle_area = dissolve - _DisolveValue;
		fixed4 dissvoleColor = lerp(_DisolveLineFirstColor,_DisolveLineSecondColor,dissovle_area); 
		//û��Ť��
		#if _UseDissovle
			if(dissovle_area <= 0)
			{
				return 0;
			}
			fixed4 alhpaColor = finalColor + rimColor;
			fixed4 alhpaFinalCol = lerp(alhpaColor,dissvoleColor * 2,smoothstep(0.0,_DisolveLineWidth,dissovle_area)) ;
			finalColor = lerp(alhpaFinalCol,finalColor,step(_DisolveLineWidth,dissovle_area));
		#endif

		//��Ť���ķ���
		#if _UseDissovleTwist
			fixed2 twistUv = i.projPos / i.projPos.w;
			fixed twistR = tex2D(_TwistTex,i.uv).r * 2 -1; //ʹŤ�� ӳ�䵽 -1,1������
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


//������ɫ
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
//ƬԪ
fixed4 frag (v2f i) : SV_Target
{
	
	float3 worldTangent = float3(i.TtoW0.x,i.TtoW1.x,i.TtoW2.x);
	float3 WorldBiNormal = float3(i.TtoW0.y,i.TtoW1.y,i.TtoW2.y);
	float3 worldNormal = float3(i.TtoW0.z,i.TtoW1.z,i.TtoW2.z);
	float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);;
	float3x3 tangentTransform = float3x3(worldTangent,float3(WorldBiNormal),float3(worldNormal));

	worldNormal = GetWorldNormal(worldNormal,tangentTransform,i.uv);

	//�Ƿ�ʹ�ù̶����գ������UI�ϣ�һ��ֱ��д��ƹ�ķ���
	float3 LightDir = lerp(UnityWorldSpaceLightDir(worldPos), _LightDir, _IsUseFixedLight);
	fixed3 LightColor = lerp(_LightColor0, fixed3(1, 1, 1), _IsUseFixedLight);
	
	half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
	half3 halfDir = normalize(viewDir + LightDir);	

	
	fixed4 mainCol = tex2D(_MainTex, i.uv);
	//�Ƿ�ʹ�� ��������Ӱ��ɫ �� ����ͼ
	#if USE_SHADOWCOLOR_MUL_TEXCOLOR
		fixed4 shadowCol = mainCol * _ShadowColor;
	#else
		fixed4 shadowCol = tex2D(_ShadowTex,i.uv) * _ShadowColor;
	#endif


	fixed4 lightMaskCol =fixed4(0.5,0.5,1,0);
	//�Ƿ�ʹ�� Maskͼ
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

	//======================================�߹ⲿ��=================================
	//�߹ⲿ�֣������������ĸ߹⣬������MatCap,�Լ� ͬʱ���� �߹��MatCap
	fixed3 finalSpecularCol = 0;
	fixed3 finalSpecularCol_Hair = 0;
	fixed specular = 0;
	#if USE_SPECULAR_ON // �߹�
		specular = pow(max(0,dot(worldNormal,halfDir)), _Gloss * 256);
		finalSpecularCol = _SpecularColor * _ShinnessMulti * specular * lightMaskCol.b ;
	#elif USE_HAIR_SPECULAR_ON //MATCAP �߹�
		finalSpecularCol_Hair = GetMatCapColor(i,tangentTransform,mainCol,lightMaskCol);

		finalColorRGB +=finalSpecularCol_Hair;
	#elif USE_ALL_SPECULAR_ON //MATCAP + �߹�
		specular = pow(max(0,dot(worldNormal,halfDir)), _Gloss * 256);
		finalSpecularCol = _SpecularColor * _ShinnessMulti * specular * lightMaskCol.b * (1-mainCol.a);
		finalSpecularCol_Hair = GetMatCapColor(i,tangentTransform,mainCol,lightMaskCol);

		finalColorRGB +=finalSpecularCol_Hair;
	#endif

	
	//===============================������======================================
	//��ͼ R ͨ�� *  ���� Rͨ�� ��ͬ����
	fixed diffuseMask = (halfLambert + (lightMaskCol.r) * i.vertexColor.r ) * 0.5;
	//fixed3 diffuseColor = (diffuseMask >= _LightArea) ? mainCol.rgb : shadowCol.rgb;
	fixed diffuseStep =  smoothstep(0,_ShadowWidthSmooth,saturate(diffuseMask - _LightArea));
	half3 finalDiffuseColor  = lerp(shadowCol,mainCol.rgb,diffuseStep);

	//===============================��Ե��=====================================
	half NDOTV = dot(worldNormal,viewDir);
	half _rim = 1 - saturate(abs(NDOTV));
	half3 rimColor =0;
	#if USE_RIM_LIGHT_ON
		half rim = pow(_rim,1 / _RimPower * 5 ) * _RimStrength;
		rimColor = rim * _RimColor;
		finalColorRGB += rimColor;
	#endif		

	//===========�ڶ����Ե���ڴ�����ƣ��������Ʊ�����ʱ�������===
	half secondRim = _rim;
	half3 secondRimColor = secondRim * _SecondRimColor * _SecondRimStrenth ;
	finalColorRGB += secondRimColor;

	// ==========�����Ե��
	#if _ArmorBodyRim
		half armorBodyRim = pow(_rim,2.5);
		half3 armorBodyRimColor = armorBodyRim *_ArmorBodyRimColor* _ArmorBodyRimStrenth;
		finalColorRGB += armorBodyRimColor;
	#endif	

    //cubmap
		fixed3 worldRefl = reflect(-viewDir, worldNormal);
		fixed3 cubeMap = texCUBElod(_CubeMap, float4(worldRefl, _CubeRoughness)) * _CubeReflTex_scale * lightMaskCol.r ;  //lightMaskCol.b
		finalColorRGB += cubeMap ;
            //fixed aa =lightMaskCol.b ;
		//fixed4 aa = fixed4(cubeMap, 1);

	//==============����������ɫ�����ɫ======
	fixed3 allLightColor = (finalDiffuseColor + finalSpecularCol) * LightColor;
	fixed4 finalColor = fixed4(finalColorRGB + allLightColor, 1);
	finalColor = finalColor * _MainColor;

	//�Է���
	finalColor = SetEmmisveColor(i,lightMaskCol,finalColor);
	//#ifdef USE_ALPHABLEND
		finalColor.a = _Alpha;
	//#endif
	//�����ܽ�
	finalColor = SetDissovle(i,fixed4(rimColor,1),finalColor);
	finalColor.a =_BodyAlPah;
	//return aa;
	return finalColor;
}

