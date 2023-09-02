using System;
using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Timeline;

[Serializable]
public class ShaderParameterPlayableClip : PlayableAsset, ITimelineClipAsset
{
    public ShaderParameterPlayableBehaviour template = new ShaderParameterPlayableBehaviour();

    public ShaderAnimationParameter[] parameter;

    public ClipCaps clipCaps
    {
        get { return ClipCaps.All; }
    }

    public override Playable CreatePlayable(PlayableGraph graph, GameObject owner)
    {
        var playable = ScriptPlayable<ShaderParameterPlayableBehaviour>.Create(graph, template);
        ShaderParameterPlayableBehaviour clone = playable.GetBehaviour();
        return playable;
    }
}
