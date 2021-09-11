Shader "Custom/HealthCircle" {
	Properties{
		//_MainTex("Sprite Texture", 2D) = "white"{}
		_FillColor("Fill Color", Color) = (1,1,1,1)
		_LineColor("Line Color", Color) = (1,1,1,1)
		_OuterRadius("Outer Radius", Range(0., 0.5)) = 1
		_InnerRadius("Inner Radius", Range(0., 0.5)) = 1
		_Smooth("Smooth", Range(0, 0.001)) = 1
		_LineWidth("Line Width", Range(0, 0.05)) = 1
		_SeparatorWidth("Seperator Width", Range(0, 10)) = 1
		_Progress("Progress", Range(0, 1)) = 1
		_SeperatorNum("Seperator Number", int) = 1
		_SetProgressValue("SetProgressValue" , int ) = 1
		
	}
		SubShader{
			Tags {
				"Queue" = "Transparent"
				"RenderType" = "Transparent"
				"IgnoreProjector" = "True"
			}

			Cull Off
			Lighting Off
			ZWrite Off
			ZTest Off
			Blend SrcAlpha OneMinusSrcAlpha

			pass {
				CGPROGRAM

				#pragma vertex vert 
				#pragma fragment frag 

				#include "UnityCG.cginc"

				sampler2D _MainTex;
				fixed4 _FillColor;
				fixed4 _LineColor;
				float4 _MainTex_ST;
				float _OuterRadius;
				float _InnerRadius;
				float _Smooth;
				float _LineWidth;
				float _SeparatorWidth;
				float _Progress;
				int _SeperatorNum;
				int _SetProgressValue;
				#define PI 3.1416
				#define PI2 6.2832
				
				struct v2f {
					float4 vertex : POSITION;
					float2 uv: TEXCOORD;
				};
			

				v2f vert(appdata_base v) {
					v2f o;

				    
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = v.texcoord;
					return o;
				}

				fixed DrawRingAntialiasing(float OutR, float InnR, float len, float amax) {//向外平滑
					fixed tmp1 = lerp(amax, 0, saturate((len - OutR) / _Smooth));
					fixed tmp2 = lerp(tmp1, 0, saturate((InnR - len) / _Smooth));
					return tmp2;
				}
		

				fixed4 frag(v2f i) : COLOR {
					float len = length(i.uv - float2(0.5, 0.5));
					fixed ret1 = DrawRingAntialiasing(_OuterRadius + _LineWidth, _OuterRadius, len, 1);//外环
					fixed ret2 = DrawRingAntialiasing(_InnerRadius, _InnerRadius - _LineWidth, len, 1);//内环
					fixed ret3 = DrawRingAntialiasing(_OuterRadius, _InnerRadius, len, _FillColor.a);//填充
		
					float c = ceil(i.uv.x -0.5);
		
					float prog =atan2(i.uv.x -0.5, i.uv.y-0.5) /PI ;
					
					half ret3Progress = 1-saturate(( (1-_Progress/ _SeperatorNum *_SetProgressValue )- prog) /_Smooth );
						half ret1Progress = 1-saturate(( (1-1.0/ _SeperatorNum *_SetProgressValue )- prog) /_Smooth );
					ret3 *=  ret3Progress  ;
			
					float tmp = prog * _SeperatorNum;
					
					float der = abs(tmp - (int)(tmp+0.5)) ;
	
					fixed ret4 = 1- saturate(der/(_Smooth*_SeperatorNum )- _SeparatorWidth) ;//隔线
					
			        half halfCircle = lerp(0, 1-saturate((len - _OuterRadius) / _Smooth), saturate((len - _InnerRadius) / _Smooth));
			        
					
					ret4 *= halfCircle; //取中间圆环
			      

					_FillColor.a = ret3 ;
					_LineColor.a = saturate(ret1 + ret2 + ret4) *ret1Progress;
			
				

		         	return  lerp(_FillColor, _LineColor, _LineColor.a);//两个透明色的混合按Line的alpha，这样隔线就在填充色之上
				}

				ENDCG
			}
		}
}
