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
        [SerializeField] private AnimationCurve _alphaCurve;
        [SerializeField] private float _a;
        [SerializeField] private float _b;
        [SerializeField] private float _c;
        [SerializeField] private float _d;
        [SerializeField] private float _normalLerp;

        private const int _interpolationCount = 4;

        private MeshFilter _meshFilter;
        private MeshRenderer _meshRenderer;
        private Mesh _mesh;

        private List<TailSection> _tailSections = new List<TailSection>();
        [SerializeField] private List<TailSection> _renderSections = new List<TailSection>();

        private List<Vector3> _positionCache = new List<Vector3>();
        private float _time;

        private Vector3[] _vertices;
        private Color[] _colors;
        private Vector2[] _uvs;
        private Vector2[] _uvs2;
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
            get { return _renderSections.Count * 2; }
        }
        private int TriangleCount
        {
            get { return (_renderSections.Count - 1) * 2; }
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
            UpdateTailTime(_tailSections);
            UpdateTailTime(_renderSections);
            _time += Time.deltaTime;
            if (_time >= _interval)
            {
                _time = 0;

                CaptureTail();
                Interpolate();
            }
            DrawTail();
        }
        private void Interpolate()
        {
            var baseIdx = _tailSections.Count - _interpolationCount;
            if (baseIdx < 0)
            {
                return;
            }

            CatmulRom(_tailSections[baseIdx + 0],
                        _tailSections[baseIdx + 1],
                        _tailSections[baseIdx + 2],
                        _tailSections[baseIdx + 3]);
        }
        private void CaptureTail()
        {
            var newTailSection = new TailSection()
            {
                PointA = PointA,
                PointB = PointB,
                Time = Time.time
            };

            _tailSections.Add(newTailSection);
        }
        private void UpdateTailTime(List<TailSection> tails)
        {
            while (tails.Count > 0 && Time.time > tails[0].Time + _during)
            {
                tails.RemoveAt(0);
            }
        }
        private void DrawTail()
        {
            if (_renderSections.Count < 2)
            {
                Debug.Log(_renderSections.Count);
                return;
            }

            _mesh.Clear();

            _vertices = new Vector3[VerticeCount];
            _colors = new Color[VerticeCount];
            _uvs = new Vector2[VerticeCount];
            _uvs2 = new Vector2[VerticeCount];
            Vector3[] normals = new Vector3[VerticeCount];

            for (var i = 0; i < _renderSections.Count; i++)
            {
                var currentSection = _renderSections[i];

                var indexA = i * 2 + 0;
                var indexB = i * 2 + 1;

                _vertices[indexA] = (currentSection.PointA);
                _vertices[indexB] = (currentSection.PointB);

                _uvs[indexA] = currentSection.UVA;
                _uvs[indexB] = currentSection.UVB;

                float u = Mathf.Clamp01((Time.time - currentSection.Time) / _during);
                u = _alphaCurve.Evaluate(u);
                _uvs2[indexA] = Vector2.one * u;
                _uvs2[indexB] = Vector2.one * u;

                Color interpolatedColor = Color.Lerp(Color.blue, Color.red, u);
                _colors[indexA] = interpolatedColor;
                _colors[indexB] = interpolatedColor;

                if (i > 1)
                {
                    var dir1 = (_renderSections[i - 1].PointB - _renderSections[i - 1].PointA).normalized;
                    var dir2 = (currentSection.PointB - currentSection.PointA).normalized;

                    if (dir1 != Vector3.zero && dir2 != Vector3.zero)
                    {
                        var normal = Vector3.Cross(dir1, dir2).normalized;
                        normals[indexA] = normal + _normalLerp * (dir2 - normal);
                        normals[indexB] = normal + _normalLerp * (-dir2 - normal);
                    }
                }
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
            _mesh.uv2 = _uvs2;
            _mesh.triangles = triangles;
            _mesh.normals = normals;

            _meshFilter.mesh = _mesh;
        }
        private void OnDrawGizmosSelected()
        {
            Gizmos.color = new Color(1, 0, 0, 0.5f);
            Gizmos.DrawSphere(PointA, 0.1f);
            Gizmos.DrawSphere(PointB, 0.1f);
        }
        //https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline
        private void CatmulRom(TailSection t0, TailSection t1, TailSection t2, TailSection t3)
        {
            _positionCache.Clear();

            var countA = CatmulRom(t0.PointA, t1.PointA, t2.PointA, t3.PointA, _positionCache);
            var countB = CatmulRom(t0.PointB, t1.PointB, t2.PointB, t3.PointB, _positionCache);

            if (countA != countB)
            {
                //Debug.LogError("[WeaponTail.CatmulRom]countA != countB");
            }

            var count = Mathf.Min(countA, countB);
            for (int i = 0; i < count; i++)
            {
                var pointA = _positionCache[i];
                var pointB = _positionCache[countA + i];

                if (_renderSections.Count > 1)
                {
                    var last = _renderSections[_renderSections.Count - 1];
                    if (last.PointA == pointA && last.PointB == pointB)
                    {
                        continue;
                    }
                }

                var noise = Mathf.Clamp01(Mathf.PerlinNoise(_positionCache[i].x, _positionCache[i].y));
                noise = noise * _a + _b;

                var tail = new TailSection()
                {
                    PointA = pointA,
                    PointB = pointB,
                    Time = Mathf.Lerp(t1.Time, t2.Time, (float)i / count),
                    UVA = new Vector2(noise, _c),
                    UVB = new Vector2(noise, _d),
                };

                _renderSections.Add(tail);
            }
        }
        private int CatmulRom(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3, List<Vector3> newPoints)
        {
            float t0 = 0.0f;
            float t1 = GetT(t0, p0, p1);
            float t2 = GetT(t1, p1, p2);
            float t3 = GetT(t2, p2, p3);

            if (t0 == t1) t1 += 0.001f;
            if (t1 == t2) t2 += 0.001f;
            if (t2 == t3) t3 += 0.001f;

            int count = 0;

            for (float t = t1; t < t2; t += ((t2 - t1) / _amountOfPoints))
            {
                var A1 = (t1 - t) / (t1 - t0) * p0 + (t - t0) / (t1 - t0) * p1;
                var A2 = (t2 - t) / (t2 - t1) * p1 + (t - t1) / (t2 - t1) * p2;
                var A3 = (t3 - t) / (t3 - t2) * p2 + (t - t2) / (t3 - t2) * p3;

                var B1 = (t2 - t) / (t2 - t0) * A1 + (t - t0) / (t2 - t0) * A2;
                var B2 = (t3 - t) / (t3 - t1) * A2 + (t - t1) / (t3 - t1) * A3;

                var C = (t2 - t) / (t2 - t1) * B1 + (t - t1) / (t2 - t1) * B2;

                newPoints.Add(C);
                count++;

                if (C.x == float.NaN)
                {
                    Debug.LogError("");
                }
            }


            return count;
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
