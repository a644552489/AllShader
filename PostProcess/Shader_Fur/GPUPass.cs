using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GPUPass : MonoBehaviour
{
    [Range(1,10)]
    public int instanceCount= 10;
    [Range(0.1f,1)]
    public float OffsetLength = 1f;

    public AnimationCurve Clip  ;


     float[] offset = { 0.05f };
    float[] _EdgeFade = { 0.01f };
    public Material mat;
    public Mesh mesh;
    List<Matrix4x4> ts = new List<Matrix4x4>();



    void Update()
    {
        if (null != mat)
        {
            float delta =OffsetLength/ instanceCount ;
            mat.enableInstancing = true;
            ts.Clear();
            Matrix4x4 m = transform.localToWorldMatrix;
            if (offset.Length != instanceCount)
                offset = new float[instanceCount];
            if (_EdgeFade.Length != instanceCount)
                _EdgeFade = new float[instanceCount];
     

            MaterialPropertyBlock ms = new MaterialPropertyBlock();
            for (int i = 0; i < instanceCount; i++)
            {
                ts.Add(m);
                offset[i] =delta* i;
                _EdgeFade[i] = Clip.Evaluate( ((float)(i+1)) / (instanceCount));
          
            
            }
          
            ms.SetFloatArray("FUR_OFFSET" , offset);
            ms.SetFloatArray("_EdgeFade", _EdgeFade);

            Graphics.DrawMeshInstanced(mesh, 0, mat, ts, ms);
        }

        
    }
}
