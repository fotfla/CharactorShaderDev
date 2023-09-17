Shader "Custom/SpotLightTest"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows

        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        static const int maxCount = 8;
        float4x4 _UdonSpotLightData[maxCount];

        float3 FakeSpotLight(float3 worldPos, float3 worldNormal, int index){
            float3 diff = worldPos - _UdonSpotLightData[index][0].xyz;
            float distance = length(diff);
            float3 dir = normalize(diff);
            float angle = dot(dir,  _UdonSpotLightData[index][1].xyz);
            if(distance >  _UdonSpotLightData[index][2].x || angle <  _UdonSpotLightData[index][2].y) return 0;
            float atten = 1 / (distance + 0.0001);
            float ndl = saturate(dot(-dir, worldNormal));
            float falloff = smoothstep( _UdonSpotLightData[index][2].y, 1, angle);
            return atten * falloff *  ndl * _UdonSpotLightData[index][3].rgb * _UdonSpotLightData[index][3].a *  _UdonSpotLightData[index][2].z;
        }

        float3 FakeSpotLights(float3 worldPos, float3 worldNormal){
            float3 c = 0;
            [unroll]
            for(int i = 0; i < maxCount; i ++){
                c += FakeSpotLight(worldPos, worldNormal, i);
            }
            return c;
        }

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            o.Emission = FakeSpotLights(IN.worldPos, o.Normal);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
