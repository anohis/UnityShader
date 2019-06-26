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
        [SerializeField] private float _during;
        [SerializeField] private Material _material;

        private MeshFilter _meshFilter;
        private MeshRenderer _meshRenderer;
        private Mesh _mesh;

        private List<TailSection> _tailSections = new List<TailSection>();

        private Vector3[] _vertices;
        private Color[] _colors;
        private Vector2[] _uvs;
        private int[] _triangles;

        private Vector3 PointA
        {
            get
            {
                return transform.position + transform.TransformVector(_pointA);
            }
        }
        private Vector3 PointB
        {
            get
            {
                return transform.position + transform.TransformVector(_pointB);
            }
        }
        private int VerticeCount
        {
            get { return _tailSections.Count * 2; }
        }
        private int TriangleCount
        {
            get { return (_tailSections.Count - 1) * 2; }
        }

        private void Start()
        {
            var obj = new GameObject();
            _meshFilter = obj.AddComponent<MeshFilter>();
            _meshRenderer = obj.AddComponent<MeshRenderer>();
            _meshRenderer.material = _material;
            _meshRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            _meshRenderer.receiveShadows = false;
            _mesh = _meshFilter.mesh;
        }

        private void Update()
        {
            UpdateTailTime();
            CaptureTail();
            DrawTail();
        }

        private void CaptureTail()
        {
            var newTailSection = new TailSection()
            {
                PointA = PointA,
                PointB = PointB,
                Time = Time.time
            };

            if (_tailSections.Count > 1)
            {
                var lastTailSection = _tailSections[_tailSections.Count - 1];
            }

            _tailSections.Add(newTailSection);
        }

        private void UpdateTailTime()
        {
            while (_tailSections.Count > 0 && Time.time > _tailSections[0].Time + _during)
            {
                _tailSections.RemoveAt(0);
            }
        }

        private void DrawTail()
        {
            if (_tailSections.Count < 2)
            {
                return;
            }

            _mesh.Clear();

            _vertices = new Vector3[VerticeCount];
            _colors = new Color[VerticeCount];
            _uvs = new Vector2[VerticeCount];

            for (var i = 0; i < _tailSections.Count; i++)
            {
                var currentSection = _tailSections[i];

                float u = Mathf.Clamp01((Time.time - currentSection.Time) / _during);

                _vertices[i * 2 + 0] = (currentSection.PointA);
                _vertices[i * 2 + 1] = (currentSection.PointB);

                _uvs[i * 2 + 0] = new Vector2(u, 0);
                _uvs[i * 2 + 1] = new Vector2(u, 1);

                Color interpolatedColor = Color.Lerp(Color.blue, Color.red, u);
                _colors[i * 2 + 0] = interpolatedColor;
                _colors[i * 2 + 1] = interpolatedColor;
            }

            int[] triangles = new int[TriangleCount * 3];
            for (int i = 0; i < triangles.Length / 6; i++)
            {
                triangles[i * 6 + 0] = i * 2;
                triangles[i * 6 + 1] = i * 2 + 1;
                triangles[i * 6 + 2] = i * 2 + 2;

                triangles[i * 6 + 3] = i * 2 + 2;
                triangles[i * 6 + 4] = i * 2 + 1;
                triangles[i * 6 + 5] = i * 2 + 3;
            }

            _mesh.vertices = _vertices;
            _mesh.colors = _colors;
            _mesh.uv = _uvs;
            _mesh.triangles = triangles;

            _meshFilter.mesh = _mesh;
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.color = new Color(1,0,0,0.5f);
            Gizmos.DrawSphere(PointA, 0.1f);
            Gizmos.DrawSphere(PointB, 0.1f);
        }
    }
}
