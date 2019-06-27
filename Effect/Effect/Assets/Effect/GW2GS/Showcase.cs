using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Effect.GS
{
    public class Showcase : MonoBehaviour
    {
        [SerializeField] private Animator _animator;


        private const float _comboLimitTime = 1;

        private readonly int _attackHash = Animator.StringToHash("Attack");
        private readonly int _lightAttackHash = Animator.StringToHash("LightAttack");
        private readonly int _attackIndexHash = Animator.StringToHash("AttackIndex");
        private readonly int _hashStateTimeHash = Animator.StringToHash("StateTime");
        private readonly int _forwardSpeedHash = Animator.StringToHash("ForwardSpeed");

        private bool _wantLightAttack;

        private float _comboTime = 0;
        private int _comboIndex = 0;
        private bool _isRun;

        public void LightAttack()
        {
            _wantLightAttack = true;
        }
        public void Run()
        {
            _isRun = !_isRun;
            _animator.SetFloat(_forwardSpeedHash, _isRun ? 10.0f : 0.0f);
        }

        private void Update()
        {
            _animator.SetFloat(_hashStateTimeHash, Mathf.Repeat(_animator.GetCurrentAnimatorStateInfo(0).normalizedTime, 1f));

            CheckComboTime(Time.deltaTime);
            CheckAttack();
        }
        private void CheckComboTime(float deltaTime)
        {
            _comboTime += deltaTime;
            if (_comboTime > _comboLimitTime)
            {
                _animator.SetInteger(_attackIndexHash, 0);
            }
        }
        private void CheckAttack()
        {
            _animator.ResetTrigger(_attackHash);
            _animator.ResetTrigger(_lightAttackHash);

            if (_wantLightAttack)
            {
                _animator.SetTrigger(_lightAttackHash);
                _animator.SetTrigger(_attackHash);
                _comboTime = 0;
            }

            _wantLightAttack = false;
        }
    }
}