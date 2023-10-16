
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
using UdonSharpEditor;
#endif

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class SetGlobalParameter : UdonSharpBehaviour
{
    [SerializeField]
    public MeshRenderer meshRenderer;
    private MaterialPropertyBlock materialPropertyBlock;

    [SerializeField]
    public string[] propertyNames;
    int[] props;

    void Start()
    {
        materialPropertyBlock = new MaterialPropertyBlock();

        var count = propertyNames.Length;
        props = new int[count];
        for (var i = 0; i < count; i++)
        {
            var name = propertyNames[i];
            props[i] = VRCShader.PropertyToID("_Udon" + name);
        }
    }

    private void Update()
    {
        meshRenderer.GetPropertyBlock(materialPropertyBlock);

        for (int i = 0; i < propertyNames.Length; i++)
        {
            var p = materialPropertyBlock.GetFloat(propertyNames[i]);
            VRCShader.SetGlobalFloat(props[i], p);
        }
    }
}

#if !COMPILER_UDONSHARP && UNITY_EDITOR
[CustomEditor(typeof(SetGlobalParameter))]
public class SetGlobalParameterInspector : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (GUILayout.Button("Set"))
        {
            var p = target as SetGlobalParameter;
            var count = p.meshRenderer.sharedMaterial.shader.GetPropertyCount();
            var propertyNames = new string[count];
            for (var i = 0; i < count; i++)
            {
                propertyNames[i] = p.meshRenderer.sharedMaterial.shader.GetPropertyName(i);
            }
            p.propertyNames = propertyNames;
        }
    }
}
#endif
