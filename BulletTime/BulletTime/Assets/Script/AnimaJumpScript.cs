using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AnimaJumpScript : StateMachineBehaviour {

    /// <summary>
    /// 以物件面相方向做角度修正
    /// </summary>
    public float JumpDir = 0;
    public float JumpPower = 1;
    public float MovePower = 1;
    public float Distance = 1;
    public bool AutoApplyRootMotion = true;

    public float MoveSpeed = 0;
    /// <summary>
    /// 速度衰弱值
    /// </summary>
    public float MoveSpeedAlpha = 0;

    private Vector3 CharacterForward = Vector3.forward;
    private Rigidbody CharacterRigidbody;
    private bool IsFirst = true;
    private float CurrSpeed = 0;
    private Vector3 TargetPos;

    override public void OnStateEnter(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
    {
        if(AutoApplyRootMotion)
            animator.applyRootMotion = false;
        CharacterRigidbody = animator.GetComponent<Rigidbody>();
        IsFirst = true;
        CharacterForward = animator.transform.forward;
        CurrSpeed = MoveSpeed;
        Vector2 newDir = new Vector2(CharacterForward.x, CharacterForward.z).AddAngle(JumpDir);
        CharacterForward = new Vector3(newDir.x, CharacterForward.y, newDir.y);
        TargetPos = animator.transform.position + new Vector3(CharacterForward.x, 0, CharacterForward.z) * Distance;
    }

    // OnStateUpdate is called on each Update frame between OnStateEnter and OnStateExit callbacks
    override public void OnStateUpdate(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
    {
        if (IsFirst && !animator.applyRootMotion)
        {
            IsFirst = false;
            CharacterRigidbody.AddForce(new Vector3(CharacterForward.x * MovePower, JumpPower, CharacterForward.z * MovePower),ForceMode.Impulse);
        }
        if (CurrSpeed > 0)
        {
            animator.transform.position = Vector3.Lerp(animator.transform.position, TargetPos, CurrSpeed * Time.deltaTime);
            CurrSpeed = Tool.Lerp(CurrSpeed, 0, MoveSpeedAlpha * Time.deltaTime);
        }
    }

	// OnStateExit is called when a transition ends and the state machine finishes evaluating this state
	override public void OnStateExit(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
    {
        if (AutoApplyRootMotion)
            animator.applyRootMotion = true;
    }

    // OnStateMove is called right after Animator.OnAnimatorMove(). Code that processes and affects root motion should be implemented here
    //override public void OnStateMove(Animator animator, AnimatorStateInfo stateInfo, int layerIndex) {
    //
    //}

    // OnStateIK is called right after Animator.OnAnimatorIK(). Code that sets up animation IK (inverse kinematics) should be implemented here.
    //override public void OnStateIK(Animator animator, AnimatorStateInfo stateInfo, int layerIndex) {
    //
    //}

    
}
