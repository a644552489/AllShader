using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using UnityEngine.Rendering;

public class ToonActorShaderGUI_V4 : BaseCustomShaderGUI_V4
{
    private static class Styles
    {
        public static GUIContent  EnvironmentMapText = new GUIContent("环境贴图", "");
    }

    public enum BlendMode
    {
        Opaque,
        Transparent
    }

    private static readonly string[] s_BlendNames = Enum.GetNames(typeof(BlendMode));
    MaterialProperty _Smoothness = null;
    MaterialProperty _RefColor = null;
    MaterialProperty _SpecMap = null;
    MaterialProperty _RefMap = null;
    MaterialProperty _SmoothnessMap = null;
    MaterialProperty _SRSMap = null;
    MaterialProperty _Light1Color = null;
    void FindProprty()
    {
         _Smoothness = FindProperty("_Smoothness");
         _RefColor = FindProperty("_Ref");
         _SpecMap = FindProperty("_SpecMap");
         _RefMap = FindProperty("_RefMap");
         _SmoothnessMap = FindProperty("_SmoothnessMap");
        _SRSMap = FindProperty("_SRSMap");
        _Light1Color = FindProperty("_Light1Color");
    }

    protected override void OnBaseGUI()
    {
        FindProprty();
        EditorGUILayout.BeginVertical();

        //this.DoRenderMode();
        this.DoMain();
        this.DoNormalMap();
        this.DoEnvironmentMap();

        this.DoLightAndShade();
        this.DoSpecular();
        this.DoEmissve();
        this.DoRimLight();

        this.DoOutline();

        this.DoLight();
        this.SRSOpen();
        this.DoOther();
       

        EditorGUILayout.EndVertical();
    }

    private void DoRenderMode()
    {
        BlendMode currentMode;
        MaterialProperty blendModeProp = FindProperty("_Mode");
        EditorGUI.BeginChangeCheck();
        {
            EditorGUI.showMixedValue = blendModeProp.hasMixedValue;
            currentMode = (BlendMode)blendModeProp.floatValue;

            EditorGUI.BeginChangeCheck();
            currentMode = (BlendMode)EditorGUILayout.Popup("Rendering Mode", (int)currentMode, s_BlendNames);
            if (EditorGUI.EndChangeCheck())
            {
                RecordAction("Rendering Mode");
                blendModeProp.floatValue = (float)currentMode;
            }

            EditorGUI.showMixedValue = false;
        }
        if (EditorGUI.EndChangeCheck())
        {
            foreach (var obj in blendModeProp.targets)
            {
                Material mat = obj as Material;
                switch (currentMode)
                {
                    case BlendMode.Opaque:
                        {
                            mat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                            mat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                            //mat.renderQueue = 2000;
                        }
                        break;
                    case BlendMode.Transparent:
                        {
                            mat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                            mat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                            //mat.renderQueue = 3000;
                        }
                        break;
                }
            }
        }
    }

    private void DoMain()
    {
        MaterialProperty mainTex = FindProperty("_MainTex");
        editor.TextureProperty(mainTex, "MainTex(RGB)");

        this.SetColorProperty("_MainColor", "Color(RGB)");
        this.SetRangeProperty("_BodyAlPah", "透明度");
        this.SetRangeProperty("_Cutoff", "Alpha Cut Off");

        // 判断是否头发
        var dyeColorProp = FindProperty("_DyeColor");
        if (dyeColorProp != null)
        {
            this.DoLightMask("R:阴影Mask G:高光区域 B:高光遮罩 A:发梢染色Mask");

            // 染色属性
            editor.ColorProperty(dyeColorProp, "染色颜色");
            this.SetRangeProperty("_DyeIntensity", "染色强度");

            // 发梢
            EditorGUI.BeginChangeCheck();
            bool isUseMaskDye = EditorGUILayout.Toggle("使用发梢染色", IsKeywordEnabled("_USE_MASK_DYE"));
            if (EditorGUI.EndChangeCheck())
            {
                RecordAction("MaskDye Change");
                SetKeyword("_USE_MASK_DYE", isUseMaskDye);
            }
            if (isUseMaskDye)
            {
                this.SetColorProperty("_MaskDyeColor", "发梢染色");
                this.SetRangeProperty("_MaskDyeIntensity", "发梢染色强度");
                this.SetRangeProperty("_MaskDyeColorIntensity", "发梢染色范围");
            }
        }
        else
        {
            // 判断是皮肤还是面部
            var skinColorProp = FindProperty("_SkinDyeColor");
            if (skinColorProp != null)
            {
                EditorGUILayout.HelpBox("顶点颜色R通道作为权重", MessageType.Info);
                editor.ColorProperty(skinColorProp, "皮肤颜色");

                this.DoLightMask("R:自发光Mask G:ToonKage B:反射Mask A:平滑度");

                EditorGUILayout.HelpBox("X:闲置 Y:自发光强度 Z:高光软硬 W:反射强度", MessageType.Info);
                this.SetVectorProperty("_BloomVector", "Bloom Vector");
            }
            else
            {
                this.DoLightMask("R:边缘光Mask G:ToonKage B:高光Mask");

                EditorGUILayout.HelpBox("X:闲置 Y:闲置 Z:高光软硬 W:闲置", MessageType.Info);
                this.SetVectorProperty("_BloomVector", "Bloom Vector");
            }
        }
    }

