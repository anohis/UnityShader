using UnityEngine;

public class BulletManager : MonoBehaviour
{
    public Transform TargetTransform;
    public float BulletInterval = 1;
    public float BulletSpeed = 1;

    private float LastTime;

    void Start ()
    {
        LastTime = Time.time;
    }

    void Update()
    {
        if (Time.time - LastTime > BulletInterval)
        {
            //Debug.Log(Time.time);
            LastTime = Time.time;
        }
    }
}
