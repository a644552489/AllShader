Shader "Unlit/Water"
{
    Properties
    {
   [NoScaleOffset][Normal][SingleLineTexture][Header(Maps)][Space(7)]_WavesNormal("Waves Normal", 2D) = "white" {}
		[Header(Settings)][Space(5)]_Color1("Color 1", Color) = (0,0,0,0)
		_Color2("Color 2", Color) = (0,0,0,0)
		_Opacity("Opacity", Range( 0 , 1)) = 0
		_Smoothness("Smoothness", Range( 0 , 1)) = 0
		_WavesTile("Waves Tile", Float) = 1
		_WavesSpeed("Waves Speed", Range( 0 , 1)) = 0
		_WavesNormalIntensity("Waves Normal Intensity", Range( 0 , 2)) = 1
		_FoamContrast("Foam Contrast", Range( 0 , 1)) = 0
		_FoamDistance("Foam Distance", Range( 0 , 5)) = 0
		_FoamDensity("Foam Density", Range( 0.1 , 1)) = 0.5
		
		_DepthDistance("Depth Distance", float) = 0

		_RefractionScale("Refraction Scale", Range( 0 , 1)) = 0.2
		_CoastOpacity("Coast Opacity", Range( 0 , 1)) = 0
    }
    SubShader
    {

     		Tags { "RenderType"="Transparent" "Queue"="Transparent" "DisableBatching"="False" }

	 
		Cull Back

		ZWrite Off

		


		GrabPass{"_GrabTex"}
        Pass
        {
            		Name "ForwardBase"
			Tags { "LightMode"="ForwardBase" }
			       

			Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
			#pragma multi_compile_instancing
			#pragma multi_compile_fwdbase

			#ifndef UNITY_PASS_FORWARDBASE
				#define UNITY_PASS_FORWARDBASE
			#endif

            #pragma vertex vert
            #pragma fragment frag
            // make fog work



		
            #include "UnityCG.cginc"
			#include "Lighting.cginc"
            #include "AutoLight.cginc"
			#include "UnityPBSLighting.cginc"


		

            struct appdata
            {
    				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
 
			
					float4 pos : SV_POSITION;
			
		
			
						SHADOW_COORDS(2)
				
			
					UNITY_FOG_COORDS(4)
			
				float4 tSpace0 : TEXCOORD5;
				float4 tSpace1 : TEXCOORD6;
				float4 tSpace2 : TEXCOORD7;
	
				float4 screenPos : TEXCOORD8;
	
				float4 eyeDepth : TEXCOORD9;
                float4 grabPos :TEXCOORD10;
				float3 sh :TEXCOORD11;
				float4 lmap :TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
              	UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 objectToViewPos = UnityObjectToViewPos(v.vertex.xyz);
				float eyeDepth = -objectToViewPos.z;
				o.eyeDepth.x = eyeDepth;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.eyeDepth.yzw = 0;
		

				v.vertex.w = 1;
				v.normal = v.normal;
				v.tangent = v.tangent;

				o.pos = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
				o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

#ifdef DYNAMICLIGHTMAP_ON
				o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif
#ifdef LIGHTMAP_ON
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
       

				#ifndef LIGHTMAP_ON
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						o.sh = 0;
						/*#ifdef VERTEXLIGHT_ON
						o.sh += Shade4PointLights (
							unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
							unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
							unity_4LightAtten0, worldPos, worldNormal);
						#endif
						o.sh = ShadeSHPerVertex (worldNormal, o.sh);*/
					#endif
				#endif



		     	TRANSFER_SHADOW(o);
		
	

	
					UNITY_TRANSFER_FOG(o,o.pos);
			
					o.screenPos = ComputeScreenPos(o.pos);
                o.grabPos = ComputeGrabScreenPos(o.pos);
                return o;
            }
		uniform float4 _Color2;
			sampler2D _CameraDepthTexture ;
			uniform float4 _CameraDepthTexture_TexelSize;
			uniform float _DepthDistance;
			uniform float4 _Color1;
			sampler2D _GrabTex ;
		uniform sampler2D _WavesNormal;
			uniform float _WavesSpeed;
			uniform float _WavesTile;
			uniform float _WavesNormalIntensity;
			uniform float _RefractionScale;
			uniform float _FoamDensity;
			uniform float _FoamContrast;
			uniform float _FoamDistance;
			uniform float _Smoothness;
			uniform float _Opacity;
			uniform float _CoastOpacity;
	

			float2 voronoihash61( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}

				float voronoi61( float2 v, float time, inout float2 id, inout float2 mr, float smoothness)
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash61( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 //		if( d<F1 ) {
						 //			F2 = F1;
						 			float h = smoothstep(0.0, 1.0, 0.5 + 0.5 * (F1 - d) / smoothness); 
									 F1 = lerp(F1, d, h) - smoothness * h * (1.0 - h);
									 mg = g; mr = r; id = o;
						 //		} else if( d<F2 ) {
						 //			F2 = d;
						
						 //		}
						 	}
						}
						return F1;
					}

	       float3 UnpackScaleNormal(float4 normal , float intensity)
           {
              float3 n =  UnpackNormal(normal);
              n.xy *= intensity;
              return n;
           }

            fixed4 frag (v2f IN) : SV_Target
            {
    				float3 WorldTangent = float3(IN.tSpace0.x,IN.tSpace1.x,IN.tSpace2.x);
				float3 WorldBiTangent = float3(IN.tSpace0.y,IN.tSpace1.y,IN.tSpace2.y);
				float3 WorldNormal = float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z);
				float3 worldPos = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                		UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)

                float4 ScreenPos = IN.screenPos / IN.screenPos.w;
                ScreenPos.z = (UNITY_NEAR_CLIP_VALUE >= 0 ) ? ScreenPos.z :ScreenPos.z * 0.5+0.5;
				float ZDepth =  LinearEyeDepth(ScreenPos.z);
			
                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture , ScreenPos.xy ));
				float DepthOffset = depth - ZDepth;

			
			    float offset =abs ( DepthOffset  / _DepthDistance);
				
            float4 waterColor =saturate( saturate(_Color2 * offset) + saturate(_Color1 *(1- offset)));

	
           float4  GrabPos = IN.grabPos / IN.grabPos.w;
       //     float4 GrabTex = tex2D(_GrabTex , GrabPos.xy);



            float waveSpeed = _WavesSpeed * 0.1 * _Time.y;
            
            float2 worldUV1 = float2(worldPos.x , worldPos.z) * _WavesTile + waveSpeed;
            float2 worldUV2 = float2(worldPos.x , worldPos.z ) *_WavesTile + (1- waveSpeed) ;

            float3 normal1 = UnpackScaleNormal(tex2D(_WavesNormal , worldUV1) , _WavesNormalIntensity) +  UnpackScaleNormal(tex2D(_WavesNormal , worldUV2) , _WavesNormalIntensity);
            float4 grabNormal = GrabPos  + float4((normal1 * _RefractionScale * 0.1) , 0.0);
            float4 GrabColor = tex2D(_GrabTex , grabNormal.xy);
            float eyeDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture , grabNormal.xy));



            float4 screenColor = GrabColor;
            waterColor = saturate( screenColor * waterColor);


            waveSpeed *=100;
            float foamDensity = 1.0 - _FoamDensity;
            float2 coord = float2(worldPos.x , worldPos.z ) * _WavesTile *50 ;
      
 
			float2 mr =0;
			float2 id =0 ;
            float voroi = voronoi61(coord ,  waveSpeed ,id ,mr  ,foamDensity);

            float depthDiff =abs( DepthOffset / _FoamDistance);
		
            float foam = saturate(pow(saturate(voroi) , (1 - _FoamContrast))+(1 - depthDiff) );

            float depthDiffOpacity = abs(DepthOffset/ _CoastOpacity);

			SurfaceOutputStandard o = (SurfaceOutputStandard)0;
			float4 c= 0;

            o.Albedo = (waterColor + foam).rgb;

			o.Metallic = 0;
			o.Normal = normal1;
			o.Smoothness = _Smoothness;
			o.Emission = 0;
			o.Occlusion = 1;
			o.Alpha = (_Opacity * saturate(depthDiffOpacity));


		   float3	lightDir =normalize( UnityWorldSpaceLightDir(worldPos));
			o.Normal = normalize(mul(o.Normal , float3x3(WorldTangent, WorldBiTangent, WorldNormal)));




			float3 R = reflect(-worldViewDir , o.Normal);			    

			float3 normalDirection = o.Normal;
			float3 halfDirection = normalize(lightDir + worldViewDir);







			UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir;		
	
		      
                UnityGIInput d;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, d);
                d.light = gi.light;
                d.worldPos = worldPos;
                d.worldViewDir = worldViewDir;
                d.atten = atten;

