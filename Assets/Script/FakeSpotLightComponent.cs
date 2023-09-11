
using UdonSharp;
using UnityEngine;
using UnityEngine.Experimental.GlobalIllumination;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class FakeSpotLightComponent : UdonSharpBehaviour
{
    [SerializeField]
    Light spotlight;

    private void OnEnable()
    {
        spotlight = GetComponent<Light>();
    }

    public Vector3 GetLightPos()
    {
        return transform.position;
    }

    public Vector3 GetLightDir()
    {
        return transform.forward;
    }

    public Vector3 GetLightData()
    {
        return new Vector3(spotlight.range, Mathf.Cos(spotlight.spotAngle * Mathf.Deg2Rad * 0.5f), spotlight.intensity);
    }

    public Color GetLightColor()
    {
        return spotlight.color;
    }

    public Matrix4x4 GetSpotLightData()
    {
        var m = new Matrix4x4();
        m.SetRow(0, GetLightPos());
        m.SetRow(1, GetLightDir());
        m.SetRow(2, GetLightData());
        m.SetRow(3, GetLightColor());
        return m;
    }

    private void OnValidate()
    {
        if (spotlight == null)
        {
            spotlight = GetComponent<Light>();
        }
    }
}
