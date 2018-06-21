using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SuperJumpScript : StateMachineBehaviour
{
    public float DodgeAngle;
    public float Distance;
    public float Speed = 1;

    private PeopleController Character;
    private Vector3 CharacterForward;
    private Vector3 TargetPos;
    // OnStateEnter is called before OnStateEnter is called on any state inside this state machine
    override public void OnStateEnter(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
    {
    }


    // OnStateUpdate is called before OnStateUpdate is called on any state inside this state machine
    override public void OnStateUpdate(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
    {
    }

	// OnStateExit is called before OnStateExit is called on any state inside this state machine
    //override public void OnStateExit(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
    //{

    //}

    // OnStateMove is called before OnStateMove is called on any state inside this state machine
    //override public void OnStateMove(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
    //{

    //}

    // OnStateIK is called before OnStateIK is called on any state inside this state machine
    //override public void OnStateIK(Animator animator, AnimatorStateInfo stateInfo, int layerIndex) {
    //
    //}

    // OnStateMachineEnter is called when entering a statemachine via its Entry Node
    override public void OnStateMachineEnter(Animator animator, int stateMachinePathHash)
    {
        Character = animator.GetComponent<PeopleController>();
        Character.IsStopMoveControl = true;
        animator.applyRootMotion = false;

        CharacterForward = animator.transform.forward;
        Vector2 newDir = new Vector2(CharacterForward.x, CharacterForward.z).AddAngle(DodgeAngle);
        CharacterForward = new Vector3(newDir.x, CharacterForward.y, newDir.y);
    }

    // OnStateMachineExit is called when exiting a statemachine via its Exit Node
    override public void OnStateMachineExit(Animator animator, int stateMachinePathHash)
    {
        Character.IsStopMoveControl = false;
        Character.IsSkilling = false;
        animator.applyRootMotion = true;
    }
}
