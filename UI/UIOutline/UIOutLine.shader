Shader "UI/UIOutLine"
 {
     Properties
     {
         [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
         
 
    

         _StencilComp ("Stencil Comparison", Float) =8
         _Stencil ("Stencil ID", Float) =0
         _StencilOp ("Stencil Operation", Float) =0
         _StencilWriteMask ("Stencil Write Mask", Float) =255
         _StencilReadMask ("Stencil Read Mask", Float) = 255
 
         _ColorMask ("Color Mask", Float) = 15
 
  

      //   _OutlineColor("OutlineColor" , Color)  = (1,1,1,1)
       //  _OutlineWidth("OutlineWidth" , float) = 1
     }
 
     SubShader
     {
         Tags
         {
             "Queue"="Transparent"
             "IgnoreProjector"="True"
             "RenderType"="Transparent"
             "PreviewType"="Plane"
             "CanUseSpriteAtlas"="True"
         }
 
         Stencil
         {
             Ref [_Stencil]
             Comp [_StencilComp]
             Pass [_StencilOp]
             ReadMask [_StencilReadMask]
             WriteMask [_StencilWriteMask]
         }
 
         Cull Off
         Lighting Off
         ZWrite Off
         ZTest [unity_GUIZTestMode]
         Blend SrcAlpha OneMinusSrcAlpha
         ColorMask [_ColorMask]
 
         Pass
         {
             Name "OUTLINE"
         CGPROGRAM
             #pragma vertex vert
             #pragma fragment frag
             #pragma target 2.0
 
             #include "UnityCG.cginc"
             #include "UnityUI.cginc"
 
             struct appdata_t
             {
                 float4 vertex   : POSITION;
                 float4 color    : COLOR;
                 float2 texcoord : TEXCOORD0;
                 half2 uv1 :TEXCOORD1;        
                 half2 uv2 :TEXCOORD2;
                 half3 uv3 :TEXCOORD3;
                 half4 normal :NORMAL;
                 float4 tangent  : TANGENT;
             };
 
             struct v2f
             {
                 float4 vertex   : SV_POSITION;
                 fixed4 color    : COLOR;
                 float2 texcoord  : TEXCOORD0;
                 float4 worldPosition : TEXCOORD4;
                half4 normal :NORMAL;
                float2 uv1 :TEXCOORD1;
                float2 uv2 :TEXCOORD2;
                float2 uv3 :TEXCOORD3;
                 half4 tangent :TANGENT;

             };
 
             sampler2D _MainTex;
             
             fixed4 _TextureSampleAdd;
             float4 _ClipRect;
             float4 _MainTex_TexelSize;

             float4 _OutlineColor;
             half _OutlineWidth;
 
             v2f vert(appdata_t v)
             {
                 v2f OUT;
        
                 OUT.worldPosition = v.vertex;
                 OUT.vertex = UnityObjectToClipPos(v.vertex);
                 OUT.tangent = v.tangent;
              //   OUT.tangent.xy = v.uv1;
                 OUT.uv1 = v.uv1;
                 OUT.uv2 = v.uv2;
                 OUT.uv3 = v.uv3;
                 OUT.normal = v.normal;

                 OUT.texcoord = v.texcoord;
                    
                 OUT.color = v.color ;
                 return OUT;
             }
             //范围验证 只返回 0 或 1 ，0表示在范围外，1表示范围内
         fixed IsInRect(float2 pPos, float2 pClipRectMin, float2 pClipRectMax)
			{
				pPos = step(pClipRectMin, pPos) * step(pPos, pClipRectMax);
				return pPos.x * pPos.y;
			}


        fixed SampleAlpha(int pIndex, v2f IN)
			{
				const fixed sinArray[12] = { 0, 0.5, 0.866, 1, 0.866, 0.5, 0, -0.5, -0.866, -1, -0.866, -0.5 };
				const fixed cosArray[12] = { 1, 0.866, 0.5, 0, -0.5, -0.866, -1, -0.866, -0.5, 0, 0.5, 0.866 };
				float2 pos = IN.texcoord + _MainTex_TexelSize.xy * float2(cosArray[pIndex], sinArray[pIndex]) * IN.normal.z;	//normal.z 存放 _OutlineWidth
				return IsInRect(pos, IN.uv1, IN.uv2) * (tex2D(_MainTex, pos) + _TextureSampleAdd).w * IN.tangent.w;		//tangent.w 存放 _OutlineColor.w
			}


             fixed4 frag(v2f IN) : SV_Target
             {
               fixed4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;
				if (IN.normal.z > 0)	//normal.z 存放 _OutlineWidth
				{
					color.w *= IsInRect(IN.texcoord, IN.uv1, IN.uv2);	//uv1 uv2 存着原始字的uv长方形区域大小
					half4 val = half4(IN.uv3.x, IN.uv3.y, IN.tangent.z, 0);		//uv3.xy tangent.z 分别存放着 _OutlineColor的rgb
 
					val.w += SampleAlpha(0, IN);
					val.w += SampleAlpha(1, IN);
					val.w += SampleAlpha(2, IN);
					val.w += SampleAlpha(3, IN);
					val.w += SampleAlpha(4, IN);
					val.w += SampleAlpha(5, IN);
					val.w += SampleAlpha(6, IN);
					val.w += SampleAlpha(7, IN);
					val.w += SampleAlpha(8, IN);
					val.w += SampleAlpha(9, IN);
					val.w += SampleAlpha(10, IN);
					val.w += SampleAlpha(11, IN);
 
					color = (val * (1.0 - color.a)) + (color * color.a);
                    color.a = saturate(color.a);
                    color.a *= IN.color.a;
                  
                }

               



                //RectMask2D 使用
                 color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                 
 
              
                 clip (color.a - 0.001);
 
 
                 return color;
             }
         ENDCG
         }
     }
 }