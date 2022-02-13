using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Text.RegularExpressions;
using UnityEngine.Rendering;
using System;

//�Զ���Ч��-������ʾͼƬ
internal class SingleLineDrawer : MaterialPropertyDrawer
{
    public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
    {
        editor.TexturePropertySingleLine(label, prop);
    }
    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return 0;
    }
}
//�Զ���Ч��-������ʾͼƬ
internal class FoldoutDrawer : MaterialPropertyDrawer
{
    bool showPosition;
    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {
        showPosition = EditorGUILayout.Foldout(showPosition, label);

        prop.floatValue = Convert.ToSingle(showPosition);

    
    }
    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return 0;
    }
}



public class CustomShaderGUI : ShaderGUI
{
    

    public class MaterialData
    {
        public MaterialProperty prop;
        public bool indentLevel = false;

    }


    static Dictionary<string, MaterialProperty> s_MaterialProperty = new Dictionary<string, MaterialProperty>();
    static List<MaterialData> s_List = new List<MaterialData>();


    static List<MaterialProperty> RenderModeList = new List<MaterialProperty>();



    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Shader shader = (materialEditor.target as Material).shader;
        s_List.Clear();
        s_MaterialProperty.Clear();
        for (int i = 0; i < properties.Length; i++)
        {
            var propertie = properties[i];
            s_MaterialProperty[propertie.name] = propertie;
            s_List.Add(new MaterialData() { prop = propertie, indentLevel = false });
           
            var attributes = shader.GetPropertyAttributes(i);// 获取头字符
           
            foreach (var item in attributes)
            {
              
                if (item.StartsWith("if"))
                {
                    Match match = Regex.Match(item, @"(\w+)\s*\((.*)\)");
                    if (match.Success)
                    {
                        
                        var name = match.Groups[2].Value.Trim();//if后的标识
                        if (s_MaterialProperty.TryGetValue(name, out var a))
                        {
                            if (a.floatValue == 0f)//说明未开启
                            {
                                //�����if��ǩ������Foldoutû��չ�������л���
                                //s_List.Count-1 指当前的存储的props
                                s_List.RemoveAt(s_List.Count - 1);
                                
                                break;
                            }
                            else
                                s_List[s_List.Count - 1].indentLevel = true; //被打开
                                
                        }
                    }
                   
                 
                    
                }

      

               


            }
        }

        RenderModeShow(materialEditor , properties);
      
        /*�������Ҫչ���ӽڵ���������������ֱ�ӵ���base����
         base.OnGUI(materialEditor, s_List.ToArray());*/

        PropertiesDefaultGUI(materialEditor, s_List);
    }
    private static int s_ControlHash = "EditorTextField".GetHashCode();


    public void PropertiesDefaultGUI(MaterialEditor materialEditor, List<MaterialData> props)
    {
        var f = materialEditor.GetType().GetField("m_InfoMessage", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
        if (f != null)
        {
            string m_InfoMessage = (string)f.GetValue(materialEditor);
            materialEditor.SetDefaultGUIWidths();
            if (m_InfoMessage != null)
            {
                EditorGUILayout.HelpBox(m_InfoMessage, MessageType.Info);
            }
            else
            {
                GUIUtility.GetControlID(s_ControlHash, FocusType.Passive, new Rect(0f, 0f, 0f, 0f));
            }
        }
       
        //�������е�����
        for (int i = 0; i < props.Count; i++)
        {
            MaterialProperty prop = props[i].prop;
            bool indentLevel = props[i].indentLevel;
            
            if ((prop.flags & (MaterialProperty.PropFlags.HideInInspector | MaterialProperty.PropFlags.PerRendererData)) == MaterialProperty.PropFlags.None)
            {
                float propertyHeight = materialEditor.GetPropertyHeight(prop, prop.displayName);
                Rect controlRect = EditorGUILayout.GetControlRect(true, propertyHeight, EditorStyles.layerMaskField);
                if (indentLevel) EditorGUI.indentLevel++;
                
                materialEditor.ShaderProperty(controlRect, prop, prop.displayName);
                
                if (indentLevel) EditorGUI.indentLevel--;
            }
         
        }
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        if (SupportedRenderingFeatures.active.editableMaterialRenderQueue)
        {
            materialEditor.RenderQueueField();
        }
        materialEditor.EnableInstancingField();
        materialEditor.DoubleSidedGIField();
    }



    string Clip = "_ALPHACLIP_ON";
    string ZWrite  ="_ZWriteMode";
    string SrcBlend = "_SrcBlend";
    string DstBlend = "_DstBlend";
    string CutOff = "_Cutoff";
    enum SurfaceType
    {
        Opaque,
        Transparent,
        AlphaClip

    }
    private SurfaceType surfaceType;
    void RenderModeShow(MaterialEditor editor, MaterialProperty[] props)
    {
        Material target = editor.target as Material;

        surfaceType = (SurfaceType)FindProperty("_RenderMode" , props).floatValue;


        if (surfaceType == SurfaceType.AlphaClip)
            {
                target.EnableKeyword(Clip);

            }
            else
            {
                target.DisableKeyword(Clip);
            }

            if (surfaceType != SurfaceType.Transparent)
            {
                target.SetInt(ZWrite, 1);
            }
            else
            {
                target.SetInt(ZWrite, 0);
            }

            switch (surfaceType)
            {
                case SurfaceType.Transparent:
                    target.SetInt(SrcBlend, (int)(UnityEngine.Rendering.BlendMode.SrcAlpha));
                    target.SetInt(DstBlend, (int)(UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha));
                    target.renderQueue = (int)RenderQueue.Transparent;

                    break;

                case SurfaceType.AlphaClip:
                    target.SetInt(SrcBlend, (int)(UnityEngine.Rendering.BlendMode.One));
                    target.SetInt(DstBlend, (int)(UnityEngine.Rendering.BlendMode.Zero));
                    AlphaClip();
                    target.renderQueue = (int)RenderQueue.Geometry;
                    break;

                default:
                    target.SetInt(SrcBlend, (int)(UnityEngine.Rendering.BlendMode.One));
                    target.SetInt(DstBlend, (int)(UnityEngine.Rendering.BlendMode.Zero));
                    target.renderQueue = (int)RenderQueue.Geometry;

                    break;
            }

        void AlphaClip()
        {
            if (target.IsKeywordEnabled(Clip))
            {
                MaterialProperty alphaClip = FindProperty(CutOff, props);
                editor.ShaderProperty(alphaClip, CutOff);
            }
        }

    }
 



}

