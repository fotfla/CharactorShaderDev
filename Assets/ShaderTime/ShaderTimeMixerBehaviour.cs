using System;
using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Timeline;

public class ShaderTimeMixerBehaviour : PlayableBehaviour
{
    private readonly int UdonTimeProperty = Shader.PropertyToID("_UdonTime");

    public override void ProcessFrame(Playable playable, FrameData info, object playerData)
    {
        int inputCount = playable.GetInputCount();
        for (int i = 0; i < inputCount; i++)
        {
            float inputWeight = playable.GetInputWeight(i);
            ScriptPlayable<ShaderTimeBehaviour> inputPlayable = (ScriptPlayable<ShaderTimeBehaviour>)playable.GetInput(i);

            var time = inputPlayable.GetTime();
            Shader.SetGlobalFloat(UdonTimeProperty, (float)time);
        }
    }
}
