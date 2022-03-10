using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class CaptureShadowMap : MonoBehaviour
{
 
     Light mainLight;
    CommandBuffer cmd;
    RenderTexture rt;

    [Range(0, 4)]
    public int sampleDown = 1;

    int screenCopyID = Shader.PropertyToID("_ScreenCopyTexture");
    int TransparentShadow = Shader.PropertyToID("_TRANSPARENT_SHADOW");
    private void OnEnable()
    {
        mainLight = GetComponent<Light>();
        if (mainLight != null)
        {

            cmd = new CommandBuffer();
            cmd.name = "Grab Screen ShadowMap";
            //   Vector2Int wh = GetShadowmapResolution();
           // int width = 1024 >> sampleDown;
           // int height = 1024 >> sampleDown;
           // rt = RenderTexture.GetTemporary(width, height, 0);
            
          

           // // cmd.GetTemporaryRT(screenCopyID, 2048, 2048, 0, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
           // cmd.SetShadowSamplingMode(rt, ShadowSamplingMode.RawDepth);
         
           // cmd.Blit(BuiltinRenderTextureType.CurrentActive, rt);

           //// cmd.Blit(screenCopyID, rt);
       
           // cmd.SetGlobalTexture( screenCopyID , rt);

            mainLight.AddCommandBuffer(LightEvent.AfterShadowMap, cmd);


            Shader.SetGlobalFloat(TransparentShadow, 1);

        }
        

    }

    private void LateUpdate()
    {
        if (cmd != null)
        {
            Vector2Int resolution = this.GetShadowmapResolution();
            if (rt != null && (rt.width != resolution.x || rt.height != resolution.y))
            {
                RenderTexture.ReleaseTemporary(rt);
                rt = null;
            }

            if (rt == null)
            {
                rt = RenderTexture.GetTemporary(resolution.x, resolution.y, 0);

                RenderTargetIdentifier shadowmap = BuiltinRenderTextureType.CurrentActive;
                cmd.Clear();
                if (SystemInfo.supportsRawShadowDepthSampling)
                    cmd.SetShadowSamplingMode(shadowmap, ShadowSamplingMode.RawDepth);
                cmd.Blit(shadowmap, rt);
                cmd.SetGlobalTexture(screenCopyID, rt);
            }
        }
    }

    private void OnDisable()
    {
        
        Shader.SetGlobalFloat(TransparentShadow, 0);


        RenderTexture.ReleaseTemporary(rt);
        mainLight.RemoveCommandBuffer(LightEvent.AfterShadowMap, cmd);
        
        //GetComponent<Camera>().RemoveCommandBuffer(CameraEvent.BeforeForwardOpaque, cmd);
    }

    /// <summary>
    /// 返回阴影图大小
    /// </summary>
    /// <returns></returns>
    private Vector2Int GetShadowmapResolution()
    {
        int resolution;
        if (mainLight.shadowResolution == LightShadowResolution.FromQualitySettings)
            resolution = (int)QualitySettings.shadowResolution;
        else
            resolution = (int)mainLight.shadowResolution;

        // 根据"https://docs.unity3d.com/Manual/shadow-mapping.html"计算出大小
        float scale = 0.25f * resolution;
        int width = Mathf.Min(Mathf.NextPowerOfTwo((int)(Screen.width * scale * 3.8f)), 4096);
        int height = Mathf.Min(Mathf.NextPowerOfTwo((int)(Screen.height * scale * 3.8f)), 4096);
        int result = Mathf.Max(width, width);
        return new Vector2Int(result, result);
    }
}
