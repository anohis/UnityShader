using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace GameInput
{
    public class InputReceiver : MonoBehaviour
    {
        public InputHandler Handler;

        #region MonoBehaviour
        private void Update()
        {
            HandleInput();
        }
        #endregion

        #region protected func
        protected virtual void HandleInput()
        {
            Handler.Hanlde(KeyCode.W, Input.GetKey(KeyCode.W));
            Handler.Hanlde(KeyCode.S, Input.GetKey(KeyCode.S));
            Handler.Hanlde(KeyCode.A, Input.GetKey(KeyCode.A));
            Handler.Hanlde(KeyCode.D, Input.GetKey(KeyCode.D));
        }
        #endregion
    }
}