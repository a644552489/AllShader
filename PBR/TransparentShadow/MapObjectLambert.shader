Shader "Map/MapObjectLambert"
{
    Properties
    {
//        ambientColor("ambientColor",Color) = (0.3,0.3,0.3,0.3)
        _backShadowColorIntensity("_backShadowColorIntensity", Range(0.0, 1.0)) = 0.5
        _backShadowColor("_backShadowColor", Color) = (0, 0, 0, 0)
        _MainTex ("Texture", 2D) = "white" {}
        
        _ColorTop("SkyColor",Color) = (1,1,1,1)
        _ColorSide("EquatorColor",Color) = (1,1,1,1)
        _ColorDown("GroundColor",Color) = (1,1,1,1)
        
        _NormalMap("NormalMap", 2D) = "bump" {}
        _NormalIntensity("NormalIntensity", Range(0, 2)) = 1.0

        [HDR]_MainColor("MainColor", Color) = (1, 1, 1, 1)


        [Toggle(_UseFog)]_UseFog("Use Fog", float)=0

        [Header(Offset)]
        _OffsetFactor ("Offset Factor", Float) = 0
        _OffsetUnits ("Offset Units", Float) = 0

        [Header(CullAlpha)]
        _CutOff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _Mode("__mode", Float) = 0.0

        // Blending state
        [Header(Option)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("SrcBlend", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("DstBlend", Float) = 10
        [Enum(Off, 0, On, 1)]_ZWriteMode("ZWriteMode", float) = 1
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode", float) = 2
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode("ZTestMode", Float) = 4
        [Enum(UnityEngine.Rendering.ColorWriteMask)]_ColorMask("ColorMask", Float) = 15
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "Queue" = "Geometry"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWriteMode]
            ZTest[_ZTestMode]
            Cull[_CullMode]
            ColorMask[_ColorMask]
            Offset [_OffsetFactor], [_OffsetUnits]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_local __ _ALPHATEST_ON
            #pragma multi_compile_local __ _UseFog
            #pragma multi_compile _ _MAP_FOG
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Assets/Res/Shader/MapFogFunction.cginc"

            // DrawMesh开关
            #pragma multi_compile_local __ _ENABLE_DRAWMESH
            #ifdef _ENABLE_DRAWMESH
				#include "Assets/Res/Shader/MapDrawMeshFunction.cginc"
            #endif

           #include"Assets/Res/Shader/terrain/ColorChange.hlsl"

           

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;

                #ifdef _ENABLE_DRAWMESH
					// DrawMesh实例id
					uint insId : SV_InstanceID;
                #endif

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos :TEXCOORD1;
                float3 normalWorld : TEXCOORD2;
                float3 tangentWorld : TEXCOORD3;
                float3 binormalWorld : TEXCOORD4;
                float3 worNor:TEXCOORD6;
              
                SHADOW_COORDS(5)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NormalMap;
            half _NormalIntensity;

            half4 _MainColor;
            // half4 ambientColor;
            half4 _backShadowColor;
            half _backShadowColorIntensity;

            float3 _ColorTop, _ColorDown, _ColorSide;
            #ifdef _ALPHATEST_ON
			float _CutOff;
            #endif

            float4 _LightColor0;
            sampler2D _ScreenCopyTexture;
            float _TRANSPARENT_SHADOW;

            v2f vert(appdata v)
            {
                #ifdef _ENABLE_DRAWMESH
					// DrawMesh 矩阵转换
					SetInsObjectToWorld(v.insId);
                #endif

                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worNor = UnityObjectToWorldNormal(v.normal);
                o.normalWorld = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
                o.tangentWorld = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld)) * v.tangent.w;
       
                TRANSFER_SHADOW(o)
                return o;
            }


            float3 GradientSkyColor(float3 worNor)
            {
                float3 Ctop = saturate(worNor.y * _ColorTop);
                float3 Cdown = saturate(worNor.y * -1 * _ColorDown);
                float3 tempTop = saturate(worNor.y * 1);
                float3 tempDown = saturate(-worNor.y * 1);
                float3 combinetempColor = (1 - (tempTop + tempDown)) * _ColorSide;
                return Ctop + Cdown + combinetempColor;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                #ifdef _ENABLE_DRAWMESH
                // 设置光照，未知原因，DrawMesh的方式无法得到正确的光照
                SetLightDir();
            #endif
            float3 GradientColor = GradientSkyColor(i.worNor);
            half shadow = SHADOW_ATTENUATION(i);

            fixed4 col = tex2D(_MainTex, i.uv);
            col.rgb *= _MainColor.rgb;
            #ifdef _ALPHATEST_ON
                clip(col.a - _CutOff);
            #endif

            half3 normalWorld = normalize(i.normalWorld);
            half3 tangentWorld = normalize(i.tangentWorld);
            half3 binormalWorld = normalize(i.binormalWorld);

            fixed4 normalMap = tex2D(_NormalMap, i.uv);
            half3 normalData = UnpackNormal(normalMap);
            normalWorld = normalize(tangentWorld * normalData.x * _NormalIntensity
                + binormalWorld * normalData.y * _NormalIntensity
                + normalWorld * normalData.z);

            half3 lightWorld = normalize(_WorldSpaceLightPos0.xyz);
            half nol = dot(normalWorld, lightWorld);

            half diffuseTerm = nol * 0.5 + 0.5; //min(shadow, max(0.0, dot(normalWorld, lightWorld) *0.5 + 0.5));

            // half halfLambert = (diffuseTerm + 1.0) * 0.5;

            half3 diffuseColor = diffuseTerm * _LightColor0.xyz * col.rgb;

            //half3 ambientColor = half3(0.35, 0.35, 0.35) * col;
            half3 finalColor = diffuseColor * (nol * 0.5 + 0.5) + lerp(
                     GradientColor.rgb * col,  GradientColor.rgb * col * nol, _backShadowColorIntensity) + (1 - nol) *
                _backShadowColor;


            finalColor.rgb = MountainConrast(finalColor.rgb);
            finalColor.rgb = ColorChange(finalColor.rgb);
            //finalColor = pow(finalColor,0.7);
            // 
            // 
            // 



            //迷雾逻辑，请确保放在最后环节
            #if defined(_UseFog)&&defined(_MAP_FOG)
                finalColor.rgb = GetFogColor(i.worldPos.xyz,finalColor);
            #endif



                float4 shadowCoord = mul(unity_WorldToShadow[0], half4(i.worldPos.xyz, 1));
                float2 uv = (shadowCoord.xy / shadowCoord.w);


                if (uv.x < 0 || uv.x > 1 || uv.y < 0 || uv.y > 1) return half4(finalColor, col.a);

                float depth = tex2D(_ScreenCopyTexture, uv).r;

                shadowCoord.z /= shadowCoord.w;
                shadowCoord.z = saturate(shadowCoord.z);
                //半透明阴影
                float isShadow = depth < (shadowCoord.z + 0.001) ? 1.0 : 0.5;


                finalColor.rgb =lerp( finalColor.rgb , finalColor.rgb * isShadow , _TRANSPARENT_SHADOW);

           


                return half4(finalColor , col.a);
            }
            ENDCG
        }

        Pass//产生阴影的通道(物体透明也产生阴影)
        {
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #pragma multi_compile_local __ _ALPHATEST_ON
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldPos :TEXCOORD1;
                V2F_SHADOW_CASTER;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            #ifdef _ALPHATEST_ON
			float _CutOff;
            #endif

            v2f vert(appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                #ifdef _ALPHATEST_ON
					clip(col.a - _CutOff);
                #endif
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
    CustomEditor "MapObjShaderGUI"
}