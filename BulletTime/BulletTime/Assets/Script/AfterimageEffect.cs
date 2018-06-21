using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AfterimageEffectItem : MonoBehaviour
{
    public float AliveDuration;
    public float AlphaEffectRate;
    public Vector3 Offset;

    private MeshRenderer AfterimageMeshRenderer;
    private float LastTime = 0;

    void Start()
    {
        LastTime = Time.time;
        AfterimageMeshRenderer = GetComponent<MeshRenderer>();
        AfterimageMeshRenderer.material.SetVector("_Position", this.transform.position + Offset);
    }

    void Update()
    {
        float aliveTime = Time.time - LastTime;
        if (aliveTime > AliveDuration)
            GameObject.Destroy(this.gameObject);
        else
        {
            float timeRate = aliveTime / AliveDuration;
            AfterimageMeshRenderer.material.SetFloat("_Step", timeRate);
        }
    }
}


public class AfterimageEffect : MonoBehaviour
{
    public float EffectDuration = 2f;
    public float AlphaEffectRate = 0.5f;

    public Material AfterimageMaterial;

    SkinnedMeshRenderer[] SkinnedMeshRendererList;

    void Start ()
    {
        SkinnedMeshRendererList = this.gameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
    }

    /// <summary>
    /// 創造殘影
    /// </summary>
    public void Create()
    {
        foreach (SkinnedMeshRenderer smRenderer in SkinnedMeshRendererList)
        {
            Mesh mesh = new Mesh();
            smRenderer.BakeMesh(mesh);

            GameObject obj = new GameObject();
            obj.hideFlags = HideFlags.HideAndDontSave;

            AfterimageEffectItem item = obj.AddComponent<AfterimageEffectItem>();
            item.AliveDuration = EffectDuration;
            item.AlphaEffectRate = AlphaEffectRate;
            item.Offset = smRenderer.transform.forward * -1;

            MeshFilter filter = obj.AddComponent<MeshFilter>();
            filter.mesh = mesh;

            MeshRenderer meshRen = obj.AddComponent<MeshRenderer>();
            meshRen.material = AfterimageMaterial;

            obj.transform.localScale = smRenderer.transform.localScale;
            obj.transform.position = smRenderer.transform.position;
            obj.transform.rotation = smRenderer.transform.rotation;
        }
    }
}
