using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


[ExecuteInEditMode]
public class ExponentialHeightFogCtrl : MonoBehaviour
{
    public Transform Fogcam = null;
    // 雾 1

    //--- 增加一个下迷雾总开关 cyh
    public bool fogToggle = false;



    [SerializeField]
    [Range(0.0f, 1f)]
    private float m_fogDensity = 0.02f;
    public float fogDensity {
        get {
            return fogToggle ? m_fogDensity : 0;
        }
    }

    //[Range(0.0f,1f)]
    //public float fogDensity = 0.02f; // This is the global density factor, which can be thought of as the fog layer's thickness.


    [Range(0.001f, 1f)]
    public float fogHeightFalloff = 0.2f; // Height density factor, controls how the density increases as height decreases. Smaller values make the transition larger.


    public float fogHeight = 0.0f;

    // 雾 2
    [SerializeField]
    [Range(0.0f, 1f)]
    private float m_fogDensity2 = 0.02f;
    public float fogDensity2
    {
        get
        {
            return fogToggle ? m_fogDensity2 : 0;
        }
    }

    //[Range(0.0f, 1f)]
    //public float fogDensity2 = 0.02f;


    [Range(0.001f, 1f)]
    public float fogHeightFalloff2 = 0.2f;


    public float fogHeight2;


    [ColorUsage(false)]
    public Color fogInscatteringColor = new Color(0.447f, 0.639f, 1.0f); // Sets the inscattering color for the fog. Essentially, this is the fog's primary color.

    [Range(0.0f, 1.0f)]
    public float fogMaxOpacity = 1.0f; // This controls the maximum opacity of the fog. A value of 1 means the fog will be completely opaque, while 0 means the fog will be essentially invisible.
    public float FogMaxOpacity
    {
        get
        {
             return fogToggle ? fogMaxOpacity : 0;
        }
    }

    [Range(0.0f, 5000.0f)]
    public float startDistance = 0.0f; // Distance from the camera that the fog will start.

    [Range(0.0f, 20000000.0f)]
    public float fogCutoffDistance = 0.0f;


    public Transform dirLight = null;
    [Range(2.0f, 64.0f)]

    public float directionalInscatteringExponent = 4.0f; // Controls the size of the directional inscattering cone, which is used to approximate inscattering from a directional light source.


    public float directionalInscatteringStartDistance = 0.0f; // Controls the start distance from the viewer of the directional inscattering, which is used to approximate inscattering from a directional light.
    [ColorUsage(false)]

    public Color directionalInscatteringColor = new Color(0.25f, 0.25f, 0.125f); // Sets the color for directional inscattering, used to approximate inscattering from a directional light. This is similar to adjusting the simulated color of a directional light source.
    [Range(0.0f, 10.0f)]

    public float directionalInscatteringIntensity = 1.0f;

    public Texture2D noiseTex;
    public Color CloudColor = new Color(1,1,1,1);

    [Range(1.0f , 5.0f)]
    public float uvScale = 1.0f;
    [Range(-1.0f, 1.0f)]
    public float speedX = 0.5f;
    [Range(-1.0f, 1.0f)]
    public float speedY = 0.5f;
    [Range(-10.0f, -0.1f)]
    public float fogPosY = -1.0f; 
    [Range(0.0f, 1.0f)]
    public float fogCloudIntensity = 1.0f;
    [Range(0.0f ,1.0f)]
    public float visibleCloudIntensity = 0.0f;
    public Vector4 _CloudParams;
  

    [Space(30)]
    [Header("环境光烘培")]
    public Transform GiveLightForMe =null;

    public Color EnvimentColorTop = Color.white;
    public Color EnvimentColorCenter = Color.white;
    public Color EnvimentColorDown = Color.white;
    public bool UseCustomBake = false;
    public float RealTimeLightIntesity = 1.0f;
    public Color LightColor = new Color(1,1,1,1);

    Camera cam;
    [HideInInspector]
    public bool isCopyNew = true;
    //public Texture2D texture;
    public Cubemap input_cubemap;
    public Vector4[] coefficients ;

    [Range(1,2)]
    public float _CHARACTERLIGHTSTRENGTH = 1.2f; 


