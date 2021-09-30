using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIWorldToScreen : MonoBehaviour
{
    public Transform Target;
    private Vector3 Offset = new Vector3(0, 2.3f, 0);
    public Canvas _canvas;
    private static RectTransform rect_transform;
    private Text text;
    private void Awake()
    {
        rect_transform = GetComponent<RectTransform>();
        text = GetComponent<Text>();
    }


    private void Update()
    {
        if (Target != null)
        {
            Vector3 world_pos = Target.position + Offset;

            float _distance_sqr = (Camera.main.transform.position - world_pos).sqrMagnitude;

            Vector2 _raw_screen_pos = Vector2.zero;
            Vector2 _ui_screen_point = Vector2.zero;
            if (WorldToScreenUIPoint(Camera.main, _canvas, world_pos, out _raw_screen_pos, out _ui_screen_point))
            {
                if (!IsScreenPointInside(_raw_screen_pos))
                {

                    text.enabled = false;
                }
                else
                {
                    text.enabled = true;
                    

                    rect_transform.anchoredPosition = new Vector2((int)_ui_screen_point.x, (int)_ui_screen_point.y);
                    Debug.Log(_distance_sqr / 1000.0f);
                    //根据距离缩放
                    float _scale_factor = Mathf.Lerp(1f, 0.2f, _distance_sqr / 1000.0f);

                    rect_transform.localScale = new Vector3(_scale_factor, _scale_factor, _scale_factor);
                }
               
            }
            
        }
    }

    public static bool WorldToScreenUIPoint(Camera _world_camera, Canvas _canvas, Vector3 _world_position, out Vector2 _raw_screen_pos, out Vector2 _ui_screen_point, bool _force_camera_front = true)
    {
        _ui_screen_point = Vector2.zero;
        _raw_screen_pos = Vector2.zero;

        if (_world_camera == null)
        {
            _world_camera = Camera.main;
            if (_world_camera == null)
            {
                return false;
            }
        }


        Vector3 _vec3_screen_pos = _world_camera.WorldToScreenPoint(_world_position);
        if (_vec3_screen_pos.z < 0.0f)
        {
            return false;
        }

        float _scale = 1.0f;
        if (_canvas != null)
        {
            _scale = _canvas.scaleFactor;

        }
        _raw_screen_pos.x = _vec3_screen_pos.x;
        _raw_screen_pos.y = _vec3_screen_pos.y;


        _ui_screen_point = _vec3_screen_pos / _scale;
        return true;
    }
    public static bool IsScreenPointInside(Vector2 _screenPoint)
    {
        int _top_x = Screen.width;
        int _top_y = Screen.height;
        if (_screenPoint.x < _top_x && _screenPoint.x > 0 && _screenPoint.y < _top_y && _screenPoint.y > 0)
        {
            return true;
        }
        return false;
    }

}
