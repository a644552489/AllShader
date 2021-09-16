Shader "Unlit/Decal"
{
    Properties
    {
        _MainTex ("Decal Texture", 2D) = "white" {}
        _NormalCutOff("角度切除",Range(0,180)) = 0.5
    }
    SubShader
    {
        Tags { "Queue" = "Geometry +1" }
       

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 screenUV :TEXCOORD1;
                float3 ray :TEXCOORD2;
                float3 eyeVec :TEXCOORD3;
                float3 worldForward :TEXCOORD4;
                float3 worldUp :TEXCOORD5;

                
                float4 vertex : SV_POSITION;
            };

            struct Projection
            {
                float2 screenPos;
                float3 posWorld;
                float2 localUV;

                float depth;
                float3 normal;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthNormalsTexture;
            half _NormalCutOff;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenUV = ComputeScreenPos(o.vertex);
                o.ray = UnityObjectToViewPos(v.vertex).xyz * float3(-1,-1,1);
                float4 posWorld = mul(unity_ObjectToWorld , v.vertex);
                o.eyeVec = posWorld.xyz - _WorldSpaceCameraPos;
                o.worldForward = mul((float3x3)unity_ObjectToWorld , float3(0,0,1));
                o.worldUp = mul((float3x3) unity_ObjectToWorld , float3(1,0,0));

                return o;
            }

            Projection CalculateProjection(float4 i_screenPos , float3 i_ray , float3 i_worldForward)
            {
                Projection proj = (Projection)0;
                proj.screenPos = i_screenPos.xy / i_screenPos.w;
                float3 surfaceNormal;
                float Depth;
                float4 encode = tex2D(_CameraDepthNormalsTexture , proj.screenPos);
                DecodeDepthNormal(encode , Depth , surfaceNormal);
                proj.normal = mul(half4(surfaceNormal,1.0) ,UNITY_MATRIX_V ).xyz;


                //取得世界坐标
                i_ray = i_ray *(_ProjectionParams.z / i_ray.z);
                float4 vpos = float4(i_ray * Depth ,1);
                float3 wpos = mul(unity_CameraToWorld , vpos).xyz;
               
                float4 viewpos = float4(unity_OrthoParams.x * (proj.screenPos.x*2-1) ,unity_OrthoParams.y * (proj.screenPos.y *2 -1) , Depth * (_ProjectionParams.z- _ProjectionParams.y) ,1);
                float3 worldpos = mul(unity_CameraToWorld , viewpos).xyz;
                proj.posWorld = (UNITY_MATRIX_P[3][3] * worldpos + (1-UNITY_MATRIX_P[3][3]) * wpos);
               
                
                float3 opos = mul(unity_WorldToObject , float4(proj.posWorld,1)).xyz;
                clip(float3(0.5,0.5,0.5) - abs(opos.xyz));
                
                float2 UnscaleUVs = float2(opos.xy + 0.5);

                proj.localUV = UnscaleUVs;

                half d = dot(proj.normal , normalize(-i_worldForward ));
                float Deg2Rad = 3.14159/180.0;
                clip(d - cos(Deg2Rad * _NormalCutOff));
               return proj;
                
            }

            fixed4 frag (v2f i) : SV_Target
            {
               Projection proj = CalculateProjection(i.screenUV ,i.ray , i.worldForward );
               
               float c = cos(_Time.y);
               float s = sin(_Time.y);
               float2x2 rot = float2x2(c , -s , s , c);
                proj.localUV = mul(rot , proj.localUV-0.5);
               float4 col = tex2D(_MainTex , proj.localUV+0.5);

             
                return col;
            }
            ENDCG
        }
    }
}
