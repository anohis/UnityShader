using System;
using System.Collections;
using System.Collections.Generic;
using ToolKit.Math;
using UnityEngine;

namespace GameInput
{
    public class InputHandler : MonoBehaviour
    {
        protected Dictionary<KeyCode, Action<bool>> _handler = new Dictionary<KeyCode, Action<bool>>();
        protected Vector3 _move = Vector3.zero;

        #region MonoBehaviour
        private void Awake()
        {
            Initialize();
        }
        protected virtual void Update()
        {
            transform.position += _move * Time.deltaTime;
            _move = Vector3.zero;
        }
        #endregion

        #region public func
        public virtual void Hanlde(KeyCode code,bool isPress)
        {
            if (_handler.ContainsKey(code))
                _handler[code](isPress);
        }
        #endregion

        #region protected func
        protected virtual void Initialize()
        {
            _handler.Add(KeyCode.W,(isPress)=> 
            {
                _move.z += isPress ? 1 : 0;
                _move.z = MathFunc.Saturate(_move.z, -1, 1);
            });
            _handler.Add(KeyCode.S, (isPress) =>
            {
                _move.z += isPress ? -1 : 0;
                _move.z = MathFunc.Saturate(_move.z, -1, 1);
            });
            _handler.Add(KeyCode.D, (isPress) =>
            {
                _move.x += isPress ? 1 : 0;
                _move.x = MathFunc.Saturate(_move.x, -1, 1);
            });
            _handler.Add(KeyCode.A, (isPress) =>
            {
                _move.x += isPress ? -1 : 0;
                _move.x = MathFunc.Saturate(_move.x, -1, 1);
            });
        }
        #endregion
    }
}