#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
				d.lightmapUV = IN.lmap;
#else
				d.lightmapUV = 0.0;
#endif

        
				#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					d.ambient = IN.sh;
				#else
					d.ambient.rgb = 0.0;
				#endif

                   d.probeHDR[0] = unity_SpecCube0_HDR;
                d.probeHDR[1] = unity_SpecCube1_HDR;
      			#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
					d.boxMin[0] = unity_SpecCube0_BoxMin;
				#endif
				#ifdef UNITY_SPECCUBE_BOX_PROJECTION
					d.boxMax[0] = unity_SpecCube0_BoxMax;
					d.probePosition[0] = unity_SpecCube0_ProbePosition;
					d.boxMax[1] = unity_SpecCube1_BoxMax;
					d.boxMin[1] = unity_SpecCube1_BoxMin;
					d.probePosition[1] = unity_SpecCube1_ProbePosition;
				#endif
   
				//	Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(o.Smoothness, d.worldViewDir, o.Normal, 0.04);
				//	gi = UnityGlobalIllumination(d, 1, o.Normal);

			//half3 indirDiffuse = ShadeSHPerPixel(o.Normal, d.ambient, d.worldPos);
			half3	indirDiffuse = SHEvalLinearL0L1(half4(o.Normal ,1.0) );

			
		
		 #ifdef UNITY_COLORSPACE_GAMMA
            indirDiffuse = LinearToGammaSpace(indirDiffuse);
        #endif
			gi.indirect.diffuse = indirDiffuse;

			c += LightingStandard( o, worldViewDir, gi );
		

	
		UNITY_APPLY_FOG(IN.fogCoord , c);
                return c;
            }
            ENDCG
        }

		
    }

}
