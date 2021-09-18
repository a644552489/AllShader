using System.Linq;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class BaseCustomShaderGUI_V4 : ShaderGUI {

	protected Material target;
	protected MaterialEditor editor;
	protected MaterialProperty[] properties;

	static GUIContent staticLabel = new GUIContent();

    // Use this for initialization
    protected MaterialProperty FindProperty(string name)
    {
        if (!System.Array.Exists(properties, element => element.name == name))
            return null;
        return FindProperty(name, properties);
    }

    protected bool isInit = false;
    protected virtual void Init()
    {

    }
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        if (isInit)
        {
            isInit = true;
            Init();
        }
		this.editor = materialEditor;
		this.target = materialEditor.target as Material;	
		this.properties = properties;
		OnBaseGUI();
	}
	protected virtual void OnBaseGUI()
	{

    }
    protected virtual void DrawBaseGUI()
    {
        base.OnGUI(editor, properties);
    }
	protected static GUIContent MakeLabel (string text, string tooltip = null) {
		staticLabel.text = text;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}

	protected static GUIContent MakeLabel (
		MaterialProperty property, string tooltip = null
	) {
		staticLabel.text = property.displayName;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}

	protected void SetKeyword (string keyword, bool state) {
		if (state) {
			foreach (Material m in editor.targets) {
				m.EnableKeyword(keyword);
			}
		}
		else {
			foreach (Material m in editor.targets) {
				m.DisableKeyword(keyword);
			}
		}
	}

	protected bool IsKeywordEnabled (string keyword) {
		return target.IsKeywordEnabled(keyword);
	}

	protected void RecordAction (string label) {
		editor.RegisterPropertyChangeUndo(label);
	}

    #region Set Property Functions

    protected void SetFloatProperty(string propName, string label)
    {
        var property = FindProperty(propName);
        if (property != null) editor.FloatProperty(property, label);
    }

    protected void SetColorProperty(string propName, string label)
    {
        MaterialProperty property = FindProperty(propName);
        if (property == null) return;

        if (property.type == MaterialProperty.PropType.Color)
        {
            editor.ColorProperty(property, label);
        }
        else
        {
            // 保存的是线性值
            var v = property.vectorValue;
            Color linearColor = v;
            Color gammaColor = linearColor.gamma;

            EditorGUI.BeginChangeCheck();
            gammaColor = EditorGUILayout.ColorField(label, gammaColor);
            if (EditorGUI.EndChangeCheck())
            {
                linearColor = gammaColor.linear;
                property.vectorValue = linearColor;
            }
        }
    }

    protected void SetVectorProperty(string propName, string label)
    {
        MaterialProperty property = FindProperty(propName);
        if (property != null) editor.VectorProperty(property, label);
    }

    protected void SetRangeProperty(string propName, string label)
    {
        var property = FindProperty(propName);
        if (property != null) editor.RangeProperty(property, label);
    }

    protected void SetTextureProperty(string propName, string label)
    {
        var property = FindProperty(propName);
        if (property != null) editor.TextureProperty(property, label);
    }

    #endregion
}
