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
            int width = 1024 >> sampleDown;
            int height = 1024 >> sampleDown;
            rt = RenderTexture.GetTemporary(width, height, 0);
            
          

            // cmd.GetTemporaryRT(screenCopyID, 2048, 2048, 0, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
            cmd.SetShadowSamplingMode(rt, ShadowSamplingMode.RawDepth);
         
            cmd.Blit(BuiltinRenderTextureType.CurrentActive, rt);

           // cmd.Blit(screenCopyID, rt);
       
            cmd.SetGlobalTexture( screenCopyID , rt);

         

            mainLight.AddCommandBuffer(LightEvent.AfterShadowMap, cmd);


            Shader.SetGlobalFloat(TransparentShadow, 1);

        }
        

    }


    private void OnDisable()
    {
        
        Shader.SetGlobalFloat(TransparentShadow, 0);


        RenderTexture.ReleaseTemporary(rt);
        mainLight.RemoveCommandBuffer(LightEvent.AfterShadowMap, cmd);
        
        //GetComponent<Camera>().RemoveCommandBuffer(CameraEvent.BeforeForwardOpaque, cmd);
    }

}
