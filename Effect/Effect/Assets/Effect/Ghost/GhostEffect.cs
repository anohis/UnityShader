using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace Effect.Ghost
{
    public class GhostEffectItem : MonoBehaviour
    {
        public float AliveDuration;
        public float Alpha;

        private MeshRenderer _meshRenderer;
        private float _lastTime = 0;

        #region MonoBehaviour
        private void Start()
        {
            _lastTime = Time.time;
            _meshRenderer = GetComponent<MeshRenderer>();
        }
        private void Update()
        {
            float aliveTime = Time.time - _lastTime;
            if (aliveTime > AliveDuration)
                GameObject.Destroy(gameObject);
            else
            {
                float timeRate = aliveTime / AliveDuration;
                _meshRenderer.material.SetFloat("_Step", timeRate);
                _meshRenderer.material.SetFloat("_Alpha", Alpha * (1-timeRate));
            }
        }
        #endregion
    }

    public class GhostEffect : MonoBehaviour
    {
        public float EffectDuration = 2f;
        public float Alpha = 0.5f;
        public Vector3 Offest;
        public Material GhostMaterial;

        private SkinnedMeshRenderer[] _skinnedMeshRendererList;

        #region MonoBehaviour
        void Start()
        {
            _skinnedMeshRendererList = this.gameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        }
        #endregion

        #region public func
        public void Create()
        {
            foreach (SkinnedMeshRenderer smRenderer in _skinnedMeshRendererList)
            {
                Mesh mesh = new Mesh();
                smRenderer.BakeMesh(mesh);

                if (mesh.subMeshCount > 1)
                {
                    mesh.SetTriangles(mesh.triangles, 0);
                    mesh.subMeshCount = 1;
                }

                GameObject obj = new GameObject();
                obj.hideFlags = HideFlags.HideAndDontSave;

                GhostEffectItem item = obj.AddComponent<GhostEffectItem>();
                item.AliveDuration = EffectDuration;
                item.Alpha = Alpha;

                MeshFilter filter = obj.AddComponent<MeshFilter>();
                filter.mesh = mesh;

                MeshRenderer meshRen = obj.AddComponent<MeshRenderer>();
                meshRen.material = GhostMaterial;

                obj.transform.localScale = smRenderer.transform.localScale;
                obj.transform.position = smRenderer.transform.position;
                obj.transform.rotation = smRenderer.transform.rotation;
            }
        }
        #endregion
    }
}
