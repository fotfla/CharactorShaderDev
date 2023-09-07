
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
public class SetSkyBox : UdonSharpBehaviour
{
    [SerializeField]
    Material skybox;

    SphericalHarmonicsL2 sh;
    [SerializeField]
    float[] shValue;

    private void Start()
    {
        for (var i = 0; i < 27; i++)
        {
            int rgb = i / 9;
            int coff = i % 9;
            sh[rgb, coff] = shValue[i];
        }
    }

    private void OnEnable()
    {
        RenderSettings.skybox = skybox;
        RenderSettings.ambientProbe = sh;
    }

    public void SetSH(SphericalHarmonicsL2 sh)
    {
        shValue = new float[27];
        for (var i = 0; i < 27; i++)
        {
            int rgb = i / 9;
            int coff = i % 9;
            shValue[i] = sh[rgb, coff];
        }
    }

    public Material GetMaterial()
    {
        return skybox;
    }
}

#if !COMPILER_UDONSHARP && UNITY_EDITOR
[CustomEditor(typeof(SetSkyBox))]
public class SetSkyBoxInspector : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("SetSH"))
        {
            var sky = (SetSkyBox)target;
            RenderSettings.skybox = sky.GetMaterial();
            DynamicGI.UpdateEnvironment();
            sky.SetSH(RenderSettings.ambientProbe);
        }
    }
}
#endif