    // Update is called once per frame
    void Update()
    {
        const float USELESS_VALUE = 0.0f;

        if (Fogcam != null && dirLight != null)
        {
            var ExponentialFogParameters = new Vector4(RayOriginTerm(fogDensity, fogHeightFalloff, fogHeight, Fogcam), fogHeightFalloff, USELESS_VALUE, startDistance);
            var ExponentialFogParameters2 = new Vector4(RayOriginTerm(fogDensity2, fogHeightFalloff2, fogHeight2, Fogcam), fogHeightFalloff2, fogDensity2, fogHeight2);
            var ExponentialFogParameters3 = new Vector4(fogDensity, fogHeight, USELESS_VALUE, fogCutoffDistance);
            var DirectionalInscatteringColor = new Vector4(
                directionalInscatteringIntensity * directionalInscatteringColor.r,
                directionalInscatteringIntensity * directionalInscatteringColor.g,
                directionalInscatteringIntensity * directionalInscatteringColor.b,
                directionalInscatteringExponent
            );
            var InscatteringLightDirection = new Vector4(
                -dirLight.forward.x,
                -dirLight.forward.y,
                -dirLight.forward.z,
                directionalInscatteringStartDistance
            );
            var ExponentialFogColorParameter = new Vector4(
                fogInscatteringColor.r,
                fogInscatteringColor.g,
                fogInscatteringColor.b,
                1.0f - FogMaxOpacity
            );

            Shader.SetGlobalVector(nameof(ExponentialFogParameters), ExponentialFogParameters);
            Shader.SetGlobalVector(nameof(ExponentialFogParameters2), ExponentialFogParameters2);
            Shader.SetGlobalVector(nameof(ExponentialFogParameters3), ExponentialFogParameters3);
            Shader.SetGlobalVector(nameof(DirectionalInscatteringColor), DirectionalInscatteringColor);
            Shader.SetGlobalVector(nameof(InscatteringLightDirection), InscatteringLightDirection);
            Shader.SetGlobalVector(nameof(ExponentialFogColorParameter), ExponentialFogColorParameter);
            Shader.SetGlobalTexture("_FOGNOISETEX", noiseTex);
            Shader.SetGlobalColor("_CLOUDCOLOR", CloudColor);
            Shader.SetGlobalVector("_FOGFLOWPARAMS", new Vector4(uvScale , speedX , speedY , fogPosY));
            Shader.SetGlobalVector("_FOGFLOWPARAMS1", new Vector4(fogCloudIntensity , visibleCloudIntensity,0,0));
            Shader.SetGlobalVector("_CloudParams" ,_CloudParams );
            Shader.SetGlobalFloat(nameof(_CHARACTERLIGHTSTRENGTH) , _CHARACTERLIGHTSTRENGTH);
        }

        SetSHValue();

    }

    private static float RayOriginTerm(float density, float heightFalloff, float heightOffset,Transform cam)
    {
        float exponent = heightFalloff * (cam.position.y - heightOffset);
        return density * Mathf.Pow(2.0f, - exponent);
    }


    void Start()
    {
        if (!Application.isPlaying)
        {
            setSH9Global();
        }
 

    }
    private void OnEnable()
    {
        Shader.EnableKeyword("EMANLE_FOG");
        OnValidate();
    }

    private void OnDisable()
    {
        Shader.DisableKeyword("EMANLE_FOG");
    }

    private void OnValidate()
    {
        if (UseCustomBake)
        {
            Shader.EnableKeyword("USE_CUSTOM_BAKE");
        }
        else
        {
            Shader.DisableKeyword("USE_CUSTOM_BAKE");
        }
    }

    void SetSHValue()
    {
        if (GiveLightForMe != null)
        {
            Shader.SetGlobalVector("_RolanLightDir", -GiveLightForMe.forward);
            Shader.SetGlobalColor("_RolanLightColor", LightColor * RealTimeLightIntesity);
        }
        Shader.SetGlobalColor("EnvimentColorTop", EnvimentColorTop);
        Shader.SetGlobalColor("EnvimentColorCenter", EnvimentColorCenter);
        Shader.SetGlobalColor("EnvimentColorDown", EnvimentColorDown);

    }


    #region 环境光
    public void setSH9Global()
    {
        if(coefficients == null)    return;

        for (int i = 0; i < 9; ++i)
        {
            string param = "g_sph" + i.ToString();
            Shader.SetGlobalVector(param, coefficients[i]);
        }
        input_cubemap = null;
        
    }

    public Cubemap CopyFromEnvMap()
    {
        if (null == cam)
        {

        }

        GameObject obj = new GameObject();
        obj.hideFlags = HideFlags.HideAndDontSave;
        cam = obj.AddComponent<Camera>();
        cam.cullingMask = 0;
        Skybox sb = obj.AddComponent<Skybox>();
        sb.material = new Material(Shader.Find("Skybox/Cubemap"));
        sb.material.SetTexture("_Tex", input_cubemap);
        cam.enabled = false;

        Cubemap cm = new Cubemap(512, TextureFormat.RGBA32, false);
        cam.RenderToCubemap(cm);
        GameObject.DestroyImmediate(obj);
        return cm;
    }

    public void ModifyTextureReadable()
    {
#if UNITY_EDITOR
        string path = AssetDatabase.GetAssetPath(input_cubemap);
        if (null == path || path.Length == 0)
        {
            return;
        }
        TextureImporter textureImporter = AssetImporter.GetAtPath(path) as TextureImporter;
        if (null == textureImporter)
            return;
        textureImporter.isReadable = true;
        textureImporter.SaveAndReimport();
#endif
    }

