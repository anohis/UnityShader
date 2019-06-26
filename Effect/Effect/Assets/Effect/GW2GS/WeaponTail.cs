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
        [SerializeField] private int _amountOfPoints = 10;
        [SerializeField] private float _alpha = 0.5f;

        private const int _interpolationCount = 4;

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

            var listA = new List<Vector3>();
            var listB = new List<Vector3>();

            if (_tailSections.Count == 1)
            {
                listA.Add(_tailSections[0].PointA);
                listA.Add(_tailSections[0].PointA);
                listA.Add(newTailSection.PointA);
                listA.Add(newTailSection.PointA);

                listB.Add(_tailSections[0].PointB);
                listB.Add(_tailSections[0].PointB);
                listB.Add(newTailSection.PointB);
                listB.Add(newTailSection.PointB);
            }
            else if (_tailSections.Count == 2)
            {
                listA.Add(_tailSections[0].PointA);
                listA.Add(_tailSections[1].PointA);
                listA.Add(newTailSection.PointA);
                listA.Add(newTailSection.PointA);

                listB.Add(_tailSections[0].PointB);
                listB.Add(_tailSections[1].PointB);
                listB.Add(newTailSection.PointB);
                listB.Add(newTailSection.PointB);
            }
            else if (_tailSections.Count >= 3)
            {
                int baseIdx = _tailSections.Count - _interpolationCount + 1;

                listA.Add(_tailSections[baseIdx + 0].PointA);
                listA.Add(_tailSections[baseIdx + 1].PointA);
                listA.Add(_tailSections[baseIdx + 2].PointA);
                listA.Add(newTailSection.PointA);

                listB.Add(_tailSections[baseIdx + 0].PointB);
                listB.Add(_tailSections[baseIdx + 1].PointB);
                listB.Add(_tailSections[baseIdx + 2].PointB);
                listB.Add(newTailSection.PointB);
            }

            CatmulRom(listA);
            CatmulRom(listB);
            for (int i = 1; i < listA.Count - 1; i++)
            {
                _tailSections.Add(new TailSection()
                {
                    PointA = listA[i],
                    PointB = listB[i],
                    Time = Time.time
                });
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
            Gizmos.color = new Color(1, 0, 0, 0.5f);
            Gizmos.DrawSphere(PointA, 0.1f);
            Gizmos.DrawSphere(PointB, 0.1f);
        }
        //https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline
        private void CatmulRom(List<Vector3> newPoints)
        {
            if (newPoints.Count < 4)
            {
                newPoints.Clear();
                return;
            }

            var p0 = newPoints[0]; 
            var p1 = newPoints[1];
            var p2 = newPoints[2];
            var p3 = newPoints[3];

            newPoints.Clear();

            float t0 = 0.0f;
            float t1 = GetT(t0, p0, p1);
            float t2 = GetT(t1, p1, p2);
            float t3 = GetT(t2, p2, p3);

            for (float t = t1; t < t2; t += ((t2 - t1) / _amountOfPoints))
            {
                var A1 = (t1 - t) / (t1 - t0) * p0 + (t - t0) / (t1 - t0) * p1;
                var A2 = (t2 - t) / (t2 - t1) * p1 + (t - t1) / (t2 - t1) * p2;
                var A3 = (t3 - t) / (t3 - t2) * p2 + (t - t2) / (t3 - t2) * p3;

                var B1 = (t2 - t) / (t2 - t0) * A1 + (t - t0) / (t2 - t0) * A2;
                var B2 = (t3 - t) / (t3 - t1) * A2 + (t - t1) / (t3 - t1) * A3;

                var C = (t2 - t) / (t2 - t1) * B1 + (t - t1) / (t2 - t1) * B2;

                newPoints.Add(C);
            }
        }
        private float GetT(float t, Vector3 p0, Vector3 p1)
        {
            float a = Mathf.Pow((p1.x - p0.x), 2.0f) + Mathf.Pow((p1.y - p0.y), 2.0f) + Mathf.Pow((p1.z - p0.z), 2.0f);
            float b = Mathf.Pow(a, 0.5f);
            float c = Mathf.Pow(b, _alpha);

            return (c + t);
        }
    }
}
