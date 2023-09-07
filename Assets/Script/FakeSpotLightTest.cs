
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
[RequireComponent(typeof(Light))]
public class FakeSpotLightTest : UdonSharpBehaviour
{
    Light spotLight;

    private int PosProp;
    private int DirProp;
    private int AngleProp;
    private int RangeProp;
    private int ColorProp;
    private int FalloffProp;

    private void Start()
    {
        spotLight = GetComponent<Light>();

        PosProp = VRCShader.PropertyToID("_UdonLightPos");
        DirProp = VRCShader.PropertyToID("_UdonLightDir");
        AngleProp = VRCShader.PropertyToID("_UdonSpotAngle");
        RangeProp = VRCShader.PropertyToID("_UdonLightRange");
        ColorProp = VRCShader.PropertyToID("_UdonLightColor");
    }

    private void Update()
    {
        VRCShader.SetGlobalVector(PosProp, transform.position);
        VRCShader.SetGlobalVector(DirProp, transform.forward);
        VRCShader.SetGlobalFloat(RangeProp, spotLight.range);
        VRCShader.SetGlobalFloat(AngleProp, Mathf.Cos(spotLight.spotAngle * Mathf.Deg2Rad * 0.5f));
        VRCShader.SetGlobalColor(ColorProp, new Color(spotLight.color.r, spotLight.color.b, spotLight.color.g, spotLight.intensity));
    }
}
