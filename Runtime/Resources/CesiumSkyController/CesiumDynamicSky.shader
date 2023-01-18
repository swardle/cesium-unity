Shader "Cesium/DynamicSky"
{
    Properties
    {
        //_SkyColorGround ("Ground Color", Color) = (1.000000,0.500000,0.500000,1.000000)
        //_SkyColorHorizon ("Horizon Color", Color) = (0.000000,0.000000,0.000000,1.000000)
        _SkyColorDay ("Sky Color - Day", Color) = (0.33,0.59,0.83,1.000000)
        _SkyColorNight ("Sky Color - Night", Color) = (0.016, 0.016, 0.1, 1.0)
        _HorizonBlend ("Horizon Color Blend", Float) = 1.0
        _SunRadius ("SunRadius", Range(0.0, 0.5)) = 0.01
        _SunBloomRadius ("Sun Bloom Radius", Range(0.0, 1.0)) = 0.85
        _SunBloomIntensity ("Sun Bloom Intensity", Float) = 0.5

        // Debug only
        //_GroundSpaceBlend ("Ground Space Blend", Range(0.0, 1.0)) = 0.0
        //_DebugFloat ("Debug Float", Range(0.0, 1.0)) = 0.5

    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 position : POSITION; 
                float4 col : COLOR;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float4 col : COLOR;
                float3 viewDirWS : TEXCOORD0;
            };

            //float4 _SkyColorGround;
            //float4 _SkyColorHorizon;
            float4 _SkyColorDay;
            float4 _SkyColorNight;
            float _HorizonBlend;
            float _SunRadius;
            float _SunBloomRadius;
            float _SunBloomIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.position.xyz);
                o.viewDirWS = vertexInput.positionWS;
                o.position = vertexInput.positionCS;

                float4 skyColor = _SkyColorDay;//lerp(_SkyColorHorizon, _SkyColorDay, clamp(abs(v.position.y * _HorizonBlend), 0, 1));

                o.col = skyColor;

                return o;
            }

            float3 _SunDirection;
            float _GroundSpaceBlend;

            // Debug only
            float _DebugFloat;

            float4 frag (v2f i) : SV_Target 
            {

                float3 viewDir = normalize(i.viewDirWS);

                float3 sunDot = clamp(dot(viewDir, _SunDirection), 0, 1); 

                // Remap sun height from (-1, 1) to 0, 1)
                float sunHeightFactor = ((_SunDirection.y + 1.0) * 0.5);
                float sunHeightBlend = smoothstep(0.4, 0.7, sunHeightFactor);

                float sunsetFactor = 1 - abs(_SunDirection.y);
                float sunsetBlend = smoothstep(0.6, 1.0, sunsetFactor);

                float horizonBlend = saturate(pow(1-abs(viewDir.y), 2)); //viewDir.y + _GroundSpaceBlend.x

                float sunRadius = 1 - _SunRadius * _SunRadius;
                float sunDisk = smoothstep(sunRadius-0.001, sunRadius, sunDot);

                float sunBloom = saturate(smoothstep(1-_SunBloomRadius, 1.5, sunDot)) * _SunBloomIntensity;
                float sunBloom2 = pow(smoothstep(sunRadius-0.01, sunRadius, sunDot) * 0.4, 2);
                sunBloom = sunBloom + sunBloom2;

                float3 sunColor = float3(1, 1, 1) * sunDisk;

                float3 skyColor = _SkyColorDay + sunBloom;

                skyColor = lerp(_SkyColorNight.xyz, skyColor, sunHeightBlend);

                //skyColor = lerp(skyColor, float3(0, 0, 0), _GroundSpaceBlend.x);

                // Blend between day horizon color and night horizon color.
                float3 horizonColor = lerp(float3(0.0100, 0.03000, 0.06000), 0.5, sunHeightBlend);
                // Blend in orange at sunrise/sunset
                float3 sunsetColor = lerp(horizonColor, float3(1.0, 0.5, 0.0), (sunsetBlend-(1-sunDot) + 1.0) * 0.5);
                horizonColor = lerp(horizonColor, sunsetColor, pow(sunsetBlend, 4));
                // mask to horizon only
                horizonColor = lerp(0, horizonColor, horizonBlend);

                skyColor = clamp(skyColor + horizonColor, 0, 1); 

                // Todo: create atmosphere effect by moving horizon down x axis while in space
                // float spaceBlend = smoothstep(0.5, 0.6, ((viewDir.y + 0) * 0.5) + _GroundSpaceBlend.x);
                skyColor = lerp(skyColor, float3(0, 0, 0), _GroundSpaceBlend.x);

                skyColor = skyColor + sunColor;

                float4 c = float4(skyColor, 1);
                //float4 c = float4(0, sunBloom2, sunDisk, 1); //DEBUG ONLY

                return c;
            }
            ENDHLSL
        }
    }
}
