Shader "Unlit/ScreenSpaceLightShaft"
{
    Properties
    {
        _DepthTex("Depth",2D) = "black"{}
        _NoiseTex("Noise", 3D) = "white" {}

        _Size("Size", float) = 10
        _Near("Near", float) = 0.3
        _Far("Far", float) = 50

        _StepDist("Step Distamce", float) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent+1000"}
        LOD 100
        Cull Front
        ZTest Always
        //ZWrite Off
        Blend SrcAlpha One

        // GrabPass{"_CameraColorTexture"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            #define ITERATION 64

             sampler2D _DepthTex;
             float4x4 _DepthCameraWorldToObject;
             float _Far;
             float _Near;

             sampler3D _NoiseTex;

             float _StepDist;

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            // UNITY_DECLARE_SCREENSPACE_TEXTURE(_CameraColorTexture);

            float _Size;

            struct appdata
            {
                float4 vertex : POSITION;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2;
                float4 screenPos : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            struct Ray{
                float3 origin;
                float3 dir;
                float tmin;
                float tmax;
             };

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float2 screenPos = v.vertex.xy / v.vertex.w *_ScreenParams.x;
                screenPos.y *= _ScreenParams.y / _ScreenParams.x;
                o.vertex = float4(screenPos, 0, 1);
                // o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, o.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            inline float NearPlaneDistance(float4 projPos){
				projPos.xy /= projPos.w;
				projPos.xy = (projPos.xy - 0.5) * 2.0;
				projPos.x *= _ScreenParams.x / _ScreenParams.y;
				float3 n = normalize(float3(projPos.xy, abs(UNITY_MATRIX_P[1][1])));
				return _ProjectionParams.y / n.z;
		    }

            float Linear01DepthFromCamera(float depth){
                float y = _Far / _Near;
                float x = -1 + y;
                return 1.0 / (x * depth + y);
             }

            float map(float3 p){
                float3 pos = mul(_DepthCameraWorldToObject, float4(p,1));
                float2 uv = saturate(pos.xy  / _Size + 0.5);
                float depth = Linear01DepthFromCamera(SAMPLE_DEPTH_TEXTURE(_DepthTex, uv));
                depth = depth < pos.z ? 0.0 : 1.0;
                return 1;
            }

            float4 fogColor(float3 p){
                return tex3D(_NoiseTex, p).r;
             }

            float4 trace(Ray ray){
                float3 ro = ray.origin;
                float l = 0;

                float end = ray.tmax;

                float stepDist = _StepDist;
                float3 step = stepDist * ray.dir;

                float t = 0.0;
                float4 output = 0;
                for(int i = 0; i < ITERATION; i++){
                    t = map(ro);
                    float4 c = fogColor(ro) * t;
                    output += (1.0 - output.a) * c;
                    if(output.a > 1) break;
                    ro += step;
                    l += stepDist;
                    //if(l > end) {
                    //    t = map(ray.origin + ray.dir * end);
                    //    c = fogColor(ro) * t;
                    //    output += (1.0 - output.a) * c;
                    //    break;
                    //}
                }
                return output;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 col = float4(0,0,0,0);

                Ray ray = (Ray)0;
                float3 rd = i.worldPos - _WorldSpaceCameraPos;
                ray.dir = normalize(rd);

                float3 nearPlanePos = _WorldSpaceCameraPos + NearPlaneDistance(i.screenPos) * normalize(rd);
                ray.origin = nearPlanePos;

                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy / i.screenPos.w));
				float3 worldPos = depth * normalize(rd) / dot(normalize(rd),- UNITY_MATRIX_V[2].xyz) + _WorldSpaceCameraPos;
                float tmax2 = length(ray.origin - worldPos);
                ray.tmax = tmax2;

                col = trace(ray);

                //return float4(pos, 1);
                //return float4(depth,depth,depth,1);
                return saturate(col);
            }
            ENDCG
        }
    }
}
