Shader "Custom/BubblesV2" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
            _Cube("Cubemap", CUBE) = "" {}
    }
	
    SubShader {
        Pass{
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            //uniform float4 _MainTex_TexelSize; //special value
          
            
            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 normalInWorldCoords : NORMAL;
                float3 vertexInWorldCoords : TEXCOORD1;
            };

            v2f vert (appdata v) {
                v2f o;

                o.vertexInWorldCoords = mul(unity_ObjectToWorld, v.vertex); //Vertex position in WORLD coords
                o.normalInWorldCoords = UnityObjectToWorldNormal(v.normal); //Normal 

                o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }

            samplerCUBE _Cube;

            fixed4 frag (v2f i) : SV_Target {
                float3 P = i.vertexInWorldCoords.xyz;

                //get normalized incident ray (from camera to vertex)
                float3 vIncident = normalize(P - _WorldSpaceCameraPos);

                //reflect that ray around the normal using built-in HLSL command
                float3 vReflect = reflect(vIncident, i.normalInWorldCoords);


                //use the reflect ray to sample the skybox
                float4 reflectColor = texCUBE(_Cube, vReflect);

                return reflectColor;

                //float3 col = tex2D( _MainTex, i.uv).rgb;
                //Find Luminance
                //float brightness = dot(col, float3(0.2126, 0.7152, 0.0722));
             
                //return float4(col, 1.0) if Luminance > some threshold else return black
                /*if (brightness > 1.0) {
                    return float4(col, 1.0);
                } else {
                    return float4(0, 0, 0, 1);
                }*/
            }
            ENDCG
        }
		Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard alpha //fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}

		ENDCG
    }
    FallBack "Diffuse"
}
