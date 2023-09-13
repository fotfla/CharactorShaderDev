Shader "Unlit/VolumetricSpotLight"
{
    Properties
    {
        _DepthTex("Depth", 2D) = "black"{}
        _Intensity("Intensity",float) = 1.0
		_JitterIntensity("Jitter Intensity",float) = 0.001
		_Attenuation("Attenuation",float) = 0.25

		_Near("Near", float) = 0.3
		_Far("Far", float) = 20
    }
    SubShader
    {
	    Tags{"RenderType"="Transparent" "Queue"="Transparent+100"}
        Cull off
		Blend SrcAlpha One

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #define ITERATION 32

            #include "UnityCG.cginc"
            #include "NoiseShader/HLSL/SimplexNoise3D.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
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

			sampler2D _DepthTex;
            float4 _DepthTex_ST;

			float3 _Offset;
			float _JitterIntensity;
			float _Intensity;
			float _Attenuation;

			float _Far;
			float _Near;

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

            inline float Linear01Depth02(float depth){
				float far = _Far;
				float near = _Near;
				float y = far/near;
				float x = -1 + far/near; 
				#if defined(UNITY_REVERSED_Z)
				  y = 1;
				  x = 66;
				#endif
				float z = x/far;
				float w = y/far; 
				return 1.0 / (x * depth + y);
			}

            float map(float3 p){
				float2 uv = p.xy / lerp(_Near, _Far,  (p.z - _Near) / (_Far - _Near));
				uv.y += 0.5;
				uv.x = 0.25 - uv.x;
				uv = saturate(uv);
				float depth = Linear01Depth02(SAMPLE_DEPTH_TEXTURE(_DepthTex, uv));

				depth = depth < p.z ? 0.0 : 1.0;
				depth *= pow(0.5 + p.y, _Attenuation);
				float n = fbm(p * 5.0 - _Time.y * float3(0.1,0.5,0.2)) * 0.3 + 0.7;
				return _Intensity * depth * n;
			}

            float4 trace(Ray ray){
				float3 ro = ray.origin;
				float jitter = rnd(ro) * _JitterIntensity;
				float3 lstep = ray.dir * ray.tmax/(float)ITERATION * (1 - jitter);
				float t = 0.0;
				float4 color;
				float4 output = float4(0,0,0,0);
				float d = 0;
				[unroll]
				for(int i = 0; i < ITERATION; i++){
					t = map(ro);
					float4 color = 1 * t;
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.localPos = v.vertex;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f vert) : SV_Target
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
				
				ray.origin = IsInnerBox(_WorldSpaceCameraPos - pos, scale) ? localize(_WorldSpaceCameraPos - pos) : vert.localPos;

				intersection(ray);
				alignment(ray,rd);
			
				float4 a = trace(ray);
				col = a;

				//float2 uv = i.localPos.xy / lerp(_Near, _Far,  (i.localPos.z - _Near) / (_Far - _Near));
				//uv.y += 0.5;
				//uv.x = 0.25 - uv.x;
				//uv = saturate(uv);
				//float depth = Linear01Depth02(SAMPLE_DEPTH_TEXTURE(_DepthTex, uv));
				//col = depth;
				//col.xy = uv;
				//col.z = 0;
                return col;
            }
            ENDCG
        }
    }
}
