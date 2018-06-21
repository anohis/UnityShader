using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PeopleController : UnTimeScaleBehaviour
{
    public Camera CharacterCarmera;
    public bool IsStopMoveControl = false;
    public float WalkSpeed = 1;
    public float RunSpeed = 2;
    public bool IsSkilling = false;

    private float Hor, Ver;
    private Animator SelfAnima;
    private Rigidbody SelfRigidbody;
    private bool IsRun = false;
    private AfterimageEffect Afterimage;

    protected override void DoStart()
    {
        SelfAnima = GetComponent<Animator>();
        SelfRigidbody = GetComponent<Rigidbody>();
        Afterimage = GetComponent<AfterimageEffect>();

        IsSkilling = false;
    }

    protected override void OnPause(bool value)
    {
        SelfAnima.enabled = !value;
    }

    void FixedUpdate()
    {
        UpdateMove();
        if (!IsSkilling)
            UpdateSkill();
    }

    float TransferTo180(float angle)
    {
        while (angle > 180)
            angle -= 360;
        return angle;
    }

    private void DoMove()
    {
        if (IsStopMoveControl) return;

        SelfAnima.SetBool("IsWalk", true);
        SelfAnima.SetFloat("BlendTreeX", Ver * (IsRun ? 2 : 1));
        SelfAnima.SetFloat("BlendTreeY", Hor * (IsRun ? 2 : 1));

        float tempHor = Hor;
        float tempVer = Ver;
        if (Ver < 0)
        {
            tempHor *= -1;
            tempVer *= -1;
        }

        float dir = CharacterCarmera.transform.eulerAngles.y + Mathf.Atan2(tempHor, tempVer) * Mathf.Rad2Deg;

        //轉向做平滑比較不突兀
        this.transform.rotation = Quaternion.Slerp(this.transform.rotation,Quaternion.Euler(0, dir, 0), Time.fixedDeltaTime * 10);

        //配合動畫剛起步會慢一些
        float stepSpeed = Mathf.Max(Mathf.Abs(Hor), Mathf.Abs(Ver));
        if (IsRun)
        {
            if (Ver >= 0)
            {
                stepSpeed *= RunSpeed;
                SelfAnima.speed = (1.0f / 0.8f) * WalkSpeed;
            }
            else
            {
                stepSpeed *= RunSpeed / 2;
                SelfAnima.speed = (1.0f / 0.8f) * WalkSpeed * 2;
            }
        }
        else
            SelfAnima.speed = (1.0f / 0.8f) * WalkSpeed;

        transform.position += transform.forward * Mathf.Sign(Ver) * Mathf.Abs(stepSpeed) * Time.fixedDeltaTime * WalkSpeed;
    }

    private void DoIdle()
    {
        SelfAnima.SetBool("IsWalk", false);
    }

    private void UpdateMove()
    {
        Hor = Input.GetAxis("Horizontal");
        Ver = Input.GetAxis("Vertical");
        if (Input.GetKeyDown(KeyCode.LeftAlt))
            IsRun = !IsRun;
        if (Hor != 0 || Ver != 0)
            DoMove();
        else
            DoIdle();
    }

    private void UpdateSkill()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            SelfAnima.SetBool("IsSuperJump", true);
            IsSkilling = true;
            //Afterimage.Create();
            //TimeManager.Instance.SetTimeScale(5,0.5f);
        }
        if (Input.GetKeyDown(KeyCode.Z))
            TimeManager.Instance.Pause = true;
        if (Input.GetKeyDown(KeyCode.X))
            TimeManager.Instance.Pause = false;
    }

}