    private void DoNormalMap()
    {
        MaterialProperty property = FindProperty("_FaceDir");
        if (property != null)
        {
            editor.VectorProperty(property, "面部法线");
            float temp = property.vectorValue.x * property.vectorValue.y * property.vectorValue.z;
            if (Mathf.Abs(temp) <= Mathf.Epsilon)
                Debug.LogErrorFormat("面部法线不能全部填0，在移动设备会出现纯黑效果，通知美术修改");
        }

        property = FindProperty("_BumpMap");
        if (property != null)
        {
            var bumpTex = editor.TextureProperty(property, "法线贴图");
            SetKeyword("_USE_NORMAL_MAP", bumpTex != null);
            EditorGUILayout.Space();
        }
    }

    private void DoLightMask(string msg)
    {
        EditorGUILayout.HelpBox(msg, MessageType.Info);
        this.SetTextureProperty("_LightMaskTex", "Mask贴图(RGBA)");
    }

    private void DoEnvironmentMap()
    {
        MaterialProperty envMapProperty = FindProperty("_EnvironmentMap");
        if (envMapProperty != null)
        {
            editor.TexturePropertySingleLine(Styles.EnvironmentMapText, envMapProperty);
            EditorGUILayout.Space();
        }
    }

    #region Light And Shade

    private bool m_LightAndShadeFoldOut = true;

