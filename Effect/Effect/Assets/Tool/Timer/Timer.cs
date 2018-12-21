using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

namespace ToolKit.Time
{
    public class Timer : MonoBehaviour
    {
        public float Delay;
        public float Interval;
        public int Count;
        public UnityEvent OnTriggeredCallBack;

        #region MonoBehaviour
        private void OnEnable()
        {
            StartCoroutine(DoTimer());
        }
        #endregion

        #region private func
        private IEnumerator DoTimer()
        {
            yield return WaitDelay();
            while (Count > 0)
            {
                yield return WaitInterval();
                Count--;
            }
        }
        private IEnumerator WaitDelay()
        {
            yield return new WaitForSeconds(Delay);
        }
        private IEnumerator WaitInterval()
        {
            if(OnTriggeredCallBack!=null)
                OnTriggeredCallBack.Invoke();
            yield return new WaitForSeconds(Interval);
        }
        #endregion
    }
}