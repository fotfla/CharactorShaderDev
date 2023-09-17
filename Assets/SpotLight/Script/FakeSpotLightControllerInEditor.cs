using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if !COMPILER_UDONSHARP && UNITY_EDITOR
[ExecuteInEditMode]
public class FakeSpotLightControllerInEditor : MonoBehaviour
{
    [SerializeField]
    int maxLight = 8;

    FakeSpotLightComponent[] spotLights;
    Matrix4x4[] spotLightData;

    private int LightDataProp = Shader.PropertyToID("_UdonSpotLightData");

    private void Start()
    {
        spotLights = FindObjectsOfType<FakeSpotLightComponent>();
        spotLightData = new Matrix4x4[maxLight];
    }

    private void Update()
    {
        for (int i = 0; i < spotLights.Length; i++)
        {
            if (i < maxLight) spotLightData[i] = spotLights[i].GetSpotLightData();
        }
        Shader.SetGlobalMatrixArray(LightDataProp, spotLightData);

        var mm = Shader.GetGlobalMatrixArray(LightDataProp);
        Debug.Log(mm.Length);
    }
}
#endif
