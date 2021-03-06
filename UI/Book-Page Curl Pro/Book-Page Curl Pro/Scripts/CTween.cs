using UnityEngine;
using System.Collections;
using System;
public class CTween : MonoBehaviour {

    Vector3 from,to;
    float duration;
    Action<Vector3> update;
    Action finish;
    float elapsedtime = 0;
    bool working = false;
    public static Vector3 ValueTo(GameObject obj,
        Vector3 from, Vector3 to,float duration,
        Action<Vector3> update = null,Action finish=null)
    {
        CTween tween = obj.GetComponent<CTween>();
        if (!tween)
            tween = obj.AddComponent<CTween>();
        tween.elapsedtime = 0;
        tween.working = true;
        tween.enabled = true;
        tween.from = from;
        tween.to = to;
        tween.duration = duration;
        tween.update = update;
        tween.finish = finish;
        return Vector3.zero;
    }
    static Vector3 QuadOut(Vector3 start,Vector3 end,float duration,float elapsedTime)
    {
        if (elapsedTime >= duration)
            return end;
        else
        {
            return (elapsedTime / duration) * (elapsedTime / duration - 2) * -(end - start) + start;
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (working)
        {
            elapsedtime += Time.deltaTime;
            Vector3 value = QuadOut(from, to, duration, elapsedtime);
            if (update != null) update(value);
            if (elapsedtime>=duration)
            {
                working = false;
                this.enabled = false;
                if (finish!=null)
                {
                    finish();
                }
            }
        }
    }
}
