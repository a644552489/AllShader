// Shader created with Shader Forge v1.38 
// Shader Forge (c) Neat Corporation / Joachim Holmer - http://www.acegikmo.com/shaderforge/
// Note: Manually altering this data may prevent you from opening it in Shader Forge
/*SF_DATA;ver:1.38;sub:START;pass:START;ps:flbk:,iptp:0,cusa:False,bamd:0,cgin:,lico:0,lgpr:1,limd:0,spmd:1,trmd:0,grmd:0,uamb:True,mssp:True,bkdf:False,hqlp:False,rprd:False,enco:False,rmgx:True,imps:True,rpth:0,vtps:0,hqsc:False,nrmq:1,nrsp:0,vomd:0,spxs:False,tesm:0,olmd:1,culm:2,bsrc:3,bdst:7,dpts:2,wrdp:False,dith:0,atcv:False,rfrpo:True,rfrpn:Refraction,coma:15,ufog:False,aust:True,igpj:True,qofs:0,qpre:3,rntp:2,fgom:False,fgoc:False,fgod:False,fgor:False,fgmd:0,fgcr:0.5780935,fgcg:0.5220588,fgcb:1,fgca:1,fgde:0.01,fgrn:0,fgrf:40,stcl:False,atwp:False,stva:128,stmr:255,stmw:255,stcp:6,stps:0,stfa:0,stfz:0,ofsf:0,ofsu:0,f2p0:False,fnsp:True,fnfb:False,fsmp:False;n:type:ShaderForge.SFN_Final,id:9361,x:33976,y:32619,varname:node_9361,prsc:2|normal-1883-OUT,custl-6634-OUT,alpha-893-OUT;n:type:ShaderForge.SFN_Fresnel,id:9245,x:31863,y:33390,cmnt:菲涅尔反射生成边缘光,varname:node_9245,prsc:2;n:type:ShaderForge.SFN_Power,id:9664,x:32785,y:33261,varname:node_9664,prsc:2|VAL-8095-OUT,EXP-5560-OUT;n:type:ShaderForge.SFN_Slider,id:6602,x:32070,y:33492,ptovrint:False,ptlb:RimLight,ptin:_RimLight,cmnt:边缘光范围,varname:node_6602,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0.8672428,max:5;n:type:ShaderForge.SFN_Add,id:4346,x:33286,y:32926,cmnt:菲涅尔十透明通道十调节 等于 不透明区域,varname:node_4346,prsc:2|A-7717-B,B-3414-OUT,C-6924-OUT,D-9217-OUT;n:type:ShaderForge.SFN_Slider,id:3414,x:32835,y:32872,ptovrint:False,ptlb:Transparent,ptin:_Transparent,cmnt:整体透明度调节,varname:node_3414,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:1,max:1;n:type:ShaderForge.SFN_Add,id:8556,x:33499,y:32763,varname:node_8556,prsc:2|A-4517-OUT,B-7717-B,C-6098-OUT,D-4555-OUT;n:type:ShaderForge.SFN_FaceSign,id:8399,x:31887,y:33175,cmnt:背面不需要边缘光,varname:node_8399,prsc:2,fstp:0;n:type:ShaderForge.SFN_Multiply,id:8095,x:32112,y:33304,varname:node_8095,prsc:2|A-8399-VFACE,B-9245-OUT;n:type:ShaderForge.SFN_Multiply,id:9217,x:32966,y:33134,cmnt:通道透明度调节,varname:node_9217,prsc:2|A-5468-OUT,B-9664-OUT;n:type:ShaderForge.SFN_Slider,id:5468,x:32611,y:33171,ptovrint:False,ptlb:RimTransparent,ptin:_RimTransparent,cmnt:通道透明度调节,varname:node_5468,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:0.4189994,max:1;n:type:ShaderForge.SFN_NormalVector,id:2636,x:32372,y:32113,prsc:2,pt:True;n:type:ShaderForge.SFN_HalfVector,id:4377,x:32372,y:32276,varname:node_4377,prsc:2;n:type:ShaderForge.SFN_Dot,id:2198,x:32596,y:32185,cmnt:生成高光,varname:node_2198,prsc:2,dt:0|A-2636-OUT,B-4377-OUT;n:type:ShaderForge.SFN_Slider,id:138,x:32332,y:32454,ptovrint:False,ptlb:Gloss,ptin:_Gloss,varname:node_138,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,min:0,cur:3.38003,max:5;n:type:ShaderForge.SFN_Power,id:6021,x:32933,y:32208,varname:node_6021,prsc:2|VAL-2198-OUT,EXP-4582-OUT;n:type:ShaderForge.SFN_Exp,id:4582,x:32748,y:32318,varname:node_4582,prsc:2,et:0|IN-138-OUT;n:type:ShaderForge.SFN_Clamp01,id:4592,x:33203,y:32227,varname:node_4592,prsc:2|IN-6021-OUT;n:type:ShaderForge.SFN_Color,id:9514,x:33331,y:32058,ptovrint:False,ptlb:SpecColor,ptin:_SpecColor,varname:node_9514,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0.5,c2:0.5,c3:0.5,c4:1;n:type:ShaderForge.SFN_Multiply,id:4517,x:33687,y:32262,varname:node_4517,prsc:2|A-9514-RGB,B-4592-OUT;n:type:ShaderForge.SFN_Clamp01,id:6634,x:33691,y:32763,varname:node_6634,prsc:2|IN-8556-OUT;n:type:ShaderForge.SFN_Clamp01,id:893,x:33582,y:32933,varname:node_893,prsc:2|IN-4346-OUT;n:type:ShaderForge.SFN_Multiply,id:6098,x:32859,y:32682,varname:node_6098,prsc:2|A-640-RGB,B-7878-RGB;n:type:ShaderForge.SFN_Tex2d,id:640,x:32265,y:32711,ptovrint:False,ptlb:Texture,ptin:_Texture,varname:node_640,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:0,isnm:False;n:type:ShaderForge.SFN_Exp,id:5560,x:32515,y:33382,varname:node_5560,prsc:2,et:0|IN-6602-OUT;n:type:ShaderForge.SFN_Tex2d,id:7717,x:32956,y:32462,ptovrint:False,ptlb:Normal,ptin:_Normal,cmnt:法线rg通道 透明b通道,varname:node_7717,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,ntxv:3,isnm:False;n:type:ShaderForge.SFN_Multiply,id:6924,x:32846,y:32966,varname:node_6924,prsc:2|A-640-A,B-2108-OUT;n:type:ShaderForge.SFN_Add,id:2890,x:32213,y:33095,cmnt:背面的通道透明度减弱0.4,varname:node_2890,prsc:2|A-3507-OUT,B-8399-VFACE;n:type:ShaderForge.SFN_Vector1,id:3507,x:31972,y:33023,varname:node_3507,prsc:2,v1:0.4;n:type:ShaderForge.SFN_Clamp01,id:2108,x:32430,y:33095,varname:node_2108,prsc:2|IN-2890-OUT;n:type:ShaderForge.SFN_Color,id:770,x:33072,y:33374,ptovrint:False,ptlb:RimColor,ptin:_RimColor,varname:node_770,prsc:2,glob:False,taghide:False,taghdr:False,tagprd:False,tagnsco:False,tagnrm:False,c1:0.5,c2:0.5,c3:0.5,c4:1;n:type:ShaderForge.SFN_Multiply,id:4555,x:33287,y:33222,varname:node_4555,prsc:2|A-9664-OUT,B-770-RGB;n:type:ShaderForge.SFN_Color,id:7878,x:32643,y:32780,ptovrint:False,ptlb:MainColor,ptin:_MainColor,varname:node_7878,prsc:2,glob:False,taghide:False,taghdr:True,tagprd:False,tagnsco:False,tagnrm:False,c1:0.5,c2:0.5,c3:0.5,c4:1;n:type:ShaderForge.SFN_Code,id:1883,x:33232,y:32425,varname:node_1883,prsc:2,code:bgBvAHIAbQBhAGwALgB4AHkAIAA9ACAAbgBvAHIAbQBhAGwALgB4AHkAIAAqACAAMgAgAC0AIAAxADsADQAKAG4AbwByAG0AYQBsAC4AegAgAD0AIABzAHEAcgB0ACgAMQAgAC0AIABzAGEAdAB1AHIAYQB0AGUAKABkAG8AdAAoAG4AbwByAG0AYQBsAC4AeAB5ACwAIABuAG8AcgBtAGEAbAAuAHgAeQApACkAKQA7AA0ACgByAGUAdAB1AHIAbgAgAG4AbwByAG0AYQBsADsA,output:2,fname:Function_node_1883,width:247,height:132,input:2,input_1_label:normal|A-7717-RGB;proporder:6602-3414-5468-138-9514-640-770-7878-7717;pass:END;sub:END;*/

