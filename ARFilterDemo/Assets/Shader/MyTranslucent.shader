Shader "Custom/Translucent"
{
    Properties
    {
        [Header(Base)]
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}

        [Header(Specular)]
        [NoScaleOffset]_SpecularTex("SpecularTex", 2D) = "white"{}
        _SpecularIntensity("Specular",float) = 1
        _Shineness("Shineness",float) = 1

        [Header(Translucent)]
        _Translucent("Thickness(X) Distortion(Y) Attenuation(Z) Strength(W)", vector) = (0.5,0.5,1,1)
    }

    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _ADDITIONAL_LIGHTS

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float3 normalOS         : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float2 uv               : TEXCOORD0;
                float fogCoord          : TEXCOORD1;
                float3 normalWS         : TEXCOORD2;
                float3 viewWS           : TEXCOORD3;
                float3 positionWS       : TEXCOORD4;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            half _SpecularIntensity, _Shineness;
            half4 _Translucent;
            CBUFFER_END
            TEXTURE2D (_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D (_SpecularTex);SAMPLER(sampler_SpecularTex);

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.viewWS = normalize(_WorldSpaceCameraPos - o.positionWS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);

                return o;
            }

            //Translucent
            half3 Translucent(Light light, half3 viewDir, float3 normalWS, half normalDistortion, half thickness, half attenuation, half strength)
            {
                half3 V = viewDir;
                float3 L = light.direction;
                half3 H = L + normalWS * normalDistortion;
                half _HdotV = saturate(dot(-H,V));
                half3 I = pow(_HdotV, attenuation) * strength;
                I *= thickness;
                I *= light.color;

                return I;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half4 c;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                c = baseMap * _BaseColor;

                half transThickness = _Translucent.x;
                half transNormalDistortion = _Translucent.y;
                half transAttenuation = _Translucent.z;
                half transStrength = _Translucent.w;

                //Light and Specular
                // Specular = Ks * pow(max(0,dot(N,H)), Shininess)
                float3 N = normalize(i.normalWS);
                Light light = GetMainLight();
                float3 L = light.direction;
                float3 V = i.viewWS;
                float3 H = normalize(L + V);
                half NdotH = max(0,dot(N,H));
                half4 specularMap = SAMPLE_TEXTURE2D(_SpecularTex, sampler_SpecularTex, i.uv);
                half specular = _SpecularIntensity * pow(NdotH,_Shineness) * specularMap.r;
                half diffuse = max(0,dot(N,L));
                c *= diffuse;
                c += specular;

                half thickness = 1 - transThickness;

                //Translucent
                c.rgb += Translucent(light, i.viewWS, N, transNormalDistortion, thickness, transAttenuation, transStrength);

                //AdditionalLights
                #ifdef _ADDITIONAL_LIGHTS
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                    {
                        Light addLight = GetAdditionalLight(lightIndex, i.positionWS);
                        half3 attenuatedLightColor = addLight.color * (addLight.distanceAttenuation * addLight.shadowAttenuation);
                        // c.rgb += LightingLambert(attenuatedLightColor, addLight.direction, N);
                        c.rgb += Translucent(addLight, i.viewWS, N, transNormalDistortion, thickness, transAttenuation, transStrength) * attenuatedLightColor;
                    }
                #endif

                c.rgb = MixFog(c.rgb, i.fogCoord);
                return c;
            }
            ENDHLSL
        }
    }
}
