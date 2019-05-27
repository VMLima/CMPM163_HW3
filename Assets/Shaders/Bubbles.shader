Shader "Custom/Bubbles" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _Cube("Cubemap", CUBE) = "" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Emission ("Emission", Range(0,1)) = 0.0
        //_EmissionColor("Color", Color) = (0,0,0)
        //_EmissionMap("Emission", 2D) = "white" {}
    }
	
    SubShader {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
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

            v2f vert(appdata v) {
                v2f o;

                o.vertexInWorldCoords = mul(unity_ObjectToWorld, v.vertex); //Vertex position in WORLD coords
                o.normalInWorldCoords = UnityObjectToWorldNormal(v.normal); //Normal 

                o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }

            samplerCUBE _Cube;
            float4 _Color;

            fixed4 frag(v2f i) : SV_Target {

             float3 P = i.vertexInWorldCoords.xyz;
             P.y = 1 - P.y;

             //get normalized incident ray (from camera to vertex)
             float3 vIncident = normalize(P - _WorldSpaceCameraPos);

             //reflect that ray around the normal using built-in HLSL command
             float3 vReflect = reflect(vIncident, i.normalInWorldCoords);


             //use the reflect ray to sample the skybox
             float4 reflectColor = texCUBE(_Cube, vReflect);
             //reflectColor = float4(reflectColor.rgb, 0.25);

             //refract the incident ray through the surface using built-in HLSL command
             float3 vRefract = refract(vIncident, i.normalInWorldCoords, 0.5);

             //float4 refractColor = texCUBE( _Cube, vRefract );


             float3 vRefractRed = refract(vIncident, i.normalInWorldCoords, 0.1);
             float3 vRefractGreen = refract(vIncident, i.normalInWorldCoords, 0.4);
             float3 vRefractBlue = refract(vIncident, i.normalInWorldCoords, 0.7);

             float4 refractColorRed = texCUBE(_Cube, float3(vRefractRed));
             float4 refractColorGreen = texCUBE(_Cube, float3(vRefractGreen));
             float4 refractColorBlue = texCUBE(_Cube, float3(vRefractBlue));
             float4 refractColor = float4(refractColorRed.r, refractColorGreen.g, refractColorBlue.b, 1.0);

             float4 finalReflection = float4(lerp(reflectColor, refractColor, .75).rgb, .5);

             //finalReflection *= _Color;
             return finalReflection;
            }

            ENDCG
        }

         CGPROGRAM
         // Physically based Standard lighting model, and enable shadows on all light types
         #pragma surface surf Standard alpha fullforwardshadows

         // Use shader model 3.0 target, to get nicer looking lighting
         #pragma target 3.0

         struct Input {
             float2 uv_MainTex;
         };

         half _Glossiness;
         half _Metallic;
         half _Emission;
         //half _EmissionColor;

         void surf(Input IN, inout SurfaceOutputStandard o) {
             o.Metallic = _Metallic;
             o.Smoothness = _Glossiness;
             o.Emission = _Emission;
         }
         ENDCG
    }
}
