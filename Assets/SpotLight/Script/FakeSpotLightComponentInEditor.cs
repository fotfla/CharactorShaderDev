using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

#if !COMPILER_UDONSHARP && UNITY_EDITOR
[RequireComponent(typeof(Light))]
[ExecuteInEditMode]
public class FakeSpotLightComponentInEditor : MonoBehaviour
{
    [SerializeField]
    Light spotlight;
    [SerializeField]
    GameObject coneObj;
    [SerializeField]
    Material baseMaterial;

    Material tempMaterial;

    private void Awake()
    {
        coneObj.GetComponent<MeshRenderer>().sharedMaterial = baseMaterial;
    }

    private void OnEnable()
    {
        if (!EditorApplication.isPlaying)
        {
            spotlight = GetComponent<Light>();
            coneObj = GetComponentInChildren<MeshFilter>().gameObject;
            if (baseMaterial == null)
            {
                baseMaterial = coneObj.GetComponent<MeshRenderer>().sharedMaterial;
                tempMaterial = new Material(baseMaterial);
                tempMaterial.name = tempMaterial.name + "Temp";
                coneObj.GetComponent<MeshRenderer>().material = tempMaterial;
            }
        }
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

    private void Update()
    {
        if (!EditorApplication.isPlaying)
        {
            var z = spotlight.range;
            var x = Mathf.Tan(Mathf.Deg2Rad * spotlight.spotAngle * 0.5f) * z * 2;
            coneObj.transform.localScale = new Vector3(x, z, x);
            if (tempMaterial != null)
            {
                tempMaterial.SetColor("_Color", spotlight.color);
                tempMaterial.SetFloat("_LightIntensity", spotlight.intensity);
            }
        }
    }
}
#endif