    public static int GetTexelIndexFromDirection(Vector3 dir, int cubemap_size)
    {
        float u = 0, v = 0;

        int f = FindFace(dir);

        switch (f)
        {
            case 0:
                dir.z /= dir.x;
                dir.y /= dir.x;
                u = (dir.z - 1.0f) * -0.5f;
                v = (dir.y - 1.0f) * -0.5f;
                break;

            case 1:
                dir.z /= -dir.x;
                dir.y /= -dir.x;
                u = (dir.z + 1.0f) * 0.5f;
                v = (dir.y - 1.0f) * -0.5f;
                break;

            case 2:
                dir.x /= dir.y;
                dir.z /= dir.y;
                u = (dir.x + 1.0f) * 0.5f;
                v = (dir.z + 1.0f) * 0.5f;
                break;

            case 3:
                dir.x /= -dir.y;
                dir.z /= -dir.y;
                u = (dir.x + 1.0f) * 0.5f;
                v = (dir.z - 1.0f) * -0.5f;
                break;

            case 4:
                dir.x /= dir.z;
                dir.y /= dir.z;
                u = (dir.x + 1.0f) * 0.5f;
                v = (dir.y - 1.0f) * -0.5f;
                break;

            case 5:
                dir.x /= -dir.z;
                dir.y /= -dir.z;
                u = (dir.x - 1.0f) * -0.5f;
                v = (dir.y - 1.0f) * -0.5f;
                break;
        }

        if (v == 1.0f) v = 0.999999f;
        if (u == 1.0f) u = 0.999999f;

        int index = (int)(v * cubemap_size) * cubemap_size + (int)(u * cubemap_size);

        return index;
    }

    public bool CPU_Project_MonteCarlo_9Coeff(Cubemap input, Vector4[] output, int sample_count)
    {
        if (output.Length != 9)
        {
            Debug.LogWarning("output size must be 9 for 9 coefficients");
            return false;
        }
        //cache the cubemap faces
        List<Color[]> faces = new List<Color[]>();
        for (int f = 0; f < 6; ++f)
        {
            faces.Add(input.GetPixels((CubemapFace)f, 0));
        }

        for (int c = 0; c < 9; ++c)
        {
            for (int s = 0; s < sample_count; ++s)
            {
                Vector3 dir = Random.onUnitSphere;
                int index = GetTexelIndexFromDirection(dir, input.height);
                int face = FindFace(dir);

                //read the radiance texel
                Color radiance = faces[face][index];

                //compute shperical harmonic
                float sh = SphericalHarmonicsBasis1.Eval1[c](dir);

                output[c].x += radiance.r * sh;
                output[c].y += radiance.g * sh;
                output[c].z += radiance.b * sh;
                output[c].w += radiance.a * sh;
            }
            output[c].x = output[c].x * 4.0f * Mathf.PI / (float)sample_count;
            output[c].y = output[c].y * 4.0f * Mathf.PI / (float)sample_count;
            output[c].z = output[c].z * 4.0f * Mathf.PI / (float)sample_count;
            output[c].w = output[c].w * 4.0f * Mathf.PI / (float)sample_count;
        }
        return true;
    }

    public delegate float SH_Base1(Vector3 v);

    public class SphericalHarmonicsBasis1
    {
        public static float Y0(Vector3 v)
        {
            return 0.2820947917f;
        }

        public static float Y1(Vector3 v)
        {
            return 0.4886025119f * v.y;
        }

        public static float Y2(Vector3 v)
        {
            return 0.4886025119f * v.z;
        }

        public static float Y3(Vector3 v)
        {
            return 0.4886025119f * v.x;
        }

        public static float Y4(Vector3 v)
        {
            return 1.0925484306f * v.x * v.y;
        }

        public static float Y5(Vector3 v)
        {
            return 1.0925484306f * v.y * v.z;
        }

        public static float Y6(Vector3 v)
        {
            return 0.3153915652f * (3.0f * v.z * v.z - 1.0f);
        }

        public static float Y7(Vector3 v)
        {
            return 1.0925484306f * v.x * v.z;
        }

        public static float Y8(Vector3 v)
        {
            return 0.5462742153f * (v.x * v.x - v.y * v.y);
        }

        public static SH_Base1[] Eval1 = { Y0, Y1, Y2, Y3, Y4, Y5, Y6, Y7, Y8 };
    }

    public static int FindFace(Vector3 dir)
    {
        int f = 0;
        float max = Mathf.Abs(dir.x);
        if (Mathf.Abs(dir.y) > max)
        {
            max = Mathf.Abs(dir.y);
            f = 2;
        }
        if (Mathf.Abs(dir.z) > max)
        {
            f = 4;
        }

        switch (f)
        {
            case 0:
                if (dir.x < 0)
                    f = 1;
                break;

            case 2:
                if (dir.y < 0)
                    f = 3;
                break;

            case 4:
                if (dir.z < 0)
                    f = 5;
                break;
        }

        return f;
    }
    #endregion
}
