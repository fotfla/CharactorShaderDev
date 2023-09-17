Shader "Unlit/SpotLight"
{
    Properties
    {
        [HDR]
        _Color("Color", Color) = (1,1,1,1) 
        _NoiseTex("Noise Texture", 3D) = "white"{}
        _NoiseScale("Noise Scale", float ) = 1
        _NoiseSpeed("Noise Speed", float) = 1

        _Fade("Fade", Range(0,1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

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
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
            };

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            float4 _Color;

            sampler3D _NoiseTex;
            float _NoiseScale;
            float _NoiseSpeed;

            float _Fade;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.screenPos.z);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = _Color;
                col *= tex3D(_NoiseTex, i.worldPos * _NoiseScale + float3(0,- _Time.y *_NoiseSpeed,0)).r;

                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy / i.screenPos.w));
                float z = i.screenPos.z;
                float fade = saturate(_Fade * (depth - z));
                col.a *= fade;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
