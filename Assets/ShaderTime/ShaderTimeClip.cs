using System;
using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Timeline;

[Serializable]
public class ShaderTimeClip : PlayableAsset, ITimelineClipAsset
{
    public ShaderTimeBehaviour template = new ShaderTimeBehaviour ();

    public ClipCaps clipCaps
    {
        get { return ClipCaps.Looping; }
    }

    public override Playable CreatePlayable (PlayableGraph graph, GameObject owner)
    {
        var playable = ScriptPlayable<ShaderTimeBehaviour>.Create (graph, template);
        ShaderTimeBehaviour clone = playable.GetBehaviour ();
        return playable;
    }
}
