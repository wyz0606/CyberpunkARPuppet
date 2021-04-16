Shader "Custom/Translucent"
{
    Properties
    {
        [Header(Base)]
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}

        [Header(Specular)]
        _Specular("Specular",float) = 1
        _SpecularTex("SpecularTex", 2D) = "black"{}
        _Shineness("Shineness",float) = 1

        [Header(Translucent)]
        _Thickness("Thickness", Range(0,1)) = 0.5
        _NormalDistortion("Normal Distortion", Range(0,1)) = 0.5
        _Attenuation("Attenuation",float) = 1
        _Strength("Strength", float) = 1
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
            half _NormalDistortion, _Attenuation, _Strength, _Thickness, _Specular, _Shineness;
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

            //透射
            half3 Translucent(float3 lightDir, half3 viewDir, half3 color, float3 normalWS, half thickness)
            {
                half3 V = viewDir;
                float3 L = lightDir;
                half3 H = L + normalWS * _NormalDistortion;
                half _HdotV = saturate(dot(-H,V));
                half3 I = pow(_HdotV, _Attenuation) * _Strength;
                I *= thickness;
                I *= color;

                return I;
            }

            half4 frag(Varyings i) : SV_Target
            {
                half4 c;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                c = baseMap * _BaseColor;

                //Light and Specular
                // Specular = Ks * pow(max(0,dot(N,H)), Shininess)
                float3 N = normalize(i.normalWS);
                Light light = GetMainLight();
                float3 L = light.direction;
                float3 V = i.viewWS;
                float3 H = normalize(L + V);
                half NdotH = max(0,dot(N,H));
                half4 specularMap = SAMPLE_TEXTURE2D(_SpecularTex, sampler_SpecularTex, i.uv);
                half specular = _Specular * pow(NdotH,_Shineness) * specularMap.r;
                half diffuse = max(0,dot(N,L));
                c *= diffuse;
                c += specular;

                half thickness = 1 - _Thickness;

                //Translucent
                c.rgb += Translucent(light.direction, i.viewWS, light.color, N, thickness);

                //AdditionalLights
                #ifdef _ADDITIONAL_LIGHTS
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
                    {
                        Light addLight = GetAdditionalLight(lightIndex, i.positionWS);
                        half3 attenuatedLightColor = addLight.color * (addLight.distanceAttenuation * addLight.shadowAttenuation);
                        // c.rgb += LightingLambert(attenuatedLightColor, addLight.direction, N);
                        c.rgb += Translucent(addLight.direction, i.viewWS, addLight.color, N, thickness) * attenuatedLightColor;
                    }
                #endif

                c.rgb = MixFog(c.rgb, i.fogCoord);
                return c;
            }
            ENDHLSL
        }
    }
}
