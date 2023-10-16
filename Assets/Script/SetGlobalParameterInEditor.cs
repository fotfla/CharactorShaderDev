using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using VRC.SDKBase;
using System.Linq;
#if UNITY_EDITOR
using UnityEditor;
#endif

#if UNITY_EDITOR
[ExecuteInEditMode]
public class SetGlobalParameterInEditor : MonoBehaviour
{
    [SerializeField]
    MeshRenderer meshRenderer;

    private MaterialPropertyBlock materialPropertyBlock;

    string[] propertyNames;
    int[] props;

    void Start()
    {
        if (!EditorApplication.isPlaying)
        {
            materialPropertyBlock = new MaterialPropertyBlock();
            if (meshRenderer != null)
            {
                var count = meshRenderer.sharedMaterial.shader.GetPropertyCount();
                propertyNames = new string[count];
                props = new int[count];
                for (var i = 0; i < count; i++)
                {
                    var name = meshRenderer.sharedMaterial.shader.GetPropertyName(i);
                    propertyNames[i] = name;
                    props[i] = Shader.PropertyToID("_Udon" + name);
                }
            }
        }
    }

    private void Update()
    {
        if (meshRenderer != null && !EditorApplication.isPlaying)
        {
            if (materialPropertyBlock == null) materialPropertyBlock = new MaterialPropertyBlock();

            meshRenderer.GetPropertyBlock(materialPropertyBlock);
            for (int i = 0; i < propertyNames.Length; i++)
            {
                var p = materialPropertyBlock.GetFloat(propertyNames[i]);
                Shader.SetGlobalFloat(props[i], p);
            }
        }
    }

    private void Reset()
    {
        if (meshRenderer == null)
        {
            meshRenderer = GetComponent<MeshRenderer>();

            var count = meshRenderer.sharedMaterial.shader.GetPropertyCount();
            props = new int[count];
            propertyNames = new string[count];
            for (var i = 0; i < count; i++)
            {
                var name = meshRenderer.sharedMaterial.shader.GetPropertyName(i);
                propertyNames[i] = name;
                props[i] = Shader.PropertyToID("_Udon" + name);
            }
        }
    }
}
#endif
