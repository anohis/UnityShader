using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Effect.GS
{
    public class Tail : MonoBehaviour
    {
        private Vector3[] _vertices;
        private int[] _triangles;
        [SerializeField] private Material _material;

        private void Start()
        {
            var meshFilter = gameObject.AddComponent<MeshFilter>();
            var meshRenderer = gameObject.AddComponent<MeshRenderer>();
            meshRenderer.material = _material;
            var mesh = meshFilter.mesh;
            
            _vertices = new Vector3[6];
            _vertices[0] = new Vector3(0,1,0);
            _vertices[1] = new Vector3(1,1,0);
            _vertices[2] = new Vector3(0,0,0);
            _vertices[3] = new Vector3(1,0,0);
            _vertices[4] = new Vector3(0,-1,0);
            _vertices[5] = new Vector3(1,-1,0);

            mesh.vertices = _vertices;

            var triCount = _vertices.Length - 2;
            _triangles = new int[triCount * 3];

            for (int i = 0; i < triCount; i++)
            {
                for (int j = 0; j < 3; j++)
                {
                    if (i % 2 == 0)
                    {
                        _triangles[3 * i + j] = i + j;
                    }
                    else
                    {
                        _triangles[3 * i + j] = i + 2 - j;
                    }
                }
            }

            mesh.triangles = _triangles;
            
            Vector2[] uvs = new Vector2[_vertices.Length];
            for (int i = 0; i < uvs.Length; i++)
            {
                uvs[i] = new Vector2(_vertices[i].x, _vertices[i].y);
            }
            mesh.uv = uvs;
            
            meshFilter.mesh = mesh;
        }
    }
}
