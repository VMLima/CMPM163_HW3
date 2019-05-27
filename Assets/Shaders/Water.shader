Shader "Custom/Water" {
    Properties {
		_Color ("Color", Color) = (1,1,1,1)
        _Cube ("Cubemap", CUBE) = "" {}
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset] _FlowMap ("Flow (RG, A noise)", 2D) = "black" {}
		[NoScaleOffset] _DerivHeightMap ("Deriv (AG) Height (B)", 2D) = "black" {}
        _RefractionAmount("Refraction Amount",  Range(0, 1)) = 0.75
		_UJump ("U jump per phase", Range(-0.25, 0.25)) = 0.25
		_VJump ("V jump per phase", Range(-0.25, 0.25)) = 0.25
		_Tiling ("Tiling", Float) = 1
		_Speed ("Speed", Float) = 1
		_FlowStrength ("Flow Strength", Float) = 1
		_FlowOffset ("Flow Offset", Float) = 0
		_HeightScale ("Height Scale, Constant", Float) = 0.25
		_HeightScaleModulated ("Height Scale, Modulated", Float) = 0.75
		_WaterFogColor ("Water Fog Color", Color) = (0, 0, 0, 0)
		_WaterFogDensity ("Water Fog Density", Range(0, 2)) = 0.1
		_RefractionStrength ("Refraction Strength", Range(0, 1)) = 0.25
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}

    Subshader{
        //Pass {
        //    Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        //    Blend SrcAlpha OneMinusSrcAlpha
        //    CGPROGRAM

        //    #pragma vertex vert
        //    #pragma fragment frag

        //    #include "UnityCG.cginc"


        //    struct appdata {
        //        float4 vertex : POSITION;
        //        float3 normal : NORMAL;
        //    };


        //    struct v2f {
        //        float4 vertex : SV_POSITION;
        //        float3 normalInWorldCoords : NORMAL;
        //        float3 vertexInWorldCoords : TEXCOORD1;
        //    };

        //    v2f vert(appdata v) {
        //        v2f o;

        //        o.vertexInWorldCoords = mul(unity_ObjectToWorld, v.vertex); //Vertex position in WORLD coords
        //        o.normalInWorldCoords = UnityObjectToWorldNormal(v.normal); //Normal 

        //        o.vertex = UnityObjectToClipPos(v.vertex);

        //        return o;
        //    }

        //    samplerCUBE _Cube;
        //    float _RefractionAmount;

        //    fixed4 frag(v2f i) : SV_Target
        //    {

        //     float3 P = i.vertexInWorldCoords.xyz;

        //     //get normalized incident ray (from camera to vertex)
        //     float3 vIncident = normalize(P - _WorldSpaceCameraPos);

        //     //reflect that ray around the normal using built-in HLSL command
        //     float3 vReflect = reflect(vIncident, i.normalInWorldCoords);


        //     //use the reflect ray to sample the skybox
        //     float4 reflectColor = texCUBE(_Cube, vReflect);
        //     //reflectColor = float4(reflectColor.rgb, 0.25);

        //     //refract the incident ray through the surface using built-in HLSL command
        //     float3 vRefract = refract(vIncident, i.normalInWorldCoords, 0.5);

        //     //float4 refractColor = texCUBE( _Cube, vRefract );


        //     float3 vRefractRed = refract(vIncident, i.normalInWorldCoords, 0.1);
        //     float3 vRefractGreen = refract(vIncident, i.normalInWorldCoords, 0.4);
        //     float3 vRefractBlue = refract(vIncident, i.normalInWorldCoords, 0.7);

        //     float4 refractColorRed = texCUBE(_Cube, float3(vRefractRed));
        //     float4 refractColorGreen = texCUBE(_Cube, float3(vRefractGreen));
        //     float4 refractColorBlue = texCUBE(_Cube, float3(vRefractBlue));
        //     float4 refractColor = float4(refractColorRed.r, refractColorGreen.g, refractColorBlue.b, 1.0);


        //     return float4(lerp(reflectColor, refractColor, _RefractionAmount).rgb, .5);


        //    }

        //    ENDCG
        //}

        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 200
        Cull Off

        GrabPass { "_WaterBackground" }

        CGPROGRAM
        #pragma surface surf Standard alpha finalcolor:ResetAlpha
        #pragma target 3.0

        #include "Flow.cginc"
        #include "LookingThroughWater.cginc"

        sampler2D _MainTex, _FlowMap, _DerivHeightMap;
        float _UJump, _VJump, _Tiling, _Speed, _FlowStrength, _FlowOffset;
        float _HeightScale, _HeightScaleModulated;

        struct Input {
            float2 uv_MainTex;
            float4 screenPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float3 UnpackDerivativeHeight(float4 textureData) {
            float3 dh = textureData.agb;
            dh.xy = dh.xy * 2 - 1;
            return dh;
        }

        void surf(Input IN, inout SurfaceOutputStandard o) {
            float3 flow = tex2D(_FlowMap, IN.uv_MainTex).rgb;
            flow.xy = flow.xy * 2 - 1;
            flow *= _FlowStrength;
            float noise = tex2D(_FlowMap, IN.uv_MainTex).a;
            float time = _Time.y * _Speed + noise;
            float2 jump = float2(_UJump, _VJump);

            float3 uvwA = FlowUVW(
                IN.uv_MainTex, flow.xy, jump,
                _FlowOffset, _Tiling, time, false
            );
            float3 uvwB = FlowUVW(
                IN.uv_MainTex, flow.xy, jump,
                _FlowOffset, _Tiling, time, true
            );

            float finalHeightScale =
                flow.z * _HeightScaleModulated + _HeightScale;

            float3 dhA =
                UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwA.xy)) *
                (uvwA.z * finalHeightScale);
            float3 dhB =
                UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwB.xy)) *
                (uvwB.z * finalHeightScale);
            o.Normal = normalize(float3(-(dhA.xy + dhB.xy), 1));

            fixed4 texA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
            fixed4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z;

            fixed4 c = (texA + texB) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            o.Emission = ColorBelowWater(IN.screenPos, o.Normal) * (1 - c.a);
        }

        void ResetAlpha(Input IN, SurfaceOutputStandard o, inout fixed4 color) {
            color.a = 1;
        }

        ENDCG
    }


}
