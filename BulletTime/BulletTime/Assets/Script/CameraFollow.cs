using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    public Transform target;
    public float Speed = 1;
    public float DistanceUp = 50;
    public float DistanceAway = 50;
    public Vector3 BasePos = Vector3.zero;
    public Vector3 NewRotate = Vector3.zero;
    public Vector3 RotateMin = Vector3.zero;
    public Vector3 RotateMax = Vector3.zero;

    private Vector3 CamPosition;
    private Vector3 CamRotate;

    void Start()
    {
        CamRotate = NewRotate;
    }

    void Update()
    {
        if (Input.GetMouseButton(0) || Input.GetMouseButton(1))
        {
            NewRotate.x += Input.GetAxis("Mouse Y") * Speed;
            NewRotate.y += Input.GetAxis("Mouse X") * Speed;
        }
        NewRotate.x = NewRotate.x % 360;
        NewRotate.y = NewRotate.y % 360;
        if (NewRotate.x > RotateMax.x) NewRotate.x = RotateMax.x;
        else if (NewRotate.x < RotateMin.x) NewRotate.x = RotateMin.x;
    }

    void LateUpdate()
    {
        Vector3 targetPos = target.position + BasePos;
        //避免過大的角度移動而造成畫面忽前忽後
        CamRotate = Vector3.Lerp(CamRotate, NewRotate, Time.deltaTime * Speed);
        Quaternion rotation = Quaternion.Euler(CamRotate);
        CamPosition =  Vector3.up * DistanceUp - Vector3.forward * DistanceAway;
        //四位數乘上向量表示轉向，也可以看成以原點旋轉
        CamPosition =  rotation * CamPosition + targetPos; 
        transform.position = Vector3.Lerp(transform.position, CamPosition, Time.deltaTime * Speed);
        transform.LookAt(targetPos);
    }
}
