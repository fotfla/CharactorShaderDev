Shader "Unlit/ConeInnerTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color", Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2;
                float3 normal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            float3 _UdonLightDir;
            float3 _UdonLightPos;
            float _UdonSpotAngle;
            float _UdonLightRange;
            float4 _UdonLightColor;

            float3 FakeSpotLight(float3 worldPos, float3 worldNormal){
                float3 diff = worldPos - _UdonLightPos;
                float distance = length(diff);
                float3 dir = normalize(diff);
                float angle = dot(dir, _UdonLightDir);
                if(distance > _UdonLightRange || angle < _UdonSpotAngle) return 0;
                float atten = 1 / (distance + 0.0001);
                float ndl =saturate(dot(-dir, worldNormal));
                float falloff = smoothstep(_UdonSpotAngle, 1, angle);
                return atten * falloff *  ndl * _UdonLightColor.rgb * _UdonLightColor.a;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = normalize(UnityObjectToWorldNormal(v.normal));
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                col.rgb += FakeSpotLight(i.worldPos, i.normal);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
