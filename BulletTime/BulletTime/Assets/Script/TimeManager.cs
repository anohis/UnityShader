using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class UnTimeScaleBehaviour : MonoBehaviour
{
    void Start()
    {
        TimeManager.Instance.OnPause += OnPause;
        DoStart();
    }
    protected abstract void OnPause(bool value);
    protected abstract void DoStart();
}

public class TimeManager : MonoBehaviour
{
    public static TimeManager Instance
    {
        get
        {
            if (instance == null)
            {
                GameObject obj = new GameObject();
                instance = obj.AddComponent<TimeManager>();
            }
            return instance;
        }
    }

    private static TimeManager instance = null;

    private class TimeScaleRequest
    {
        public float TargetScale = 0;
        public float CurrScale = 0;
        public float TargetTime = 0;
        public float StartTime = 0;
        public float CurrTime = 0;
    }

    public float TransferTime = 1;
    public bool Pause
    {
        set
        {
            IsPause = value;
            OnPause(value);
        }
        get { return IsPause; }
    }

    public delegate void OnPauseDelegate(bool value);
    public OnPauseDelegate OnPause;

    private List<TimeScaleRequest> TimeScaleReqs = new List<TimeScaleRequest>();
    private bool IsPause = false;

    void Awake()
    {
        if (instance == null)
            instance = this;
        else
            Destroy(this);
    }

    void Update()
    {
        if (Pause)
        {
            Time.timeScale = 0;
            return;
        }
        if (TimeScaleReqs.Count == 0)
        {
            Time.timeScale = 1;
            return;
        }
        TimeScaleRequest req = TimeScaleReqs[0];
        req.CurrTime = Time.realtimeSinceStartup;

        if (req.CurrTime > req.TargetTime + TransferTime)
        {
            Time.timeScale = 1;
            TimeScaleReqs.Remove(req);
            return;
        }
        else if(req.CurrTime >= req.StartTime && req.CurrTime <= req.TargetTime)
            req.CurrScale = req.TargetScale;
        else
        {
            float duringTime = TransferTime + req.CurrTime;

            if (req.CurrTime < req.StartTime)
                duringTime -= req.StartTime;
            else
                duringTime -= req.TargetTime;

            float timeRate = duringTime / (TransferTime * 2);

            if (req.TargetScale > 1)
                req.CurrScale = 1 + Mathf.Sin(180 * timeRate);
            else if (req.TargetScale < 1)
                req.CurrScale = 1 + Mathf.Sin(180 * (timeRate + 1));
        }

        Time.timeScale = req.CurrScale;
    }

    public void SetTimeScale(float duringTime,float scale)
    {
        int idx = 0;
        foreach (TimeScaleRequest req in TimeScaleReqs)
        {
            if (scale >= req.TargetScale) break;
            idx++;
        }

        float startTime = Time.realtimeSinceStartup + TransferTime;
        float targetTime = startTime + duringTime;

        if (TimeScaleReqs.Count == idx || scale > TimeScaleReqs[idx].TargetScale)
        {
            TimeScaleRequest req = new TimeScaleRequest()
            {
                TargetScale = scale,
                TargetTime = targetTime,
                StartTime = startTime
            };
            TimeScaleReqs.Insert(idx, req);
        }
        else if(scale == TimeScaleReqs[idx].TargetScale)
            TimeScaleReqs[idx].TargetTime = targetTime;
    }
}
