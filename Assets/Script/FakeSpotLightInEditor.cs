using UnityEditor;
using UnityEngine;

#if !COMPILER_UDONSHARP && UNITY_EDITOR
[ExecuteInEditMode]
public class FakeSpotLightInEditor : MonoBehaviour
{
    Light spotLight;

    private int PosProp = Shader.PropertyToID("_UdonLightPos");
    private int DirProp = Shader.PropertyToID("_UdonLightDir");
    private int LightDataProp = Shader.PropertyToID("_UdonLightData");
    private int ColorProp = Shader.PropertyToID("_UdonLightColor");

    private void Start()
    {
        spotLight = GetComponent<Light>();
    }

    private void Update()
    {
        if (spotLight != null && !EditorApplication.isPlaying)
        {
            Shader.SetGlobalVector(PosProp, transform.position);
            Shader.SetGlobalVector(DirProp, transform.forward);
            Shader.SetGlobalVector(LightDataProp, new Vector3(spotLight.range, Mathf.Cos(spotLight.spotAngle * Mathf.Deg2Rad * 0.5f), spotLight.intensity));
            Shader.SetGlobalColor(ColorProp, spotLight.color);
        }
    }
}
#endif