Shader "Shader_Forge/SnowdropSkirt" {
    Properties {
        _RimLight ("RimLight", Range(0, 5)) = 0.8672428
        _Transparent ("Transparent", Range(0, 1)) = 1
        _RimTransparent ("RimTransparent", Range(0, 1)) = 0.4189994
        _Gloss ("Gloss", Range(0, 5)) = 3.38003
        _SpecColor ("SpecColor", Color) = (0.5,0.5,0.5,1)
        _Texture ("Texture", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (0.5,0.5,0.5,1)
        [HDR]_MainColor ("MainColor", Color) = (0.5,0.5,0.5,1)
        _Normal ("Normal", 2D) = "bump" {}
		_Alpha("Alpha", Range(0,1))=1

		// Bloom系数
		_BloomFactor("Bloom Factor", Range(0.04, 1)) = 0.04

        //[HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off
			ColorMask RGb

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			// -------------------------------------
			// 全局 keywords
			//#pragma multi_compile _ _USE_BLOOM_ALPHA

            #define UNITY_PASS_FORWARDBASE

            #include "UnityCG.cginc"

            //#pragma multi_compile_fwdbase
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal 
            #pragma target 3.0
            uniform float _RimLight;
            uniform float _Transparent;
            uniform float _RimTransparent;
            uniform float _Gloss;
            uniform float4 _SpecColor;
            uniform sampler2D _Texture; uniform float4 _Texture_ST;
            uniform sampler2D _Normal; uniform float4 _Normal_ST;
            uniform float4 _RimColor;
            uniform float4 _MainColor;

			fixed _Alpha;
            float3 Function_node_1883( float3 normal ){
            normal.xy = normal.xy * 2 - 1;
            normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
            return normal;
            }
            
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos( v.vertex );
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                i.normalDir = normalize(i.normalDir);
                i.normalDir *= faceSign;
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float4 _Normal_var = tex2D(_Normal,TRANSFORM_TEX(i.uv0, _Normal)); // 法线rg通道 透明b通道				
                float3 normalLocal = Function_node_1883( _Normal_var.rgb );
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals
                // float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                // float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float4 _Texture_var = tex2D(_Texture,TRANSFORM_TEX(i.uv0, _Texture));
                float node_9664 = pow((isFrontFace*(1.0-max(0,dot(normalDirection, viewDirection)))),_RimLight);
                float3 finalColor = saturate((_Normal_var.b+(_Texture_var.rgb*_MainColor.rgb)));
                return float4(finalColor,saturate((_Normal_var.b+_Transparent+(_Texture_var.a*_Alpha*saturate((0.4+isFrontFace))))));
            }
            ENDCG
        }

		//Add by zjj @2018/10/29
	Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend  One One
            Cull Off
            ZWrite Off
			ColorMask A
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			// -------------------------------------
			// 全局 keywords
			//#pragma multi_compile _ _USE_BLOOM_ALPHA

            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            //#pragma multi_compile_fwdbase
            #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal 
            #pragma target 3.0
            uniform float _RimLight;
            uniform float _Transparent;
            uniform float _RimTransparent;
            uniform float _Gloss;
            uniform float4 _SpecColor;
            uniform sampler2D _Texture; uniform float4 _Texture_ST;
            uniform sampler2D _Normal; uniform float4 _Normal_ST;
            uniform float4 _RimColor;
            uniform float4 _MainColor;
			uniform half _BloomFactor;

			fixed _Alpha;
            float3 Function_node_1883( float3 normal ){
            normal.xy = normal.xy * 2 - 1;
            normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
            return normal;
            }
            
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                //float4 posWorld : TEXCOORD1;
                //float3 normalDir : TEXCOORD2;
                //float3 tangentDir : TEXCOORD3;
                //float3 bitangentDir : TEXCOORD4;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                //o.normalDir = UnityObjectToWorldNormal(v.normal);
                //o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                //o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                //o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos( v.vertex );
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );

//#if _USE_BLOOM_ALPHA
//				float alpha = _BloomFactor;
//#else
				float4 _Normal_var = tex2D(_Normal, TRANSFORM_TEX(i.uv0, _Normal));
				float4 _Texture_var = tex2D(_Texture, TRANSFORM_TEX(i.uv0, _Texture));
				float alpha = saturate((_Normal_var.b + _Transparent + (_Texture_var.a*_Alpha*saturate((0.4 + isFrontFace)))));
//#endif
				return float4(0, 0, 0, alpha);
            }
            ENDCG
        }
    }
    //FallBack "Diffuse"
    //CustomEditor "ShaderForgeMaterialInspector"
}
