Shader "Volumetric/VolumetricSpotLight"
{
	Properties
	{
		_DepthTex ("Depth", 2D) = "black" {}
		_Intensity("Intensity",float) = 1.0
		_JitterIntensity("Jitter Intensity",float) = 0.001
		_Attenuation("Attenuation",float) = 0.25

		_NoiseTex("Noise Texture", 3D) = "white"{}
		_NoiseIntensity("Noise Intensity", Range(0,1)) = 0.3
		_NoiseScale("NoiseScale", float) = 1
		_NoiseSpeed("Noise Speed", float) = 1


		_WidthOffset("Width Edge Cut", Range(0.0,1.0)) = 0.05
		_HeightOffset("Hight Edge Cut", Range(0.0,1.0)) = 0.05
		_WidthAspect("Width Aspect",Range(0.001,1.0)) = 0.8
		_HeightAspect("Height Aspect",Range(0.001,1.0)) = 0.9
		_EndWidthAspect("End Width Aspect",Range(0.001,1.0)) = 1
		_EndHeightAspect("End Height Aspect",Range(0.001,1.0)) = 1

		_Far("Far", float) = 20
		_Near("Near", float) = 0.3
	}
	SubShader
	{
	    Tags{"RenderType"="Transparent" "Queue"="Transparent+100"}
        Cull Off
		ZTest Off
		Blend SrcAlpha One

		Pass
		{	
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#define ITERATION 32
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;

				 UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD1;
				float4 localPos : TEXCOORD2;
				float4 screenPos : TEXCOORD3;
				float3 ray : TEXCOORD4;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
			};

			struct Ray{
				float3 origin;
				float3 dir;
				float tmax;
				float tmin;
			};

			struct FragOut{
                float4 color : SV_Target;
				//float depth : SV_Depth;
            };

			sampler2D _DepthTex;
			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

			float3 _Offset;
			float _JitterIntensity;
			float _Intensity;
			float _Attenuation;

			sampler3D _NoiseTex;
            float _NoiseScale;
            float _NoiseIntensity;
            float _NoiseSpeed;

			float _WidthOffset;
			float _HeightOffset;
			float _WidthAspect;
			float _HeightAspect;
			float _EndWidthAspect;
			float _EndHeightAspect;

			float _Far;
			float _Near;
		    
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.localPos = v.vertex;
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.screenPos = ComputeScreenPos(o.vertex);

				 float2 sp = o.screenPos.xy/o.screenPos.w;

                #if UNITY_SINGLE_PASS_STEREO
                    float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
                    sp = (sp - scaleOffset.zw) / scaleOffset.xy;
                #endif

                sp = sp * 2.0 - 1.0;

                float far = _ProjectionParams.z;
                float3 clipVec = float3(sp.xy,1.0) * far;
                o.ray = mul(unity_CameraInvProjection,clipVec.xyzz).xyz;

				return o;
			}

			float2x2 rot(float a){
				float c = cos(a),s = sin(a);
				return float2x2(c,s,-s,c);
			}

			inline float3 localize(float3 vec){
				return mul(unity_WorldToObject, vec);
			}

			float rnd(float3 p){
				return frac(45313.61414 * sin(dot(p, float3(12.631,15.613,17.563))));
			}

			inline float Linear01Depth02(float depth){
				float far = _Far;
				float near = _Near;
				float y = far/near;
				float x = 1 - far/near; 
				#if defined(UNITY_REVERSED_Z)
				  y = 1;
				  x = -1 + far/near;
				#endif
				float z = x/far;
				float w = y/far; 
				return 1.0/(x * depth + y);
			}

			float map(float3 p){
				float z = saturate(0.5 - p.y);
				float2 uv = (p.xz)/(z + 0.001) + 0.5;
				float depth = Linear01Depth02(SAMPLE_DEPTH_TEXTURE(_DepthTex, uv));
				depth = depth < 0.5 - p.y ? 0.0 : 1.0;
				if(uv.x < 0 || uv.x > 1 || uv.y < 0 || uv.y > 1) depth = 0;
				depth *= pow(saturate(0.5 + p.y), _Attenuation);
				// float n = fbm(p * 5.0 - _Time.y * float3(0.1,0.5,0.2)) * 0.3 + 0.7;
				float n = lerp(1, tex3D(_NoiseTex, p * _NoiseScale - _Time.y * _NoiseSpeed * float3(0,1,0)), _NoiseIntensity);
				return _Intensity * depth * n;
			}

			float4 spotColor(float3 p){
				float2 uv = p.xz / saturate(0.5 - p.y) + 0.5;
				uv = saturate(uv) - 0.5;
				float r = length(uv);
				return smoothstep(0.5, 0.45,r);
			}

			float4 fogColor(float3 p){
				float xAspect = lerp(_WidthAspect,_EndWidthAspect,saturate(p.y + 0.5));
				float yAspect = lerp(_HeightAspect,_EndHeightAspect,saturate(p.y + 0.5));
				float2 uv = (float2(p.x/xAspect, p.z/yAspect)) + 0.5;
				uv = saturate(uv);
				fixed4 col = 1.0;
				col = saturate(col * 2.0 + 0.1) * 2.0;
				float area = smoothstep(0.0,0.01,uv.x) * smoothstep(0.0,0.01,uv.y) * smoothstep(0.0,0.01,1.0 - uv.x) * smoothstep(0.0,0.01,1.0 -uv.y);
				float lumi = Luminance(col) + 0.2;
				col *= smoothstep(0.0,1, area * lumi * 2.0);
				col *= smoothstep(-0.5, -0.45, p.y);
				return col;
			}

			float4 trace(Ray ray){
				float3 ro = ray.origin;
				float jitter = rnd(ro) * _JitterIntensity;
				float3 lstep = (ray.dir * ray.tmax / (float)ITERATION) * (1 - jitter);
				float t = 0.0;
				float4 output = float4(0,0,0,0);
				float d = 0;
				for(int i = 0; i < ITERATION; i++){
					t = map(ro);
					float4 color = spotColor(ro) * t;
					output += (1.0 - output.a) * color * 0.1;
					if(output.a > 1) break;
                    ro += lstep;
				}
				return output;
			}

			void intersection(inout Ray ray){
				float3 invDir = 1.0 / ray.dir;
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

			float mod(float a, float b){
				return a - floor(a/b) *b;
			}

			inline void alignment(inout Ray ray, float3 rd){
				float3 forward = - normalize(UNITY_MATRIX_V[2].xyz);
				float3 cameraDir = normalize(rd);
				//float ratio = 1 / dot(cameraDir, forward);
				float stepDist = (1.0 / (float)ITERATION);// * ratio;
				float camDist = length(rd);
				float startOffset = stepDist - mod(camDist, stepDist);
				ray.origin += localize(cameraDir * startOffset);
			}

			float NearPlaneDistance(float4 projPos){
				projPos.xy /= projPos.w;
				projPos.xy = (projPos.xy - 0.5) * 2.0;
				projPos.x *= _ScreenParams.x / _ScreenParams.y;
				float3 n = normalize(float3(projPos.xy, abs(UNITY_MATRIX_P[1][1])));
				return _ProjectionParams.y / n.z;
		    }

			fixed4 frag (v2f vert, fixed facing : VFACE) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				fixed4 col = fixed4(0,0,0,1);

				float3 scale = float3(length(UNITY_MATRIX_M[0].xyz), length(UNITY_MATRIX_M[1].xyz), length(UNITY_MATRIX_M[2].xyz));
				float3x3 rot = (float3x3)UNITY_MATRIX_M;
				rot[0].xyz /= scale.x;
				rot[1].xyz /= scale.y;
				rot[2].xyz /= scale.z;
				float3 pos = mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;

				Ray ray = (Ray)0 ;
				float3 rd = vert.worldPos - _WorldSpaceCameraPos;
				ray.dir = normalize(localize(rd));

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

				alignment(ray, rd);
				intersection(ray);

				float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, vert.screenPos.xy / vert.screenPos.w));
				float3 worldPos = depth * normalize(rd) / dot(normalize(rd),- UNITY_MATRIX_V[2].xyz) + _WorldSpaceCameraPos;
				float tmax2 = length(ray.origin - mul(unity_WorldToObject, float4(worldPos,1)));
				ray.tmax = min(ray.tmax, tmax2);
				
				float4 a = trace(ray);
				col = a;
				return col;
			}
			ENDCG
		}
	}
}
