Shader "Unlit/SpotLight"
{
    Properties
    {
        [HDR]
        _Color("Color", Color) = (1,1,1,1) 
        _NoiseTex("Noise Texture", 3D) = "white"{}
        _NoiseScale("Noise Scale", float ) = 1
        _NoiseIntensity("Noise Intensity", Range(0,1)) = 1
        _NoiseSpeed("Noise Speed", float) = 1
      
        _LightIntensity("LightIntensity", float) = 1
        _Intensity("Intensity", float) = 1

        _Fade("Fade", Range(0.01,1)) = 0.1
        _Power("Power", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "DisableBatching"="True"}
        LOD 100
        Cull Off
        ZWrite Off
        // Blend SrcAlpha OneMinusSrcAlpha
        Blend One One

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float3 normal : NORMAL;
                float3 localPos : TEXCOORD4;
            };

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            float4 _Color;

            sampler3D _NoiseTex;
            float _NoiseScale;
            float _NoiseIntensity;
            float _NoiseSpeed;

            float _Fade;
            float _LightIntensity;
            float _Intensity;

            float _Power;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = v.normal;
                o.localPos = v.vertex;
                COMPUTE_EYEDEPTH(o.screenPos.z);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i, fixed facing : VFACE) : SV_Target
            {
                fixed4 col = _Color * _LightIntensity * _Intensity;
                float n = tex3D(_NoiseTex, i.worldPos * _NoiseScale + float3(0,- _Time.y *_NoiseSpeed,0)).r;
                col *= lerp(1, n, _NoiseIntensity);

                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy / i.screenPos.w));
                float z = i.screenPos.z;
                float fade = saturate(_Fade * (depth - z)) * smoothstep(-0.03, -0.04, i.localPos.y);
                col *= fade;

                float h = saturate(1 + i.localPos.y);
                col *= h * h;

                float3 scale = float3(length(UNITY_MATRIX_M[0].xyz), length(UNITY_MATRIX_M[1].xyz), length(UNITY_MATRIX_M[2].xyz));
                float3 normal = normalize(i.normal) / scale;



                if(facing < 0){
                    float3 normalWS = UnityObjectToWorldNormal(i.normal);
                    float vdn0 = max(0, dot(-normalWS, normalize(_WorldSpaceCameraPos - i.worldPos)));
                   
                    float3 localViewDir =  normalize(normalize(mul((float3x3)unity_WorldToObject, (_WorldSpaceCameraPos - i.worldPos)) / scale));
                    float vdn = max(0, dot(-normalize(normal), normalize(localViewDir)));
                    col *= pow(vdn, _Power);
                     col.rgb += smoothstep(-0.1, -0.03, i.localPos.y) * _Intensity * _Color * vdn0 * lerp(1, n, _NoiseIntensity) * 3;
                } else {
                     float3 localViewDir =  normalize(normalize(mul((float3x3)unity_WorldToObject, (_WorldSpaceCameraPos - i.worldPos)) / scale));
                     float vdn = max(0, dot(normalize(normal), normalize(localViewDir)));
                     col *= pow(vdn, _Power);
                }

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
