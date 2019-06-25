using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Effect.GS
{
    public class WeaponTail : MonoBehaviour
    {
        [SerializeField] private Vector3 _pointA;
        [SerializeField] private Vector3 _pointB;
        [SerializeField] private float _interval;
        [SerializeField] private Material _material;

        private Vector3 PointA { get { return transform.position + _pointA; } }
        private Vector3 PointB { get { return transform.position + _pointB; } }

        private List<Vector3> _vertices = new List<Vector3>();
        private int[] _triangles;
        private MeshFilter _meshFilter;
        private MeshRenderer _meshRenderer;
        private Mesh _mesh;

        private void Start()
        {
            var obj = new GameObject();
            _meshFilter = obj.AddComponent<MeshFilter>();
            _meshRenderer = obj.AddComponent<MeshRenderer>();
            _meshRenderer.material = _material;
            _mesh = _meshFilter.mesh;

            StartCoroutine(Draw());
        }

        private IEnumerator Draw()
        {
            while (true)
            {
                yield return new WaitForSeconds(_interval);

                _vertices.Add(PointA);
                _vertices.Add(PointB);

                _mesh.SetVertices(_vertices);

                var triCount = _vertices.Count - 2;
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

                _mesh.SetTriangles(_triangles, 0);

                Vector2[] uvs = new Vector2[_vertices.Count];
                for (int i = 0; i < uvs.Length; i++)
                {
                    uvs[i] = new Vector2(_vertices[i].x, _vertices[i].y);
                }
                _mesh.uv = uvs;

                _meshFilter.mesh = _mesh;
            }
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.color = new Color(1,0,0,0.5f);
            Gizmos.DrawSphere(PointA, 0.1f);
            Gizmos.DrawSphere(PointB, 0.1f);
        }
    }
}
