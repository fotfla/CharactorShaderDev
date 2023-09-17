using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Light))]
public class FakeSpotLightComponentInEditor : MonoBehaviour
{
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

    public Vector4 GetLightData()
    {
        return new Vector4(spotlight.range, spotlight.spotAngle, spotlight.innerSpotAngle, spotlight.intensity);
    }

    public Color GetLightColor()
    {
        return spotlight.color;
    }
}
