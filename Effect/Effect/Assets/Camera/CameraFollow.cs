using System.Collections;
using System.Collections.Generic;
using ToolKit.Math;
using UnityEngine;

namespace Camera
{
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
            NewRotate.z = NewRotate.z % 360;

			NewRotate.x = MathFunc.Saturate(NewRotate.x, RotateMin.x, RotateMax.x);
			NewRotate.y = MathFunc.Saturate(NewRotate.y, RotateMin.y, RotateMax.y);
			NewRotate.z = MathFunc.Saturate(NewRotate.z, RotateMin.z, RotateMax.z);
		}

        void LateUpdate()
        {
            Vector3 targetPos = target.position + BasePos;
			CamRotate = NewRotate;
			Quaternion rotation = Quaternion.Euler(CamRotate);
            CamPosition = Vector3.up * DistanceUp - Vector3.forward * DistanceAway;
            //四位數乘上向量表示轉向，也可以看成以原點旋轉
            CamPosition = rotation * CamPosition + targetPos;
			//transform.position = Vector3.Lerp(transform.position, CamPosition, Time.deltaTime * Speed);
			transform.position = CamPosition;
			transform.rotation = Quaternion.Euler(CamRotate + Vector3.right * Mathf.Atan2(DistanceUp, DistanceAway) * 180 / Mathf.PI);
		}
    }
}
