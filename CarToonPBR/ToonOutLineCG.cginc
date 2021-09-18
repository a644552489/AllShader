// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

float3 _Outline_Color;
fixed _Outline_Width;
fixed _MaxOutLine;
fixed _MinOutLine;

fixed _Outline_Alpha=1;

struct VertexInput{
	float4 vertex :POSITION;
	float3 normal :NORMAL;
	float4 vertexColor :COLOR0;
	float2 uv :TEXCOORD0;
};
struct v2f{
	float4 pos:SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 worldPos :TEXCOORD1;
};
v2f vert(VertexInput v)
{
	v2f o;
	//float4 objPos = mul ( unity_ObjectToWorld, float4(0,0,0,1));
	//TODO :MASK的控制，应该考虑使用VertexColor
	//float dis = distance(objPos,_WorldSpaceCameraPos);
	//float outlineWidth = _Outline_Width  * smoothstep(_Nearest_Distance,_Farthest_Distance,dis) * v.vertexColor.g;
	float outlineWidth = _Outline_Width  * v.vertexColor.g;
	//将法线方向转换到视空间  
    //float3 vnormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal); 
    float3 vnormal = mul(v.normal, (float3x3)(transpose(UNITY_MATRIX_MV))); 
	float2 offset =  TransformViewToProjection(vnormal.xy); 
	//o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal * outlineWidth * 0.001,1));

	o.pos = UnityObjectToClipPos(float4(v.vertex.xyz, 1));
	
	o.pos.xy += offset* outlineWidth *0.001 * clamp(UNITY_Z_0_FAR_FROM_CLIPSPACE(o.pos.z),_MinOutLine,_MaxOutLine);
	 //+ v.normal * outlineWidth * 0.001
	o.uv = v.uv;
	o.worldPos = mul(unity_ObjectToWorld,v.vertex);
	return o;
}
float4 frag(v2f i):SV_TARGET
{
	return float4(_Outline_Color, _Outline_Alpha);
}

float4 dissolveFrag(v2f i):SV_TARGET
{
	fixed4 finalColor = fixed4(_Outline_Color,_Outline_Alpha);
	#if _HeightDissovleOn 
	finalColor = SetHeightDissovle(finalColor,i.uv,i.worldPos);
	#endif
	return finalColor;
}