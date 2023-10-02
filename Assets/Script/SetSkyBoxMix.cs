
using UdonSharp;
using UnityEngine;
using UnityEngine.Rendering;
using VRC.SDKBase;
using VRC.Udon;


#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UdonSharpEditor;
using UnityEditor;
#endif

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class SetSkyBoxMix : UdonSharpBehaviour
{
    SphericalHarmonicsL2 sh0;
    [SerializeField]
    float[] sh0Value;

    SphericalHarmonicsL2 sh1;
    [SerializeField]
    float[] sh1Value;

    [SerializeField]
    Light directionalLight;

    [SerializeField]
    public Quaternion lightRot0;
    [SerializeField]
    public Quaternion lightRot1;

    SphericalHarmonicsL2 sh = new SphericalHarmonicsL2();
    float maxAngle;

    private void Start()
    {
        for (var i = 0; i < 27; i++)
        {
            int rgb = i / 9;
            int coff = i % 9;
            sh0[rgb, coff] = sh0Value[i];
            sh1[rgb, coff] = sh1Value[i];
        }
        maxAngle = 1 - Quaternion.Dot(lightRot0, lightRot1);
        Debug.Log(Quaternion.Dot(lightRot0, lightRot0));
    }

    private void Update()
    {
        float m = (1 - Quaternion.Dot(lightRot0, directionalLight.transform.rotation)) / maxAngle;
        Debug.Log(m);
        for (var i = 0; i < 27; i++)
        {
            int rgb = i / 9;
            int coff = i % 9;
            sh[rgb, coff] = Mathf.Lerp(sh0Value[i], sh1Value[i], m);
        }
        RenderSettings.ambientProbe = sh;
    }

    public void SetSH0(SphericalHarmonicsL2 sh)
    {
        sh0Value = new float[27];
        for (var i = 0; i < 27; i++)
        {
            int rgb = i / 9;
            int coff = i % 9;
            sh0Value[i] = sh[rgb, coff];
        }
        lightRot0 = directionalLight.transform.rotation;
    }

    public void SetSH1(SphericalHarmonicsL2 sh)
    {
        sh1Value = new float[27];
        for (var i = 0; i < 27; i++)
        {
            int rgb = i / 9;
            int coff = i % 9;
            sh1Value[i] = sh[rgb, coff];
        }
        lightRot1 = directionalLight.transform.rotation;
    }
}

#if !COMPILER_UDONSHARP && UNITY_EDITOR
[CustomEditor(typeof(SetSkyBoxMix))]
public class SetSkyBoxMixInspector : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("SetSH0"))
        {
            var sky = (SetSkyBoxMix)target;
            sky.SetSH0(RenderSettings.ambientProbe);
        }

        if (GUILayout.Button("SetSH1"))
        {
            var sky = (SetSkyBoxMix)target;
            sky.SetSH1(RenderSettings.ambientProbe);
        }
    }
}
#endif
