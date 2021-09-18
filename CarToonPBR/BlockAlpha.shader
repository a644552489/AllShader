Shader "ZShader/Actor/BlockAlpha"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AlphaTex("AlphaTex",2D) = "white" {}
		_AlphaPower("Alpha",Range(0,1)) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 alphaTexuv:TEXCOORD1;
				float4 vertex : SV_POSITION;
				float3 worldpos :TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			float _AlphaPower;
			sampler2D _AlphaTex;
			float4 _AlphaTex_ST;
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.alphaTexuv = ComputeScreenPos(o.vertex);
				o.worldpos = mul(unity_ObjectToWorld,float4(0,0,0,1));
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				
				fixed4 alphaTex = tex2D(_AlphaTex,i.alphaTexuv.xy/i.alphaTexuv.w * _AlphaTex_ST.xy*distance(_WorldSpaceCameraPos.xyz,i.worldpos));
				if(alphaTex.r <= 0.1)
					alphaTex.r +=0.5;
				col.a = (alphaTex.r) * _AlphaPower;
				return col;
			}
			ENDCG
		}
	}
}
