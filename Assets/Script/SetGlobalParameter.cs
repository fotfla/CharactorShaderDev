
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class SetGlobalParameter : UdonSharpBehaviour
{
    [SerializeField]
    MeshRenderer meshRenderer;
    Material material;

    void Start()
    {
        material = meshRenderer.material;
    }

    private void Update()
    {
        var c = material.GetColor("_Color");
        Debug.Log(c);
    }
}
