using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateAround : MonoBehaviour
{
    public Transform Target;
    public float Distance;
    public Vector3 Speed;

    private void LateUpdate()
    {
        Quaternion rotation = Quaternion.Euler(Speed * Time.deltaTime);
        transform.position = rotation * transform.position + Target.position;
    }
}
