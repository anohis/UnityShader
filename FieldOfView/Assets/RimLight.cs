using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RimLight : MonoBehaviour {

    [SerializeField]
    private Material RimLightMaterial = null;
    [SerializeField]
    private Camera ViewCamera = null;

    void Start () {
		
	}

    void UpdateRimLightMaterial()
    {
        if (RimLightMaterial == null || ViewCamera == null) return;

        Vector3 carmeraForward = ViewCamera.transform.forward;
        Vector3 carmeraPos = ViewCamera.transform.position;
        Vector3 thisPos = transform.position;
        float t = -(carmeraForward.x * (thisPos.x - carmeraPos.x) 
                        + carmeraForward.y * (thisPos.y - carmeraPos.y) 
                        + carmeraForward.z * (thisPos.z - carmeraPos.z)) / (carmeraForward.x * carmeraForward.x 
                                                                                + carmeraForward.y * carmeraForward.y 
                                                                                + carmeraForward.z * carmeraForward.z);
        Vector3 viewPos = new Vector3(thisPos.x+ carmeraForward.x * t
                                        , thisPos.y + carmeraForward.y * t
                                        , thisPos.z + carmeraForward.z * t);
        
        RimLightMaterial.SetVector("_ViewPos", viewPos);
    }


    void Update ()
    {
        UpdateRimLightMaterial();
    }
}
