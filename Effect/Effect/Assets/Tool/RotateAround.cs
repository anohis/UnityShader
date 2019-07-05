using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateAround : MonoBehaviour
{
    public Transform Target;
    public Vector3 Axis;
    public float Speed;

    private void LateUpdate()
    {
        transform.RotateAround(Target.position, Axis, Speed * Time.deltaTime);
    }
}
