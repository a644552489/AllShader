Shader "Unlit/PBRTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work


            #include "UnityCG.cginc"
            #include "include/FogCommon.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
        
                float4 pos : SV_POSITION;
                float3 posWS :TEXCOORD1;
                UBPA_FOG_COORDS(2)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.posWS = mul(unity_ObjectToWorld , v.vertex);
                UBPA_TRANSFER_FOG(o, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
    
                fixed4 col = tex2D(_MainTex, i.uv);

                UBPA_APPLY_FOG(i ,i.posWS , col);

                return col;
            }
            ENDCG
        }
    }
}
