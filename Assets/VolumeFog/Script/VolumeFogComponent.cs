using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;

[RequireComponent(typeof(Light))]
public class VolumeFogComponent : MonoBehaviour
{
    [SerializeField]
    Camera _camera;

    public void OnValidate()
    {
        _camera = transform.GetComponentInChildren<Camera>();
    }

    [ContextMenu("CreateMesh")]
    public void CreateMesh()
    {
        var mesh = new Mesh();
        var n = _camera.nearClipPlane;
        var f = _camera.farClipPlane;

        var vertices = new Vector3[]
        {
            _camera.ScreenToWorldPoint(new Vector3(                               0, _camera.pixelHeight - 1, n)),
            _camera.ScreenToWorldPoint(new Vector3(_camera.pixelWidth -1, _camera.pixelHeight - 1, n)),
            _camera.ScreenToWorldPoint(new Vector3(_camera.pixelWidth -1,                                  0, n)),
            _camera.ScreenToWorldPoint(new Vector3(                               0,                                  0, n)),
            _camera.ScreenToWorldPoint(new Vector3(                               0, _camera.pixelHeight - 1, f)),
            _camera.ScreenToWorldPoint(new Vector3(_camera.pixelWidth -1, _camera.pixelHeight - 1, f)),
            _camera.ScreenToWorldPoint(new Vector3(_camera.pixelWidth -1,                                  0, f)),
            _camera.ScreenToWorldPoint(new Vector3(                               0,                                  0, f)),
        };

        vertices = vertices.Select(x => _camera.transform.InverseTransformPoint(x)).ToArray();

        var indices = new int[]
        {
            0,1,2,
            2,3,0,

            6,5,4,
            4,7,6,

            0,4,5,
            5,1,0,

            1,5,6,
            6,2,1,

            2,6,7,
            7,3,2,

            3,7,4,
            4,0,3
        };

        mesh.SetVertices(vertices);
        mesh.SetTriangles(indices, 0);

        var obj = new GameObject("VolumeMesh");
        var filter = obj.AddComponent<MeshFilter>();
        var renderer = obj.AddComponent<MeshRenderer>();
        filter.mesh = mesh;
        obj.transform.SetParent(transform, false);
    }
}
