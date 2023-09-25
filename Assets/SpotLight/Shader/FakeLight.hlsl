#ifndef FAKESPOTLIGHT_HLSL
#define FAKESPOTLIGHT_HLSL
static const int maxCount = 8;
float4x4 _UdonSpotLightData[maxCount];

// _UdonSpotLightData[][0].xyz LightPos
// _UdonSpotLightData[][1].xyz LightDir
// _UdonSpotLightData[][2].x Range
// _UdonSpotLightData[][2].y Angle
// _UdonSpotLightData[][2].z Intensity
// _UdonSpotLightData[][3] Color

float3 FakeSpotLight(float3 worldPos, float3 worldNormal, int index)
{
    float3 diff = worldPos - _UdonSpotLightData[index][0].xyz;
    float distance = length(diff);
    float3 dir = normalize(diff);
    float angle = dot(dir, _UdonSpotLightData[index][1].xyz);
    if (distance > _UdonSpotLightData[index][2].x || angle < _UdonSpotLightData[index][2].y)
        return 0;
    float atten = 1 / (distance + 0.0001);
    float ndl = saturate(dot(-dir, worldNormal));
    float falloff = smoothstep(_UdonSpotLightData[index][2].y, 1, angle);
    return atten * falloff * ndl * _UdonSpotLightData[index][3].rgb * _UdonSpotLightData[index][3].a * _UdonSpotLightData[index][2].z;
}

float3 FakeSpotLights(float3 worldPos, float3 worldNormal)
{
    float3 c = 0;
            [unroll]
    for (int i = 0; i < maxCount; i++)
    {
        c += FakeSpotLight(worldPos, worldNormal, i);
    }
    return c;
}
#endif