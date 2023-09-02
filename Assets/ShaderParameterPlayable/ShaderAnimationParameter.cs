using UnityEngine;

[System.Serializable]
public class ShaderAnimationParameter
{
    public PropertyType type;
    public string name;

    // Start Parameter
    public int intParameter0;
    public float floatParameter0;
    public Vector4 vectorParameter0;
    public Color colorParameter0;
    // End Parameter
    public int intParameter1;
    public float floatParameter1;
    public Vector4 vectorParameter1;
    public Color colorParameter1;
}

public enum PropertyType
{
    Int, Float, Vector, Color
}
