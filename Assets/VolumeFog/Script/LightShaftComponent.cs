
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

[UdonBehaviourSyncMode(BehaviourSyncMode.None)]
public class LightShaftComponent : UdonSharpBehaviour
{
    [SerializeField]
    Camera depthCamera;

    Material material;

    private void Start()
    {
        material = GetComponent<MeshRenderer>().material;
    }

    private void Update()
    {
        material.SetMatrix("_DepthCameraWorldToObject", depthCamera.transform.worldToLocalMatrix);
        material.SetFloat("_Size", depthCamera.orthographicSize);
        material.SetFloat("_Far", depthCamera.farClipPlane);
        material.SetFloat("_Near", depthCamera.nearClipPlane);
    }
}
