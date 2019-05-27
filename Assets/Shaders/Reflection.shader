Shader "Custom/Reflection" {
    Properties {      
      _Cube ("Cubemap", CUBE) = "" {}
    }

    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
             
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
             float3 vReflect = reflect( vIncident, i.normalInWorldCoords );
             
             
             //use the reflect ray to sample the skybox
             float4 reflectColor = texCUBE( _Cube, vReflect );
             
             //refract the incident ray through the surface using built-in HLSL command
             float3 vRefract = refract( vIncident, i.normalInWorldCoords, 0.5 );
             
             float4 refractColor = texCUBE( _Cube, vRefract );
             
             return float4(lerp(reflectColor, refractColor, 0).rgb, 1.0);
                
                
            }
      
            ENDCG
        }
    }

    
    SubShader {
      Tags { "RenderType" = "Opaque"}
      CGPROGRAM
      #pragma surface surf Lambert
      struct Input {
          float2 uv_MainTex;
          float3 worldRefl;
      };
      sampler2D _MainTex;
      samplerCUBE _Cube;
      void surf (Input IN, inout SurfaceOutput o) {
          o.Albedo = tex2D (_MainTex, IN.uv_MainTex).rgb * 0.5;
          o.Emission = texCUBE (_Cube, IN.worldRefl).rgb;
      }
      ENDCG
    } 
  }
