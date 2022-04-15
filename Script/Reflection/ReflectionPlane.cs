using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class ReflectionPlane : MonoBehaviour
{
    private static readonly int REFLECTION_TEX_PROP_ID = Shader.PropertyToID("_ReflectionTex");

    private static MaterialPropertyBlock s_PropertyBlock = null;

    private Renderer m_Renderer;

    private void OnEnable()
    {
        m_Renderer = this.GetComponent<MeshRenderer>();

        if (m_Renderer)
            ReflectionManager.instance.AddPlane(this);
    }

    private void OnDisable()
    {
        ReflectionManager.instance.RemovePlane(this);
    }

    //public void SetReflectionTexture(RenderTexture texture)
    //{
    //    if (m_Renderer)
    //    {
    //        if (s_PropertyBlock == null)
    //            s_PropertyBlock = new MaterialPropertyBlock();

    //        m_Renderer.GetPropertyBlock(s_PropertyBlock);
    //        s_PropertyBlock.SetTexture(REFLECTION_TEX_PROP_ID, texture);
    //        m_Renderer.SetPropertyBlock(s_PropertyBlock);
    //    }
    //}
}
