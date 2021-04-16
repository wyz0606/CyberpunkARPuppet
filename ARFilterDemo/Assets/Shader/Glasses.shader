Shader "Custom/Glasses"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _SpecColor("Specular Color", Color) = (1,1,1,1)
        _HighlightTex("HighlightTex", 2D) = "white"{}
        _HighlightColor("Highlight Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline"}
        Blend SrcAlpha OneMinusSrcAlpha

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
                float2 uv               : TEXCOORD; 
            };

            struct v2f
            {
                float4 positionCS       : SV_POSITION;
                half3 normalWS          : TEXCOORD;
                float3 positionWS       : TEXCOORD1;
                float2 uv               : TEXCOORD2;
                half3 viewDir           : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor, _HighlightColor, _SpecColor;
            CBUFFER_END

            TEXTURE2D(_HighlightTex); SAMPLER(sampler_HighlightTex);

            v2f vert (appdata v)
            {
                v2f o;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.uv = v.uv;
                o.viewDir = normalize(_WorldSpaceCameraPos - o.positionWS);
                
                return o;
            }

            half4 SampleSpecularSmoothness(half2 uv, half4 specColor)
            {
                half4 specularSmoothness = half4(0.0h, 0.0h, 0.0h, 1.0h);

                specularSmoothness = specColor;
                specularSmoothness.a = exp2(10 * specularSmoothness.a + 1);

                return specularSmoothness;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 c;

                //Light
                float2 uv = i.uv;
                half3 N = normalize(i.normalWS);
                half3 V = normalize(i.viewDir);

                half4 specular = SampleSpecularSmoothness(uv, _SpecColor);
                half smoothness = specular.a;

                //Main Light
                Light mainLight = GetMainLight();
                half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);
                half3 diffuseColor = LightingLambert(attenuatedLightColor, mainLight.direction, N);
                half3 specularColor = LightingSpecular(attenuatedLightColor, mainLight.direction, N, V, specular, smoothness);

                //Additional Light
                #ifdef _ADDITIONAL_LIGHTS
                    // return 1;
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                    {
                        Light light = GetAdditionalLight(lightIndex, i.positionWS);
                        half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
                        diffuseColor += LightingLambert(attenuatedLightColor, light.direction, N);
                        specularColor += LightingSpecular(attenuatedLightColor, light.direction, N, V, specular, smoothness);
                    }
                #endif

                //Highlight
                half4 highlightMask = SAMPLE_TEXTURE2D(_HighlightTex,sampler_HighlightTex, i.uv);
                half3 emission = _HighlightColor.rgb * highlightMask.r;

                half3 finalColor = diffuseColor * _BaseColor.rgb + emission;
                finalColor += specularColor;

                c.rgb = finalColor;
                c.a = lerp(_BaseColor.a, 1, highlightMask.r);
                return c;
            }
            ENDHLSL
        }
    }
}
