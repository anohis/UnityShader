using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace ToolKit.Math
{
    public static class MathFunc
    {
        public static float Saturate(float value, float min, float max)
        {
            if (value < min)
                value = min;
            else if (value > max)
                value = max;

            return value;
        }
        public static float Lerp(float from, float to, float rate)
        {
            rate = Mathf.Clamp(rate, 0, 1);
            return from + (to - from) * rate;
        }
        /// <summary>
        /// 方向v轉angle角度
        /// </summary>
        /// <param name="v"></param>
        /// <param name="angle"></param>
        /// <returns></returns>
        public static Vector2 AddAngle(this Vector2 v, float angle)
        {
            float newDirRad = (Mathf.Atan2(v.x, v.y) * Mathf.Rad2Deg + angle) * Mathf.Deg2Rad;
            return new Vector2(Mathf.Sin(newDirRad), Mathf.Cos(newDirRad));
        }
    }

}