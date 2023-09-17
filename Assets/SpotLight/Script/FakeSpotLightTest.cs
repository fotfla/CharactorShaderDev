
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
[RequireComponent(typeof(Light))]

public class FakeSpotLightTest : UdonSharpBehaviour
{
    Light spotLight;

    private int PosProp = VRCShader.PropertyToID("_UdonLightPos");
    private int DirProp = VRCShader.PropertyToID("_UdonLightDir");
    private int LightDataProp = VRCShader.PropertyToID("_UdonLightData");
    private int ColorProp = VRCShader.PropertyToID("_UdonLightColor");

    private void Start()
    {
        spotLight = GetComponent<Light>();

        PosProp = VRCShader.PropertyToID("_UdonLightPos");
        DirProp = VRCShader.PropertyToID("_UdonLightDir");
        LightDataProp = VRCShader.PropertyToID("_UdonLightData");
        ColorProp = VRCShader.PropertyToID("_UdonLightColor");
    }

    private void Update()
    {
        VRCShader.SetGlobalVector(PosProp, transform.position);
        VRCShader.SetGlobalVector(DirProp, transform.forward);
        VRCShader.SetGlobalVector(LightDataProp, new Vector3(spotLight.range, Mathf.Cos(spotLight.spotAngle * Mathf.Deg2Rad * 0.5f), spotLight.intensity));
        VRCShader.SetGlobalColor(ColorProp, spotLight.color);
    }
}
