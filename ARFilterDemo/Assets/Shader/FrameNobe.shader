Shader "Custom/FrameNobe"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        [Header(HighLight)]
        [Toggle]_HighLightEnabled("HighLightEnabled", int) = 0
        _HighLightColor("HighLightColor", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}

        Pass
        {

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _HIGHLIGHTENABLED_ON

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"

            struct appdata
            {
                float4 positionOS       : POSITION;
                half3 normalOS          : NORMAL;
            };

            struct v2f
            {
                float4 positionCS       : SV_POSITION;
                half3 normalWS          : TEXCOORD;
                float3 positionWS       : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor, _HighLightColor;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 c = 0;
                #if _HIGHLIGHTENABLED_ON
                    c = _HighLightColor;
                #else
                    //LightingLambert
                    Light mainLight = GetMainLight();
                    half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
                    half3 diffuseColor = LightingLambert(attenuatedLightColor, mainLight.direction, i.normalWS);

                    #ifdef _ADDITIONAL_LIGHTS
                        uint pixelLightCount = GetAdditionalLightsCount();
                        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                        {
                            Light light = GetAdditionalLight(lightIndex, i.positionWS);
                            half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
                            diffuseColor += LightingLambert(attenuatedLightColor, light.direction, i.normalWS);
                        }
                    #endif

                    c = half4(diffuseColor,1);
                    c *= _BaseColor;
                #endif

                return c;
            }
            ENDHLSL
        }
    }
}
