Shader "Unlit/VolumetricVolumeShadow"
{
    Properties
    {
        _DepthTex("Depth", 2D) = "black"{}
        _Intensity("Intensity",float) = 1.0
		_JitterIntensity("Jitter Intensity",float) = 0.001

		_Near("Near", float) = 0.3
		_Far("Far", float) = 20
		_Size("Size", float) = 10
    }
    SubShader
    {
	    Tags{"RenderType"="Transparent" "Queue"="Transparent+100"}
        Cull Off
		ZWrite Off
		ZTest Always
		//Blend SrcAlpha One
		Blend DstColor Zero

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #define ITERATION 64

            #include "UnityCG.cginc"
            #include "NoiseShader/HLSL/SimplexNoise3D.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD1;
				float4 localPos : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
            };

			struct Ray{
				float3 origin;
				float3 dir;
				float tmax;
				float tmin;
			};

			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

			sampler2D _DepthTex;
            float4 _DepthTex_ST;

			 float4x4 _DepthCameraWorldToObject;
             float _Far;
             float _Near;
			 float _Size;

			float3 _Offset;
			float _JitterIntensity;
			float _Intensity;
			float _Attenuation;

			float2x2 rot(float a){
				float c = cos(a),s = sin(a);
				return float2x2(c,s,-s,c);
			}

            float fbm(float3 p){
				float a = 1.25;
				float n = 0;

				[unroll]
				for(int i = 0;i < 3;i++){
					n += a * snoise(p);
					a *= 0.25;
					p *= 1.5;
					p.xy = mul(rot(UNITY_PI * 0.6),p.xy);
				}

				return n;
			}

			inline float3 localize(float3 vec){
				return mul(unity_WorldToObject,vec);
			}

			float rnd(float3 p){
				return frac(45313.61414 * sin(dot(p, float3(12.631,15.613,17.563))));
			}

            float Linear01DepthFromCamera(float depth){
                float y = _Far / _Near;
                float x = 1 - _Far / _Near;
				#if defined(UNITY_REVERSED_Z)
				y = 1;
				x = - 1 + _Far/_Near;
				#endif
                return 1.0 / (x * depth + y);
             }

            float map(float3 p){
				p = mul(unity_ObjectToWorld, float4(p,1));
                float3 pos = mul(_DepthCameraWorldToObject, float4(p,1));
                float2 uv = saturate(pos.xy  / _Size * 0.5 + 0.5);
                float depth = SAMPLE_DEPTH_TEXTURE_LOD(_DepthTex, float4(uv, 0, 3));
				float z = 1 - (pos.z - _Near) / (_Far - _Near);
                depth = depth < z ? 0.0 : 1.0;
				return _Intensity * depth;
			}

			float4 fogColor(float3 p){
				return 1;
		    }

            float4 trace(Ray ray){
				float3 ro = ray.origin;
				float jitter = rnd(ro) * _JitterIntensity;
				float3 lstep = ray.dir * ray.tmax/(float)ITERATION * (1 - jitter);
				float t = 0.0;
				float4 output = float4(0,0,0,0);
				float d = 0;
				[unroll]
				for(int i = 0; i < ITERATION; i++){
					t = map(ro);
					float4 color = fogColor(ro) * t;
					output += (1.0 - output.a) * color * 0.1;
					if(output.a > 1)break;
                    ro += lstep;
				}
				return output;
			}

			void intersection(inout Ray ray){
				float3 invDir = 1 / ray.dir;
				float3 t1 = (-0.5 - ray.origin) * invDir;
				float3 t2 = (+0.5 - ray.origin) * invDir;

				float3 tmin3 = min(t1, t2);
                float2 tmin2 = max(tmin3.xx, tmin3.yz);
                ray.tmin = max(tmin2.x, tmin2.y);

				float3 tmax3 = max(t1,t2);
				float2 tmax2 = min(tmax3.xx,tmax3.yz);
				ray.tmax = min(tmax2.x,tmax2.y);
			}

			inline bool IsInnerBox(float3 pos, float3 scale){
				return abs(pos.x) < scale.x * 0.5 && abs(pos.y) < scale.y * 0.5 && abs(pos.z) < scale.z * 0.5;
			}

			inline void alignment(inout Ray ray, float3 dir){
				float3 forward = - UNITY_MATRIX_V[2].xyz;
				float3 worldDir = normalize(dir);
				float ratio = 1 / dot(worldDir,forward);
				float stepDist = 1.0 / (float)ITERATION * ratio;
				float camDist = length(dir);
				float startOffset = stepDist - fmod(camDist, stepDist);
				ray.origin -= mul((float3x3)unity_WorldToObject, worldDir * startOffset);
			}

			float NearPlaneDistance(float4 projPos){
				projPos.xy /= projPos.w;
				projPos.xy = (projPos.xy - 0.5) * 2.0;
				projPos.x *= _ScreenParams.x / _ScreenParams.y;
				float3 n = normalize(float3(projPos.xy, abs(UNITY_MATRIX_P[1][1])));
				return _ProjectionParams.y / n.z;
		    }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.localPos = v.vertex;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f vert, fixed facing : VFACE) : SV_Target
            {
				float4 col = float4(0,0,0,0);

                Ray ray;
				float3 rd = vert.worldPos - _WorldSpaceCameraPos;
				ray.dir = normalize(localize(rd));

				float3 scale = float3(length(UNITY_MATRIX_M[0].xyz),length(UNITY_MATRIX_M[1].xyz),length(UNITY_MATRIX_M[2].xyz));
				float3x3 rot = (float3x3)UNITY_MATRIX_M;
				rot[0].xyz /= scale.x;
				rot[1].xyz /= scale.y;
				rot[2].xyz /= scale.z;

				float3 pos = mul(unity_ObjectToWorld,float4(0,0,0,1)).xyz;
				
				ray.origin = vert.localPos;
				float3 worldOrigin = vert.worldPos;
				float3 nearPlanePos = (_WorldSpaceCameraPos - pos)  + NearPlaneDistance(vert.screenPos) * normalize(rd);
				if(IsInnerBox(nearPlanePos, scale)) {
					ray.origin = localize(nearPlanePos);
					worldOrigin = nearPlanePos;
					if(facing > 0) clip( -1);
				} else {
					if(facing < 0) clip(- 1);
				}

				intersection(ray);
				alignment(ray,rd);

				float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, vert.screenPos.xy / vert.screenPos.w));
				float tmax2 = length(ray.origin - localize(depth * normalize(rd) + _WorldSpaceCameraPos));
				ray.tmax = min(ray.tmax, tmax2);
			
				col = trace(ray);
				col.rgb = 1 - col.rgb;

                return col;
            }
            ENDCG
        }
    }
}