    private void DoLightAndShade()
    {
        m_LightAndShadeFoldOut = EditorGUILayout.Foldout(m_LightAndShadeFoldOut, "明暗设置");
        if (m_LightAndShadeFoldOut)
        {
            EditorGUI.BeginChangeCheck();
            bool isUseShadowMap = EditorGUILayout.Toggle("接受投影", IsKeywordEnabled("_USE_SHADOWMAP"));
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("_USE_SHADOWMAP", isUseShadowMap);
                EditorUtility.SetDirty(target);
            }

            var secondShadowColorProp = FindProperty("_SecondShadowColor");
            if (secondShadowColorProp == null)
            {
                this.SetColorProperty("_FirstShadowMultColor", "暗部颜色");
            }
            else
            {
                var skinShadowMultColorProp = FindProperty("_SkinShadowMultColor");
                if (skinShadowMultColorProp != null)
                {
                    EditorGUILayout.HelpBox("顶点颜色R通道作为权重", MessageType.Info);
                    editor.ColorProperty(skinShadowMultColorProp, "皮肤阴影色");
                }

                EditorGUILayout.LabelField("顶光:");
                {
                    EditorGUI.indentLevel++;
                    this.SetColorProperty("_FirstShadowMultColor", "暗部颜色");
                    this.SetRangeProperty("_Mix_BaseTexture", "暗部范围");
                    this.SetRangeProperty("_Mix_KageTexture", "暗部阀值");
                    EditorGUI.indentLevel--;
                }

                EditorGUILayout.LabelField("场景方向光:");
                {
                    EditorGUI.indentLevel++;
                    this.SetColorProperty("_SecondShadowColor", "暗部颜色");
                    this.SetRangeProperty("_Mix_BaseTexture2", "暗部范围");
                    this.SetRangeProperty("_Mix_KageTexture2", "暗部阀值");

                    this.SetTextureProperty("_ShadowMask", "阴影梯度图");
                    this.SetFloatProperty("_UseShadowMask", "阴影过度色强度");

                    EditorGUI.indentLevel--;
                }
            }

            EditorGUILayout.Space();
        }
    }

    #endregion

    #region 高光

    private bool m_SpecularFoldOut = true;

    private void DoSpecular()
    {
        m_SpecularFoldOut = EditorGUILayout.Foldout(m_SpecularFoldOut, "高光");
        if (m_SpecularFoldOut)
        {
            this.SetColorProperty("_MetalSpecColor", "高光颜色");

            this.SetFloatProperty("_PrimaryShift", "主光偏移值");
            this.SetFloatProperty("_SpecularMultiplier", "高光强度（主光）");
            this.SetColorProperty("_SpecularColor", "高光颜色（主光）");

            this.SetFloatProperty("_SecondaryShift", "副光偏移值");
            this.SetFloatProperty("_SpecularMultiplier2", "高光强度（副光）");
            this.SetFloatProperty("_SpecularColor2", "高光颜色（副光）");

            this.SetVectorProperty("_SpecularVector", "强度(X) 亮度上限(Y) 软硬(Z)");
            EditorGUILayout.Space();
        }
    }

    #endregion

    #region 自发光

    private bool m_EmissiveFoldOut = true;

    private bool _FloatEmissive;
    private bool IsUse_FloatEmissive
    {
        get { return IsKeywordEnabled("_Emissve_Float_ON"); }
    }

    private bool _SinEmissive;
    private bool isUse_SinEmissive
    {
        get { return IsKeywordEnabled("_Emissve_SIN_ON"); }
    }

    private void DoEmissve()
    {
        MaterialProperty maskTex = FindProperty("_EmissiveMaskTex");
        if (maskTex == null)
            return;

        m_EmissiveFoldOut = EditorGUILayout.Foldout(m_EmissiveFoldOut, "自发光");
        if (m_EmissiveFoldOut)
        {
            this.SetFloatProperty("_EmissionIntensity", "自发光强度");

            editor.TextureProperty(maskTex, "G：流动 A：闪动");

            EditorGUI.indentLevel++;
            EditorGUI.BeginChangeCheck();
            _FloatEmissive = EditorGUILayout.Toggle("流光自发光", IsUse_FloatEmissive);
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("_Emissve_Float_ON", _FloatEmissive);
            }
            EditorGUI.indentLevel++;
            //流光
            if (_FloatEmissive)
            {
                EditorGUILayout.HelpBox("流动!!", MessageType.Info);
                var EmissveTex = FindProperty("_EmissiveTex");
                editor.TextureProperty(EmissveTex, "Emissive (RGB)");

                this.SetColorProperty("_EmissiveColor", "EmissiveColor");

                var EmissiveOffsetX = FindProperty("_EmissiveOffsetX");
                editor.FloatProperty(EmissiveOffsetX, "Offset X");

                var EmissiveOffsetY = FindProperty("_EmissiveOffsetY");
                editor.FloatProperty(EmissiveOffsetY, "Offset Y");

                var _EmissiveStrength = FindProperty("_EmissiveStrength");
                editor.FloatProperty(_EmissiveStrength, "EmissiveStrength");
            }
            EditorGUI.indentLevel--;

            //闪动
            EditorGUI.BeginChangeCheck();
            _SinEmissive = EditorGUILayout.Toggle("闪动自发光", isUse_SinEmissive);
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("_Emissve_SIN_ON", _SinEmissive);
            }
            EditorGUI.indentLevel++;
            if (_SinEmissive)
            {
                EditorGUILayout.HelpBox("一闪一亮!!", MessageType.Info);
                this.SetColorProperty("_SinEmissiveColor", "EmissiveColor");

                var _EmissiveStrength = FindProperty("_SinEmissiveStrength");
                editor.FloatProperty(_EmissiveStrength, "EmissiveStrength");

                var EmissiveFrequent = FindProperty("_SinEmissiveFrequent");
                editor.FloatProperty(EmissiveFrequent, "频率");
            }

            EditorGUI.indentLevel--;
            EditorGUI.indentLevel--;
        }
    }

    #endregion

    #region 边缘光

    private bool m_RimLightFoldOut = true;

    private void DoRimLight()
    {
        m_RimLightFoldOut = EditorGUILayout.Foldout(m_RimLightFoldOut, "边缘光");
        if (m_RimLightFoldOut)
        {
            EditorGUI.indentLevel++;
            this.SetColorProperty("_RimColor", "边缘光颜色");
            this.SetRangeProperty("_RimSideWidth", "边缘光宽度");
            this.SetRangeProperty("_RimPower", "边缘光软硬");
            this.SetFloatProperty("_RimStrength", "边缘光强度");
            EditorGUI.indentLevel--;
            EditorGUILayout.Space();
        }
    }

    #endregion

    #region 外轮廓
    private bool m_OutlineFoldOut;
   

    private void DoOutline()
    {
        m_OutlineFoldOut = EditorGUILayout.Foldout(m_OutlineFoldOut, "外轮廓");
        if (m_OutlineFoldOut)
        {
            EditorGUI.indentLevel++;
            var outlineWidth = FindProperty("_Outline_Width");
            var _Farthest_Distance = FindProperty("_MaxOutLine");
            var _Nearest_Distance = FindProperty("_MinOutLine");

            this.SetColorProperty("_Outline_Color", "描边颜色");
            editor.FloatProperty(outlineWidth, "描边厚度");
            editor.RangeProperty(_Farthest_Distance, "最大轮廓倍数");
            editor.RangeProperty(_Nearest_Distance, "最小轮廓倍数");
            EditorGUI.indentLevel--;
        }
    }
    #endregion

    #region 其他，固定光照，队列

    private bool m_LightFoldOut = true;

    void DoLight()
    {
        m_LightFoldOut = EditorGUILayout.Foldout(m_LightFoldOut, "固定光照");
        if (m_LightFoldOut)
        {
            var useFixLightColorProp = FindProperty("_UseFixedLightColor");
            bool isUseFixLightColor = (useFixLightColorProp.floatValue - Mathf.Epsilon > 0.0) ? true : false;
            EditorGUI.BeginChangeCheck();
            bool temp = EditorGUILayout.Toggle("使用固定灯光颜色", isUseFixLightColor);
            if (EditorGUI.EndChangeCheck() && temp != isUseFixLightColor)
            {
                isUseFixLightColor = temp;
                target.SetFloat("_UseFixedLightColor", isUseFixLightColor ? 1.0f : 0.0f);
                EditorUtility.SetDirty(target);
            }
            if (isUseFixLightColor)
            {
                EditorGUI.indentLevel++;
                this.SetColorProperty("_FixedLightColor", "固定灯光颜色");
                EditorGUI.indentLevel--;
            }

            var isUseFixLightDirProp = FindProperty("_IsUseFixedLight");
            bool isUseFixLightDir = (isUseFixLightDirProp.floatValue - Mathf.Epsilon > 0.0) ? true : false;
            EditorGUI.BeginChangeCheck();
            temp = EditorGUILayout.Toggle("使用固定灯光方向", isUseFixLightDir);
            if (EditorGUI.EndChangeCheck() && temp != isUseFixLightDir)
            {
                isUseFixLightDir = temp;
                target.SetFloat("_IsUseFixedLight", isUseFixLightDir ? 1.0f : 0.0f);
                EditorUtility.SetDirty(target);
            }
            if (isUseFixLightDir)
            {
                EditorGUI.indentLevel++;
                this.SetFloatProperty("_FixedLightIntensity", "固定灯光强度");
                var lightEuler = FindProperty("_LightEular");
                editor.VectorProperty(lightEuler, "灯光欧拉角");
                var mat = Matrix4x4.Rotate(Quaternion.Euler(lightEuler.vectorValue));
                var lightVector = mat.MultiplyVector(Vector3.forward) * -1;
                target.SetVector("_FixedLightDir", lightVector);
                EditorGUI.indentLevel--;
            }
        }
    }

    private void DoOther()
    {
        editor.RenderQueueField();
    }

    #endregion

    #region SRS贴图
    private bool m_SRSMapFoldOut = true;
    private bool m_BlendSRS;
    private bool isUse_BlendSRS
    {
        get { return IsKeywordEnabled("_USEBLENDSRSMAP_ON"); }
    }
    private bool m_SRSMap ;
    private bool isUse_SRSMap
    {
        get { return IsKeywordEnabled("_USESRSMAP_ON"); }
    }
    void SRSOpen()
    {
        m_SRSMapFoldOut = EditorGUILayout.Foldout(m_SRSMapFoldOut, "SRS贴图");
        EditorGUI.indentLevel++;
        if (m_SRSMapFoldOut)
        {
            EditorGUI.BeginChangeCheck();
            m_SRSMap = EditorGUILayout.Toggle("SRS贴图模式", isUse_SRSMap);
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword("_USESRSMAP_ON", m_SRSMap);
            }
          
         
            if (m_SRSMap)
            {
                EditorGUI.indentLevel++;
                EditorGUI.BeginChangeCheck();
                m_BlendSRS = EditorGUILayout.Toggle("混合SRS贴图", isUse_BlendSRS);
                if (EditorGUI.EndChangeCheck())
                {
                    SetKeyword("_USEBLENDSRSMAP_ON", m_BlendSRS);
                }
                EditorGUI.indentLevel++;
                if (!isUse_BlendSRS)
                {
                    editor.TexturePropertySingleLine(new GUIContent("高光贴图"), _SpecMap);
                    editor.TexturePropertySingleLine(new GUIContent("反射贴图"), _RefMap);
                    editor.TexturePropertySingleLine(new GUIContent("平滑贴图"), _SmoothnessMap);
                }
                else
                {
                    editor.TexturePropertySingleLine(new GUIContent("高光(R)反射(G)平滑(B)混合贴图"), _SRSMap);
                }
                editor.RangeProperty(_Smoothness, "平滑度");
                editor.ColorProperty(_RefColor, "反射颜色");
                editor.ColorProperty(_Light1Color, "副光颜色");
                EditorGUI.indentLevel--;
            }
            EditorGUI.indentLevel--;
        }
        EditorGUI.indentLevel--;
    }

    #endregion
}
