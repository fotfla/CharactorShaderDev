using UnityEngine;
using UnityEngine.Playables;
using UnityEngine.Timeline;

[TrackColor(0.7028302f, 0.8514151f, 1f)]
[TrackClipType(typeof(ShaderParameterPlayableClip))]
[TrackBindingType(typeof(Renderer))]
public class ShaderParameterPlayableTrack : TrackAsset
{
    public override Playable CreateTrackMixer(PlayableGraph graph, GameObject go, int inputCount)
    {
        return ScriptPlayable<ShaderParameterPlayableMixerBehaviour>.Create (graph, inputCount);
    }
}
