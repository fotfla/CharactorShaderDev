﻿Shader "Unlit/ConeInnerTest"
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
        ZWrite On

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
            float4 _UdonLightData;
            float4 _UdonLightColor;

            float3 FakeSpotLight(float3 worldPos, float3 worldNormal){
                float3 diff = worldPos - _UdonLightPos;
                float distance = length(diff);
                float3 dir = normalize(diff);
                float angle = dot(dir, _UdonLightDir);
                if(distance > _UdonLightData.x || angle < _UdonLightData.y) return 0;
                float atten = 1 / (distance + 0.0001);
                float ndl = saturate(dot(-dir, worldNormal));
                float falloff = smoothstep(_UdonLightData.y, 1, angle);
                return atten * falloff *  ndl * _UdonLightColor.rgb * _UdonLightColor.a * _UdonLightData.z;
            }

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
                col.rgb += FakeSpotLights(i.worldPos, i.normal);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
