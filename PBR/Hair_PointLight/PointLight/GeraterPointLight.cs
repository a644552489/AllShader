using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;


[ExecuteInEditMode]
public class GeraterPointLight : MonoBehaviour
{
    // Start is called before the first frame update

    public List<Light> lights;
    
    int addLights = Shader.PropertyToID("_ADDITIONALLIGHTS");
    int lightPos = Shader.PropertyToID("_AdditionalLightsPosition");
    int lightColor = Shader.PropertyToID("_AdditionalLightsColor");
    int lightDistanceAtten = Shader.PropertyToID("_AdditionalLightsAttenuation");
    int lightSpotDirection = Shader.PropertyToID("_AdditionalLightsSpotDir");
    int lightOcclusionProbes = Shader.PropertyToID("_AdditionalLightsOcclusionProbes");
   
    Vector4[] m_AdditionalLightPositions;
    Vector4[] m_AdditionalLightColors;
    Vector4[] m_AdditionalLightAttenuations;
    Vector4[] m_AdditionalLightSpotDirections;
    Vector4[] m_AdditionalLightOcclusionProbeChannels;


    private void Awake()
    {
        //只用数据，避免影响到其他东西
        if (lights != null)
        {
            for (int i = 0; i < lights.Count; i++)
            {
                if (lights[i] == null) continue;
                lights[i].cullingMask = 0;
            }
        }
    }

    public GeraterPointLight()
    {
        int maxLight = 3;
        m_AdditionalLightPositions = new Vector4[maxLight];
        m_AdditionalLightColors = new Vector4[maxLight];
        m_AdditionalLightAttenuations = new Vector4[maxLight];
        m_AdditionalLightSpotDirections = new Vector4[maxLight];
        m_AdditionalLightOcclusionProbeChannels = new Vector4[maxLight];

    }
   
    private void Update()
    {
            if (lights == null )
               return;




            for (int i = 0; i < lights.Count; i++)
            {
                Light light = lights[i];
            


                InitializeAddLight(light, out m_AdditionalLightPositions[i],
                    out m_AdditionalLightColors[i],
                    out m_AdditionalLightAttenuations[i],
                    out m_AdditionalLightSpotDirections[i],
                    out m_AdditionalLightOcclusionProbeChannels[i]);
            
                
            }
            Shader.SetGlobalVectorArray(lightPos, m_AdditionalLightPositions);
            Shader.SetGlobalVectorArray(lightColor, m_AdditionalLightColors);
            Shader.SetGlobalVectorArray(lightDistanceAtten, m_AdditionalLightAttenuations);
            Shader.SetGlobalVectorArray(lightSpotDirection, m_AdditionalLightSpotDirections);
            Shader.SetGlobalVectorArray(lightOcclusionProbes, m_AdditionalLightOcclusionProbeChannels);


            Shader.SetGlobalInt(addLights, lights.Count);

          
        
    }
    private void OnDisable()
    {
        Shader.SetGlobalInt(addLights, -1);
    }
    private void OnDestroy()
    {
        Shader.SetGlobalInt(addLights, -1);
    }

    public void InitializeAddLight(Light light  ,
       out Vector4 lightPos ,
       out Vector4 lightColor ,
       out Vector4 lightAtten ,
       out Vector4 SpotDir,
       out Vector4 lightOcclusionProbeChannel )
    {
        lightPos = new Vector4(0, 0, 1, 0);
        lightColor = new Vector4(0, 0, 0, 1);
        lightAtten = new Vector4(0, 1, 0, 1);
        SpotDir = new Vector4(0, 0, 1, 0);
        lightOcclusionProbeChannel = new Vector4(0, 0, 0, 0);

        if (light == null)
            return;
        if (!light.isActiveAndEnabled)
            return;

        if (light.type == LightType.Directional)
        {
            Vector4 dir = -light.transform.localToWorldMatrix.GetColumn(2);
            lightPos = new Vector4(dir.x, dir.y, dir.z, 0.0f);
        }
        else {
            Vector4 pos = light.transform.localToWorldMatrix.GetColumn(3);
            lightPos = new Vector4(pos.x ,pos.y , pos.z , 1.0f);
           
        }

        lightColor = light.color  * light.intensity * light.bounceIntensity ;

        GetLightAttenuationAndSpotDirection(light.type , light.range , light.transform.localToWorldMatrix ,
            light.spotAngle , light?.innerSpotAngle ,
            out lightAtten , out SpotDir);

        if (light != null && light.bakingOutput.lightmapBakeType == LightmapBakeType.Mixed &&
            0 <= light.bakingOutput.occlusionMaskChannel &&
            light.bakingOutput.occlusionMaskChannel < 4)
        {
            lightOcclusionProbeChannel[light.bakingOutput.occlusionMaskChannel] = 1.0f;
        }

    }

    void GetLightAttenuationAndSpotDirection(LightType lightType,
        float lightRange,
       Matrix4x4 LightLocalToWorldMatrix,
       float spotAngle,
       float? innerAngle,
       out Vector4 lightAttenuation,
        out Vector4 lightSpotDir)
    {
        lightAttenuation = new Vector4(0, 1, 0, 1);
        lightSpotDir = new Vector4(0, 0, 1, 0);

        if (lightType != LightType.Directional)
        {
            float lightRangeSqr = lightRange * lightRange;
            float fadeStartDistanceSqr = 0.8f * 0.8f * lightRangeSqr;
            float fadeRangeSqr = (fadeStartDistanceSqr - lightRangeSqr);
            float oneOverFadeRangeSqr = 1.0f / fadeRangeSqr;
            float lightRangeSqrOverFadeRangeSqr = -lightRangeSqr / fadeRangeSqr;
            float oneOverLightRangeSqr = 1.0f / Mathf.Max(0.0001f, lightRange * lightRange);


            lightAttenuation.x = Application.isMobilePlatform || SystemInfo.graphicsDeviceType == GraphicsDeviceType.Switch ? oneOverFadeRangeSqr : oneOverLightRangeSqr;
            lightAttenuation.y = lightRangeSqrOverFadeRangeSqr;
        }

        if (lightType == LightType.Spot)
        {
            Vector4 dir = LightLocalToWorldMatrix.GetColumn(2);
            lightSpotDir = new Vector4(-dir.x, -dir.y, -dir.z, 0.0f);

            float cosOuterAngle = Mathf.Cos(Mathf.Deg2Rad * spotAngle * 0.5f);
            float cosInnerAngle;
            if (innerAngle.HasValue)
                cosInnerAngle = Mathf.Cos(innerAngle.Value * Mathf.Deg2Rad * 0.5f);
            else
                cosInnerAngle = Mathf.Cos((2.0f * Mathf.Atan(Mathf.Tan(spotAngle * 0.5f * Mathf.Deg2Rad) * (64.0f - 18.0f) / 64.0f)) * 0.5f);

            float smoothAngleRange = Mathf.Max(0.001f, cosInnerAngle - cosOuterAngle);
            float invAngleRange = 1.0f / smoothAngleRange;
            float add = -cosOuterAngle * invAngleRange;
            lightAttenuation.z = invAngleRange;
            lightAttenuation.w = add;



        }
    }

}
