Shader "Hidden/Actor/DepthOnly"
{
	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		Cull off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			uniform float4x4 _G_ShadowWorldToProj;

			struct Attributes
			{
				float4 positionOS : POSITION;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float2 depth : TEXCOORD0;
			};

			Varyings vert(Attributes input)
			{
				Varyings output;
				output.positionCS = mul(_G_ShadowWorldToProj, mul(unity_ObjectToWorld, input.positionOS));
				output.depth = output.positionCS.zw;
				return output;
			}

			float4 frag(Varyings input) : SV_Target
			{
				float depth = input.depth.x / input.depth.y;
				return depth.xxxx;
			}
			ENDCG
		}
	}
}
