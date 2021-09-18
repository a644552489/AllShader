Shader "ZShader/Toon/Toon_ActorBody_cubmap"
{
	Properties
	{
		_MainColor("MainColor",Color) = (1,1,1,1)
		_BodyAlPah("��ɫ͸����",Range(0,1)) = 1
		
		_MainTex ("��Ҫ��ͼ (RGB)", 2D) = "white" {}
		_ShadowTex("��Ӱ��ͼ (RGB)",2D) = "white" {}
		_ShadowColor("��Ӱ��ɫ",Color) = (1,1,1,1)

		_LightArea("��ӰӰ������",Range(0,1)) = 0.6
		_ShadowWidthSmooth("��Ӱƽ����",Range(0,0.1)) = 0.05

		//[Toggle(USE_LIGHTMASK_ON)] _USE_LIGHTMASK_ON("ʹ��Mask��ͼ",Float) = 0
		_LightMask("Mask��ͼ (RGBA)",2D) = "red" {}

		_LightMask_R("Mask��ͼ (R)",2D) = "white" {}
		_LightMask_G("Mask��ͼ (G)",2D) = "gray" {}
		_LightMask_B("Mask��ͼ (B)",2D) = "white" {}
		_LightMask_A("Mask��ͼ (A)",2D) = "black" {}

		_SpecularColor("�߹���ɫ",Color) = (1,1,1,1)
		_Gloss("�߹�Gloss",Range(0.001,5)) = 1
		_ShinnessMulti("�߹�ǿ��",Range(0,5)) = 1

		_HairMatCapTex("ͷ���Ŷ�",2D) = "black"{}
		_TweakUv("Ť��UV",Range(-0.5,0.5)) = 0
		_NormalMapForMatCap(" _NormalMapForMatCap",2D) = "bump" {}
		_MatcapColor("MatCap��ɫ",Color) = (0.5,0.5,0.5)

		//[Toggle(NORMAL_MAP_ON)] _UseNormalMap("ʹ�÷�����ͼ?",Float) = 0

		_BumpMap("Normal Map",2D) = "bump"{}
		_BumpScale("Normal Scale",Float) = 1
		
		//[Toggle(USE_RIM_LIGHT_ON)] USE_RIM_LIGHT_ON("ʹ�ñ�Ե��?",Float) = 0
		_RimColor("�ⷢ��_��ɫ",Color) = (0,0,0.5,1)
		_RimPower("�ⷢ��_��Ե",Range(0.001,3)) = 0.5 
		_RimStrength("�ⷢ��_ǿ��",Float) = 0.5

		//��C#������Ƶ�����
		_SecondRimColor("���� �ⷢ��",Color) = (1,1,1,1)
		_SecondRimStrenth("���� �ⷢ��",Range(0,1.0)) = 0

		//OutLine����ʹ��
		_Outline_Width ("Outline_Width", Float ) = 1
        _MaxOutLine ("_MaxOutLine", Range(0,5) ) = 2
        _MinOutLine ("_MinOutLine", Range(0,2) ) = 0.5
        _Outline_Color ("Outline_Color", Color) = (0.5,0.5,0.5,1)

		//����
		_EmissiveTex ("Emissive (RGB)", 2D) = "white" {}
		_EmissiveColor("EmissiveColor",Color) = (1,0,0,1)
		_EmissiveOffsetX ("Emissive (RGB) Offset x", Float) = 0
		_EmissiveOffsetY ("Emissive (RGB) Offset Y", Float) = 0
		_EmissiveStrength ("Emissive Strength", Float) = 1

		//����
		_SinEmissiveColor("_SinEmissiveColor",Color) = (1,0,0,1)
		_SinEmissiveStrength("_SinEmissiveStrength",Float) = 6
		_SinEmissiveFrequent ("Emissive Frequent", Float) = 0
		_Alpha("͸����",Float)=1
		_Outline_Alpha("��Ե͸����",Float)=1

		//==============================������༭���ã�����������=================================
		_IsUseFixedLight("ʹ�ù̶��ƹ�", Float) = 1.0
		_LightDir("�ƹⷽ��",Vector) = (0.5,0.5,0.5)
		_LightEular("�ƹ�ŷ����",Vector) = (45,10,0,0) //����ŷ���ǣ��ڱ༭����ת��Ϊ�ƹⷽ��

		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendMode ("Src Blend Mode", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendMode ("Dst Blend Mode", Float) = 0
		// [Toggle]_IsUI("�Ƿ�UI��",Float) = 0 
		// [Toggle]_IsUseDissolve("�Ƿ�ʹ���ܽ���Ч",Float) = 0 //�Ƿ�ʹ���ܽ���Ч��ʧ���Զ���UIʹ��
		//======================================================================================

		_CubeMap("Cube Map",CUBE) = "black" {}
		_CubeReflTex_scale("_CubeReflTex_scale",Range(0,1)) = 1
		_CubeRoughness("_CubeRoughness",Range(0,2)) = 0

		// Render State
		//[HideInInspector]_ColorMask("Color Mask", Float) = 15
	}
	SubShader
	{
		LOD 150
		Tags { "RenderType"="Opaque" "Queue"="AlphaTest"}
		//GrabPass{"_GlobalGrabTexture"}

		Pass
		{
			Stencil
			{
				Ref 0
				Comp Always
				Pass Replace
			}

			Tags{ "LightMode" = "ForwardBase"}
			//Blend [_SrcBlendMode] [_DstBlendMode]
        	Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			//ColorMask[_ColorMask]

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			#pragma fragmentoption ARB_precision_hint_fastest

			#pragma shader_feature USE_SHADOWCOLOR_MUL_TEXCOLOR
			#pragma shader_feature NORMAL_MAP_ON
			#pragma shader_feature USE_LIGHTMASK_OFF USE_COMBINE_CHANNEL_ON USE_SPLIT_CHANNEL_ON 
			//ֻʹ��Mat�߹⣬ͬʱʹ��Mat�߹������
			#pragma shader_feature USE_SPECULAR_ON USE_HAIR_SPECULAR_ON USE_ALL_SPECULAR_ON
			#pragma shader_feature USE_RIM_LIGHT_ON
			//����
			#pragma shader_feature _Emissve_Float_ON
			//���� / ����
			#pragma shader_feature _Emissve_SIN_ON
			
			#pragma multi_compile _NoneDissovle _UseDissovle _UseDissovleTwist
			//�����Ե��
			#pragma multi_compile _ _ArmorBodyRim
			#include "Toon_Actor_cubmap.cginc"
			ENDCG
		}

		Pass{
			Name "OUTLNIE"
			Cull Front
			Tags { "RenderType"="Opaque" "Queue"="AlphaTest"}
			Blend SrcAlpha OneMinusSrcAlpha
			//Blend [_SrcBlendMode] [_DstBlendMode]
			CGPROGRAM
			
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#pragma fragmentoption ARB_precision_hint_fastest

			#include "ToonOutLineCG.cginc"
			ENDCG
		}
	}

	SubShader
	{
		//�ض�100 ����Ϊ ר��Ϊ��������õ�
		//ȥ��NormalMap, ȥ���߹⣬ȥ����Ե��
		LOD 100
		Tags { "RenderType"="Opaque" "Queue"="AlphaTest"}	
		Pass
		{
			Tags{ "LightMode" = "ForwardBase"}
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			//ColorMask[_ColorMask]
        	
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex veryLowVert
			#pragma fragment veryLowfrag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			#pragma fragmentoption ARB_precision_hint_fastest

			#pragma shader_feature USE_SHADOWCOLOR_MUL_TEXCOLOR
			#pragma shader_feature USE_LIGHTMASK_OFF USE_COMBINE_CHANNEL_ON USE_SPLIT_CHANNEL_ON 
			//����
			#pragma shader_feature _Emissve_Float_ON
			//���� / ����
			#pragma shader_feature _Emissve_SIN_ON

			#pragma multi_compile _NoneDissovle _UseDissovle _UseDissovleTwist
			#include "Toon_ActorLow.cginc"
			ENDCG
		}
	
	}
	//Fallback "Legacy Shaders/Diffuse"
	CustomEditor "ToonActorShaderGUI_cubmap"
}
