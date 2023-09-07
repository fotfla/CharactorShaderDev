
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class SetGlobalParameter : UdonSharpBehaviour
{
    [SerializeField]
    MeshRenderer meshRenderer;
    private MaterialPropertyBlock materialPropertyBlock;

    private int Param1Prop;

    void Start()
    {
        Param1Prop = VRCShader.PropertyToID("_UdonParam1");

        materialPropertyBlock = new MaterialPropertyBlock();
    }

    private void Update()
    {
        meshRenderer.GetPropertyBlock(materialPropertyBlock);
        var p1 = materialPropertyBlock.GetFloat("Param1");
        VRCShader.SetGlobalFloat(Param1Prop, p1);
    }
}
