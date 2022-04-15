using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class SpecularReflectionPass : Rendering.Runtime.ScriptableRendererFeature
{
    private class CustomRenderPass : Rendering.Runtime.ScriptableRenderPass
    {
        private static readonly int s_ReflectionTexPropID = Shader.PropertyToID("g_ReflectionTex");

        private readonly List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();

        private FilteringSettings m_FilteringSettings;

        public CustomRenderPass()
        {
            m_RenderPassEvent = Rendering.Runtime.RenderPassEvent.BeforeRenderingOpaques;

            m_ShaderTagIdList.Add(new ShaderTagId("RenderForward"));

            m_FilteringSettings = new FilteringSettings();
            m_FilteringSettings.layerMask = -1;
            m_FilteringSettings.renderingLayerMask = 0xffffffff;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            List<ReflectionPlane> planes = ReflectionManager.instance.planes;
            if (planes.Count != 0)
                cmd.GetTemporaryRT(s_ReflectionTexPropID, cameraTextureDescriptor.width, cameraTextureDescriptor.height, 24, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
        }

        public override void Execute(ScriptableRenderContext context, ref Rendering.Runtime.RenderingData renderingData)
        {
            List<ReflectionPlane> planes = ReflectionManager.instance.planes;
            if (planes.Count == 0) return;

            CommandBuffer cmd = CommandBufferPool.Get("Specular Reflection RT");
            {
                ref Rendering.Runtime.CameraData cameraData = ref renderingData.cameraData;
                Camera camera = cameraData.camera;
                RenderTargetIdentifier colorAttachment = BuiltinRenderTextureType.CameraTarget;

                cmd.Clear();
                cmd.SetRenderTarget(s_ReflectionTexPropID);
                cmd.ClearRenderTarget(true, true, Color.black);

                // 这里只用第一个反射平面
                var reflectionPlane = planes[0];

                // 设置视角矩阵与投影矩阵
                Vector3 planeNormal = reflectionPlane.transform.up;
                Vector3 planePoint = reflectionPlane.transform.position;
                Matrix4x4 reflectMatrix = CalculateReflectMatrix(planeNormal, planePoint);
                Matrix4x4 worldToCameraMatrix = camera.worldToCameraMatrix * reflectMatrix;
                Matrix4x4 projectionMatrix = camera.projectionMatrix;
                cmd.SetViewProjectionMatrices(worldToCameraMatrix, projectionMatrix);
                context.ExecuteCommandBuffer(cmd);

                // 过滤反射层
                m_FilteringSettings.layerMask = -1;
                m_FilteringSettings.layerMask &= ~(1 << LayerMask.NameToLayer("ReflectionPlane"));

                // 渲染不透明物
                m_FilteringSettings.renderQueueRange = RenderQueueRange.opaque;
                DrawingSettings drawingOpaqueSettings = this.CreateDrawingSettings(m_ShaderTagIdList, camera, SortingCriteria.CommonOpaque);
                context.DrawRenderers(renderingData.cullResults, ref drawingOpaqueSettings, ref m_FilteringSettings);

                // 天空盒
                context.DrawSkybox(renderingData.cameraData.camera);

                // 渲染透明物
                m_FilteringSettings.renderQueueRange = RenderQueueRange.transparent;
                DrawingSettings drawingTransparentSettings = this.CreateDrawingSettings(m_ShaderTagIdList, camera, SortingCriteria.CommonTransparent);
                context.DrawRenderers(renderingData.cullResults, ref drawingTransparentSettings, ref m_FilteringSettings);

                // 恢复FrameBuffer
                cmd.Clear();
                cmd.SetViewProjectionMatrices(cameraData.GetViewMatrix(), cameraData.GetProjectionMatrix());
                cmd.SetRenderTarget(colorAttachment);
                context.ExecuteCommandBuffer(cmd);
            }
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            List<ReflectionPlane> planes = ReflectionManager.instance.planes;
            if (planes.Count != 0)
                cmd.ReleaseTemporaryRT(s_ReflectionTexPropID);
        }

        /// <summary>
        /// 计算反射矩阵
        /// </summary>
        /// <param name="normal"></param>
        /// <param name="positionOnPlane"></param>
        /// <returns></returns>
        private static Matrix4x4 CalculateReflectMatrix(Vector3 normal, Vector3 positionOnPlane)
        {
            var d = -Vector2.Dot(normal, positionOnPlane);
            var reflectMatrix = Matrix4x4.identity;
            reflectMatrix.m00 = 1 - 2 * normal.x * normal.x;
            reflectMatrix.m01 = -2 * normal.x * normal.y;
            reflectMatrix.m02 = -2 * normal.x * normal.z;
            reflectMatrix.m03 = -2 * d * normal.x;

            reflectMatrix.m10 = -2 * normal.x * normal.y;
            reflectMatrix.m11 = 1 - 2 * normal.y * normal.y;
            reflectMatrix.m12 = -2 * normal.y * normal.z;
            reflectMatrix.m13 = -2 * d * normal.y;

            reflectMatrix.m20 = -2 * normal.x * normal.z;
            reflectMatrix.m21 = -2 * normal.y * normal.z;
            reflectMatrix.m22 = 1 - 2 * normal.z * normal.z;
            reflectMatrix.m23 = -2 * d * normal.z;

            return reflectMatrix;
        }
    }

    private CustomRenderPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();
    }

    public override void AddRenderPasses(Rendering.Runtime.ScriptableRenderer renderer, ref Rendering.Runtime.RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}
