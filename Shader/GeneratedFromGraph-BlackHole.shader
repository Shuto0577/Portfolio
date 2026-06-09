Shader "Shader Graphs/BlackHole"
{
    Properties
    {
        [PerRendererData]_Position("Position", Vector, 2) = (0.5, 0.5, 0, 0)
        _Radius("Radius", Float) = 1
        _Ratio("Ratio", Vector, 2) = (1, 1, 0, 0)
        _Distance("Distance", Float) = 1
        _CoreRadius("CoreRadius", Float) = 0.05
        _CoreBlur("CoreBlur", Float) = 0.1
        _DistortionRange("DistortionRange", Float) = 0.5
        _DistortionFade("DistortionFade", Float) = 0.1
        [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Unlit"
            "Queue"="Transparent"
            "DisableBatching"="False"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalUnlitSubTarget"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                // LightMode: <None>
            }
        
        // Render State
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma multi_compile_instancing
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ USE_LEGACY_LIGHTMAPS
        #pragma multi_compile _ LIGHTMAP_BICUBIC_SAMPLING
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX_NORMAL_OUTPUT
        #define FEATURES_GRAPH_VERTEX_TANGENT_OUTPUT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_UNLIT
        #define _FOG_FRAGMENT 1
        #define _SURFACE_TYPE_TRANSPARENT 1
        #define UNLIT_DEFAULT_DECAL_BLENDING 1
        #define UNLIT_DEFAULT_SSAO 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Fog.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(ATTRIBUTES_NEED_INSTANCEID)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float2 NDCPosition;
             float2 PixelPosition;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0 : INTERP0;
             float3 positionWS : INTERP1;
             float3 normalWS : INTERP2;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.texCoord0.xyzw = input.texCoord0;
            output.positionWS.xyz = input.positionWS;
            output.normalWS.xyz = input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.texCoord0.xyzw;
            output.positionWS = input.positionWS.xyz;
            output.normalWS = input.normalWS.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _Position;
        float _Radius;
        float2 _Ratio;
        float _Distance;
        float _CoreRadius;
        float _CoreBlur;
        float _DistortionRange;
        float _DistortionFade;
        UNITY_TEXTURE_STREAMING_DEBUG_VARS;
        CBUFFER_END
        
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_CameraSortingLayerTexture);
        SAMPLER(sampler_CameraSortingLayerTexture);
        float4 _CameraSortingLayerTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A - B;
        }
        
        void Unity_Divide_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A / B;
        }
        
        void Unity_Length_float2(float2 In, out float Out)
        {
            Out = length(In);
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Distance_float2(float2 A, float2 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D = UnityBuildTexture2DStructNoScale(_CameraSortingLayerTexture);
            float2 _Property_e75e244b614c4829b05138986a75fc12_Out_0_Vector2 = _Position;
            float4 _UV_874892e473a34f6dbc88b1f804656769_Out_0_Vector4 = IN.uv0;
            float2 _Property_ecfc3b67d2554fd9ae985e3e57ecdca5_Out_0_Vector2 = _Position;
            float2 _Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2;
            Unity_Subtract_float2((_UV_874892e473a34f6dbc88b1f804656769_Out_0_Vector4.xy), _Property_ecfc3b67d2554fd9ae985e3e57ecdca5_Out_0_Vector2, _Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2);
            float2 _Property_c3f7856863254c288c603001b50ba8ff_Out_0_Vector2 = _Ratio;
            float2 _Divide_bbaefc47cd0f463188f75f91c8846ac6_Out_2_Vector2;
            Unity_Divide_float2(_Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2, _Property_c3f7856863254c288c603001b50ba8ff_Out_0_Vector2, _Divide_bbaefc47cd0f463188f75f91c8846ac6_Out_2_Vector2);
            float _Length_cfe3565bc74d4090bf6fd91e1e81ff5e_Out_1_Float;
            Unity_Length_float2(_Divide_bbaefc47cd0f463188f75f91c8846ac6_Out_2_Vector2, _Length_cfe3565bc74d4090bf6fd91e1e81ff5e_Out_1_Float);
            float _Property_fe71b53d748a4cdf8fcd273e4e2ca4e6_Out_0_Float = _Distance;
            float _Power_a28c0469105048fc8cffa3077877b549_Out_2_Float;
            Unity_Power_float(_Property_fe71b53d748a4cdf8fcd273e4e2ca4e6_Out_0_Float, float(0.5), _Power_a28c0469105048fc8cffa3077877b549_Out_2_Float);
            float _Multiply_d019d20763b841c0b1e3c7b9cf246b4d_Out_2_Float;
            Unity_Multiply_float_float(_Length_cfe3565bc74d4090bf6fd91e1e81ff5e_Out_1_Float, _Power_a28c0469105048fc8cffa3077877b549_Out_2_Float, _Multiply_d019d20763b841c0b1e3c7b9cf246b4d_Out_2_Float);
            float _Power_a87d2c03897b4caaa34e210c8c8a1479_Out_2_Float;
            Unity_Power_float(_Multiply_d019d20763b841c0b1e3c7b9cf246b4d_Out_2_Float, float(2), _Power_a87d2c03897b4caaa34e210c8c8a1479_Out_2_Float);
            float _Property_647058a03fe446b48804baa913a1b34f_Out_0_Float = _Radius;
            float _Multiply_989b663afaf441319a0715f715a81e67_Out_2_Float;
            Unity_Multiply_float_float(_Power_a87d2c03897b4caaa34e210c8c8a1479_Out_2_Float, _Property_647058a03fe446b48804baa913a1b34f_Out_0_Float, _Multiply_989b663afaf441319a0715f715a81e67_Out_2_Float);
            float _Multiply_675a7cfba0094a858070d54dcd63b597_Out_2_Float;
            Unity_Multiply_float_float(_Multiply_989b663afaf441319a0715f715a81e67_Out_2_Float, 2, _Multiply_675a7cfba0094a858070d54dcd63b597_Out_2_Float);
            float _Divide_4202e6ad7f874154827f617c2306a0ad_Out_2_Float;
            Unity_Divide_float(float(1), _Multiply_675a7cfba0094a858070d54dcd63b597_Out_2_Float, _Divide_4202e6ad7f874154827f617c2306a0ad_Out_2_Float);
            float _OneMinus_151e1a1f7b8a42578a6fe655938f9d52_Out_1_Float;
            Unity_OneMinus_float(_Divide_4202e6ad7f874154827f617c2306a0ad_Out_2_Float, _OneMinus_151e1a1f7b8a42578a6fe655938f9d52_Out_1_Float);
            float2 _Multiply_aa08266616fd4bb99d0f0bc688b6d431_Out_2_Vector2;
            Unity_Multiply_float2_float2(_Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2, (_OneMinus_151e1a1f7b8a42578a6fe655938f9d52_Out_1_Float.xx), _Multiply_aa08266616fd4bb99d0f0bc688b6d431_Out_2_Vector2);
            float2 _Add_a402e642760e4c60981ad0560b974d74_Out_2_Vector2;
            Unity_Add_float2(_Property_e75e244b614c4829b05138986a75fc12_Out_0_Vector2, _Multiply_aa08266616fd4bb99d0f0bc688b6d431_Out_2_Vector2, _Add_a402e642760e4c60981ad0560b974d74_Out_2_Vector2);
            float4 _UV_d6a0a4f19fa54d2d9c881392792ea071_Out_0_Vector4 = IN.uv0;
            float2 _Subtract_501f809b35684c189118f8eac45c849a_Out_2_Vector2;
            Unity_Subtract_float2(_Add_a402e642760e4c60981ad0560b974d74_Out_2_Vector2, (_UV_d6a0a4f19fa54d2d9c881392792ea071_Out_0_Vector4.xy), _Subtract_501f809b35684c189118f8eac45c849a_Out_2_Vector2);
            float4 _ScreenPosition_3c9593d030d1476aac2fcfca3e04743b_Out_0_Vector4 = float4(IN.NDCPosition.xy, 0, 0);
            float2 _Add_5a101a9abbae433db4310a1d90597fb2_Out_2_Vector2;
            Unity_Add_float2(_Subtract_501f809b35684c189118f8eac45c849a_Out_2_Vector2, (_ScreenPosition_3c9593d030d1476aac2fcfca3e04743b_Out_0_Vector4.xy), _Add_5a101a9abbae433db4310a1d90597fb2_Out_2_Vector2);
            float4 _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4 = SAMPLE_TEXTURE2D(_Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D.tex, _Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D.samplerstate, _Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D.GetTransformedUV(_Add_5a101a9abbae433db4310a1d90597fb2_Out_2_Vector2) );
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_R_4_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.r;
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_G_5_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.g;
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_B_6_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.b;
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_A_7_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.a;
            float _Property_52231855222f4fbea0fb538009cb45fb_Out_0_Float = _CoreRadius;
            float _Property_33e8ef50dc4d498db98b948af9495bd4_Out_0_Float = _CoreBlur;
            float _Add_378db2f0aeae4e4bb001fcd3285618b9_Out_2_Float;
            Unity_Add_float(_Property_52231855222f4fbea0fb538009cb45fb_Out_0_Float, _Property_33e8ef50dc4d498db98b948af9495bd4_Out_0_Float, _Add_378db2f0aeae4e4bb001fcd3285618b9_Out_2_Float);
            float4 _UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4 = IN.uv0;
            float2 _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2 = float2(float(0.5), float(0.5));
            float _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float;
            Unity_Distance_float2((_UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4.xy), _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float);
            float _Smoothstep_ca941a008b414220ac943bd0a34ccb2a_Out_3_Float;
            Unity_Smoothstep_float(_Property_52231855222f4fbea0fb538009cb45fb_Out_0_Float, _Add_378db2f0aeae4e4bb001fcd3285618b9_Out_2_Float, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float, _Smoothstep_ca941a008b414220ac943bd0a34ccb2a_Out_3_Float);
            float4 _Multiply_0ae779bdc1ca451da0d842fb67a08712_Out_2_Vector4;
            Unity_Multiply_float4_float4(_SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4, (_Smoothstep_ca941a008b414220ac943bd0a34ccb2a_Out_3_Float.xxxx), _Multiply_0ae779bdc1ca451da0d842fb67a08712_Out_2_Vector4);
            float _Property_7860741471ae48ad83c819f704302922_Out_0_Float = _DistortionRange;
            float _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float = _DistortionFade;
            float _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float;
            Unity_Subtract_float(_Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float, _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float);
            float _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float;
            Unity_Smoothstep_float(_Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float, _Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float, _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float);
            float _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            Unity_OneMinus_float(_Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float, _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float);
            surface.BaseColor = (_Multiply_0ae779bdc1ca451da0d842fb67a08712_Out_2_Vector4.xyz);
            surface.Alpha = _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        
            #if UNITY_UV_STARTS_AT_TOP
            output.PixelPosition = float2(input.positionCS.x, (_ProjectionParams.x < 0) ? (_ScaledScreenParams.y - input.positionCS.y) : input.positionCS.y);
            #else
            output.PixelPosition = float2(input.positionCS.x, (_ProjectionParams.x > 0) ? (_ScaledScreenParams.y - input.positionCS.y) : input.positionCS.y);
            #endif
        
            output.NDCPosition = output.PixelPosition.xy / _ScaledScreenParams.xy;
            output.NDCPosition.y = 1.0f - output.NDCPosition.y;
        
            output.uv0 = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "MotionVectors"
            Tags
            {
                "LightMode" = "MotionVectors"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        ColorMask RG
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 3.5
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_MOTION_VECTORS
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(ATTRIBUTES_NEED_INSTANCEID)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.texCoord0.xyzw = input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.texCoord0.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _Position;
        float _Radius;
        float2 _Ratio;
        float _Distance;
        float _CoreRadius;
        float _CoreBlur;
        float _DistortionRange;
        float _DistortionFade;
        UNITY_TEXTURE_STREAMING_DEBUG_VARS;
        CBUFFER_END
        
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_CameraSortingLayerTexture);
        SAMPLER(sampler_CameraSortingLayerTexture);
        float4 _CameraSortingLayerTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        void Unity_Distance_float2(float2 A, float2 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _Property_7860741471ae48ad83c819f704302922_Out_0_Float = _DistortionRange;
            float _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float = _DistortionFade;
            float _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float;
            Unity_Subtract_float(_Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float, _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float);
            float4 _UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4 = IN.uv0;
            float2 _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2 = float2(float(0.5), float(0.5));
            float _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float;
            Unity_Distance_float2((_UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4.xy), _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float);
            float _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float;
            Unity_Smoothstep_float(_Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float, _Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float, _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float);
            float _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            Unity_OneMinus_float(_Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float, _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float);
            surface.Alpha = _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpacePosition =                        input.positionOS;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
            output.uv0 = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/MotionVectorPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormalsOnly"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX_NORMAL_OUTPUT
        #define FEATURES_GRAPH_VERTEX_TANGENT_OUTPUT
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        #define _SURFACE_TYPE_TRANSPARENT 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(ATTRIBUTES_NEED_INSTANCEID)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0 : INTERP0;
             float3 normalWS : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.texCoord0.xyzw = input.texCoord0;
            output.normalWS.xyz = input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.texCoord0.xyzw;
            output.normalWS = input.normalWS.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _Position;
        float _Radius;
        float2 _Ratio;
        float _Distance;
        float _CoreRadius;
        float _CoreBlur;
        float _DistortionRange;
        float _DistortionFade;
        UNITY_TEXTURE_STREAMING_DEBUG_VARS;
        CBUFFER_END
        
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_CameraSortingLayerTexture);
        SAMPLER(sampler_CameraSortingLayerTexture);
        float4 _CameraSortingLayerTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        void Unity_Distance_float2(float2 A, float2 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _Property_7860741471ae48ad83c819f704302922_Out_0_Float = _DistortionRange;
            float _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float = _DistortionFade;
            float _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float;
            Unity_Subtract_float(_Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float, _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float);
            float4 _UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4 = IN.uv0;
            float2 _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2 = float2(float(0.5), float(0.5));
            float _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float;
            Unity_Distance_float2((_UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4.xy), _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float);
            float _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float;
            Unity_Smoothstep_float(_Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float, _Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float, _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float);
            float _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            Unity_OneMinus_float(_Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float, _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float);
            surface.Alpha = _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
            output.uv0 = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX_NORMAL_OUTPUT
        #define FEATURES_GRAPH_VERTEX_TANGENT_OUTPUT
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(ATTRIBUTES_NEED_INSTANCEID)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0 : INTERP0;
             float3 normalWS : INTERP1;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.texCoord0.xyzw = input.texCoord0;
            output.normalWS.xyz = input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.texCoord0.xyzw;
            output.normalWS = input.normalWS.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _Position;
        float _Radius;
        float2 _Ratio;
        float _Distance;
        float _CoreRadius;
        float _CoreBlur;
        float _DistortionRange;
        float _DistortionFade;
        UNITY_TEXTURE_STREAMING_DEBUG_VARS;
        CBUFFER_END
        
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_CameraSortingLayerTexture);
        SAMPLER(sampler_CameraSortingLayerTexture);
        float4 _CameraSortingLayerTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        void Unity_Distance_float2(float2 A, float2 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _Property_7860741471ae48ad83c819f704302922_Out_0_Float = _DistortionRange;
            float _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float = _DistortionFade;
            float _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float;
            Unity_Subtract_float(_Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float, _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float);
            float4 _UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4 = IN.uv0;
            float2 _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2 = float2(float(0.5), float(0.5));
            float _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float;
            Unity_Distance_float2((_UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4.xy), _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float);
            float _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float;
            Unity_Smoothstep_float(_Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float, _Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float, _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float);
            float _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            Unity_OneMinus_float(_Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float, _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float);
            surface.Alpha = _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
            output.uv0 = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }
        
        // Render State
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles3 glcore
        #pragma multi_compile_instancing
        #pragma instancing_options renderinglayer
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
        #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX_NORMAL_OUTPUT
        #define FEATURES_GRAPH_VERTEX_TANGENT_OUTPUT
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_GBUFFER
        #define _SURFACE_TYPE_TRANSPARENT 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(ATTRIBUTES_NEED_INSTANCEID)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 texCoord0;
            #if !defined(LIGHTMAP_ON)
             float3 sh;
            #endif
            #if defined(USE_APV_PROBE_OCCLUSION)
             float4 probeOcclusion;
            #endif
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float2 NDCPosition;
             float2 PixelPosition;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
            #if !defined(LIGHTMAP_ON)
             float3 sh : INTERP0;
            #endif
            #if defined(USE_APV_PROBE_OCCLUSION)
             float4 probeOcclusion : INTERP1;
            #endif
             float4 texCoord0 : INTERP2;
             float3 positionWS : INTERP3;
             float3 normalWS : INTERP4;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            #if !defined(LIGHTMAP_ON)
            output.sh = input.sh;
            #endif
            #if defined(USE_APV_PROBE_OCCLUSION)
            output.probeOcclusion = input.probeOcclusion;
            #endif
            output.texCoord0.xyzw = input.texCoord0;
            output.positionWS.xyz = input.positionWS;
            output.normalWS.xyz = input.normalWS;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if !defined(LIGHTMAP_ON)
            output.sh = input.sh;
            #endif
            #if defined(USE_APV_PROBE_OCCLUSION)
            output.probeOcclusion = input.probeOcclusion;
            #endif
            output.texCoord0 = input.texCoord0.xyzw;
            output.positionWS = input.positionWS.xyz;
            output.normalWS = input.normalWS.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _Position;
        float _Radius;
        float2 _Ratio;
        float _Distance;
        float _CoreRadius;
        float _CoreBlur;
        float _DistortionRange;
        float _DistortionFade;
        UNITY_TEXTURE_STREAMING_DEBUG_VARS;
        CBUFFER_END
        
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_CameraSortingLayerTexture);
        SAMPLER(sampler_CameraSortingLayerTexture);
        float4 _CameraSortingLayerTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A - B;
        }
        
        void Unity_Divide_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A / B;
        }
        
        void Unity_Length_float2(float2 In, out float Out)
        {
            Out = length(In);
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Distance_float2(float2 A, float2 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D = UnityBuildTexture2DStructNoScale(_CameraSortingLayerTexture);
            float2 _Property_e75e244b614c4829b05138986a75fc12_Out_0_Vector2 = _Position;
            float4 _UV_874892e473a34f6dbc88b1f804656769_Out_0_Vector4 = IN.uv0;
            float2 _Property_ecfc3b67d2554fd9ae985e3e57ecdca5_Out_0_Vector2 = _Position;
            float2 _Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2;
            Unity_Subtract_float2((_UV_874892e473a34f6dbc88b1f804656769_Out_0_Vector4.xy), _Property_ecfc3b67d2554fd9ae985e3e57ecdca5_Out_0_Vector2, _Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2);
            float2 _Property_c3f7856863254c288c603001b50ba8ff_Out_0_Vector2 = _Ratio;
            float2 _Divide_bbaefc47cd0f463188f75f91c8846ac6_Out_2_Vector2;
            Unity_Divide_float2(_Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2, _Property_c3f7856863254c288c603001b50ba8ff_Out_0_Vector2, _Divide_bbaefc47cd0f463188f75f91c8846ac6_Out_2_Vector2);
            float _Length_cfe3565bc74d4090bf6fd91e1e81ff5e_Out_1_Float;
            Unity_Length_float2(_Divide_bbaefc47cd0f463188f75f91c8846ac6_Out_2_Vector2, _Length_cfe3565bc74d4090bf6fd91e1e81ff5e_Out_1_Float);
            float _Property_fe71b53d748a4cdf8fcd273e4e2ca4e6_Out_0_Float = _Distance;
            float _Power_a28c0469105048fc8cffa3077877b549_Out_2_Float;
            Unity_Power_float(_Property_fe71b53d748a4cdf8fcd273e4e2ca4e6_Out_0_Float, float(0.5), _Power_a28c0469105048fc8cffa3077877b549_Out_2_Float);
            float _Multiply_d019d20763b841c0b1e3c7b9cf246b4d_Out_2_Float;
            Unity_Multiply_float_float(_Length_cfe3565bc74d4090bf6fd91e1e81ff5e_Out_1_Float, _Power_a28c0469105048fc8cffa3077877b549_Out_2_Float, _Multiply_d019d20763b841c0b1e3c7b9cf246b4d_Out_2_Float);
            float _Power_a87d2c03897b4caaa34e210c8c8a1479_Out_2_Float;
            Unity_Power_float(_Multiply_d019d20763b841c0b1e3c7b9cf246b4d_Out_2_Float, float(2), _Power_a87d2c03897b4caaa34e210c8c8a1479_Out_2_Float);
            float _Property_647058a03fe446b48804baa913a1b34f_Out_0_Float = _Radius;
            float _Multiply_989b663afaf441319a0715f715a81e67_Out_2_Float;
            Unity_Multiply_float_float(_Power_a87d2c03897b4caaa34e210c8c8a1479_Out_2_Float, _Property_647058a03fe446b48804baa913a1b34f_Out_0_Float, _Multiply_989b663afaf441319a0715f715a81e67_Out_2_Float);
            float _Multiply_675a7cfba0094a858070d54dcd63b597_Out_2_Float;
            Unity_Multiply_float_float(_Multiply_989b663afaf441319a0715f715a81e67_Out_2_Float, 2, _Multiply_675a7cfba0094a858070d54dcd63b597_Out_2_Float);
            float _Divide_4202e6ad7f874154827f617c2306a0ad_Out_2_Float;
            Unity_Divide_float(float(1), _Multiply_675a7cfba0094a858070d54dcd63b597_Out_2_Float, _Divide_4202e6ad7f874154827f617c2306a0ad_Out_2_Float);
            float _OneMinus_151e1a1f7b8a42578a6fe655938f9d52_Out_1_Float;
            Unity_OneMinus_float(_Divide_4202e6ad7f874154827f617c2306a0ad_Out_2_Float, _OneMinus_151e1a1f7b8a42578a6fe655938f9d52_Out_1_Float);
            float2 _Multiply_aa08266616fd4bb99d0f0bc688b6d431_Out_2_Vector2;
            Unity_Multiply_float2_float2(_Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2, (_OneMinus_151e1a1f7b8a42578a6fe655938f9d52_Out_1_Float.xx), _Multiply_aa08266616fd4bb99d0f0bc688b6d431_Out_2_Vector2);
            float2 _Add_a402e642760e4c60981ad0560b974d74_Out_2_Vector2;
            Unity_Add_float2(_Property_e75e244b614c4829b05138986a75fc12_Out_0_Vector2, _Multiply_aa08266616fd4bb99d0f0bc688b6d431_Out_2_Vector2, _Add_a402e642760e4c60981ad0560b974d74_Out_2_Vector2);
            float4 _UV_d6a0a4f19fa54d2d9c881392792ea071_Out_0_Vector4 = IN.uv0;
            float2 _Subtract_501f809b35684c189118f8eac45c849a_Out_2_Vector2;
            Unity_Subtract_float2(_Add_a402e642760e4c60981ad0560b974d74_Out_2_Vector2, (_UV_d6a0a4f19fa54d2d9c881392792ea071_Out_0_Vector4.xy), _Subtract_501f809b35684c189118f8eac45c849a_Out_2_Vector2);
            float4 _ScreenPosition_3c9593d030d1476aac2fcfca3e04743b_Out_0_Vector4 = float4(IN.NDCPosition.xy, 0, 0);
            float2 _Add_5a101a9abbae433db4310a1d90597fb2_Out_2_Vector2;
            Unity_Add_float2(_Subtract_501f809b35684c189118f8eac45c849a_Out_2_Vector2, (_ScreenPosition_3c9593d030d1476aac2fcfca3e04743b_Out_0_Vector4.xy), _Add_5a101a9abbae433db4310a1d90597fb2_Out_2_Vector2);
            float4 _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4 = SAMPLE_TEXTURE2D(_Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D.tex, _Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D.samplerstate, _Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D.GetTransformedUV(_Add_5a101a9abbae433db4310a1d90597fb2_Out_2_Vector2) );
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_R_4_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.r;
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_G_5_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.g;
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_B_6_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.b;
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_A_7_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.a;
            float _Property_52231855222f4fbea0fb538009cb45fb_Out_0_Float = _CoreRadius;
            float _Property_33e8ef50dc4d498db98b948af9495bd4_Out_0_Float = _CoreBlur;
            float _Add_378db2f0aeae4e4bb001fcd3285618b9_Out_2_Float;
            Unity_Add_float(_Property_52231855222f4fbea0fb538009cb45fb_Out_0_Float, _Property_33e8ef50dc4d498db98b948af9495bd4_Out_0_Float, _Add_378db2f0aeae4e4bb001fcd3285618b9_Out_2_Float);
            float4 _UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4 = IN.uv0;
            float2 _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2 = float2(float(0.5), float(0.5));
            float _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float;
            Unity_Distance_float2((_UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4.xy), _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float);
            float _Smoothstep_ca941a008b414220ac943bd0a34ccb2a_Out_3_Float;
            Unity_Smoothstep_float(_Property_52231855222f4fbea0fb538009cb45fb_Out_0_Float, _Add_378db2f0aeae4e4bb001fcd3285618b9_Out_2_Float, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float, _Smoothstep_ca941a008b414220ac943bd0a34ccb2a_Out_3_Float);
            float4 _Multiply_0ae779bdc1ca451da0d842fb67a08712_Out_2_Vector4;
            Unity_Multiply_float4_float4(_SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4, (_Smoothstep_ca941a008b414220ac943bd0a34ccb2a_Out_3_Float.xxxx), _Multiply_0ae779bdc1ca451da0d842fb67a08712_Out_2_Vector4);
            float _Property_7860741471ae48ad83c819f704302922_Out_0_Float = _DistortionRange;
            float _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float = _DistortionFade;
            float _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float;
            Unity_Subtract_float(_Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float, _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float);
            float _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float;
            Unity_Smoothstep_float(_Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float, _Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float, _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float);
            float _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            Unity_OneMinus_float(_Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float, _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float);
            surface.BaseColor = (_Multiply_0ae779bdc1ca451da0d842fb67a08712_Out_2_Vector4.xyz);
            surface.Alpha = _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        
            #if UNITY_UV_STARTS_AT_TOP
            output.PixelPosition = float2(input.positionCS.x, (_ProjectionParams.x < 0) ? (_ScaledScreenParams.y - input.positionCS.y) : input.positionCS.y);
            #else
            output.PixelPosition = float2(input.positionCS.x, (_ProjectionParams.x > 0) ? (_ScaledScreenParams.y - input.positionCS.y) : input.positionCS.y);
            #endif
        
            output.NDCPosition = output.PixelPosition.xy / _ScaledScreenParams.xy;
            output.NDCPosition.y = 1.0f - output.NDCPosition.y;
        
            output.uv0 = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/UnlitGBufferPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "SceneSelectionPass"
            Tags
            {
                "LightMode" = "SceneSelectionPass"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX_NORMAL_OUTPUT
        #define FEATURES_GRAPH_VERTEX_TANGENT_OUTPUT
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENESELECTIONPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(ATTRIBUTES_NEED_INSTANCEID)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.texCoord0.xyzw = input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.texCoord0.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _Position;
        float _Radius;
        float2 _Ratio;
        float _Distance;
        float _CoreRadius;
        float _CoreBlur;
        float _DistortionRange;
        float _DistortionFade;
        UNITY_TEXTURE_STREAMING_DEBUG_VARS;
        CBUFFER_END
        
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_CameraSortingLayerTexture);
        SAMPLER(sampler_CameraSortingLayerTexture);
        float4 _CameraSortingLayerTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        void Unity_Distance_float2(float2 A, float2 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _Property_7860741471ae48ad83c819f704302922_Out_0_Float = _DistortionRange;
            float _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float = _DistortionFade;
            float _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float;
            Unity_Subtract_float(_Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float, _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float);
            float4 _UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4 = IN.uv0;
            float2 _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2 = float2(float(0.5), float(0.5));
            float _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float;
            Unity_Distance_float2((_UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4.xy), _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float);
            float _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float;
            Unity_Smoothstep_float(_Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float, _Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float, _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float);
            float _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            Unity_OneMinus_float(_Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float, _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float);
            surface.Alpha = _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        
            #if UNITY_UV_STARTS_AT_TOP
            #else
            #endif
        
        
            output.uv0 = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "ScenePickingPass"
            Tags
            {
                "LightMode" = "Picking"
            }
        
        // Render State
        Cull Back
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 2.0
        #pragma vertex vert
        #pragma fragment frag
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX_NORMAL_OUTPUT
        #define FEATURES_GRAPH_VERTEX_TANGENT_OUTPUT
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        #define SCENEPICKINGPASS 1
        #define ALPHA_CLIP_THRESHOLD 1
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(ATTRIBUTES_NEED_INSTANCEID)
             uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
             float2 NDCPosition;
             float2 PixelPosition;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float4 texCoord0 : INTERP0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
             uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
             uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
             uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
             FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.texCoord0.xyzw = input.texCoord0;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.texCoord0 = input.texCoord0.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float2 _Position;
        float _Radius;
        float2 _Ratio;
        float _Distance;
        float _CoreRadius;
        float _CoreBlur;
        float _DistortionRange;
        float _DistortionFade;
        UNITY_TEXTURE_STREAMING_DEBUG_VARS;
        CBUFFER_END
        
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_CameraSortingLayerTexture);
        SAMPLER(sampler_CameraSortingLayerTexture);
        float4 _CameraSortingLayerTexture_TexelSize;
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_Subtract_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A - B;
        }
        
        void Unity_Divide_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A / B;
        }
        
        void Unity_Length_float2(float2 In, out float Out)
        {
            Out = length(In);
        }
        
        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }
        
        void Unity_OneMinus_float(float In, out float Out)
        {
            Out = 1 - In;
        }
        
        void Unity_Multiply_float2_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }
        
        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }
        
        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }
        
        void Unity_Distance_float2(float2 A, float2 B, out float Out)
        {
            Out = distance(A, B);
        }
        
        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D = UnityBuildTexture2DStructNoScale(_CameraSortingLayerTexture);
            float2 _Property_e75e244b614c4829b05138986a75fc12_Out_0_Vector2 = _Position;
            float4 _UV_874892e473a34f6dbc88b1f804656769_Out_0_Vector4 = IN.uv0;
            float2 _Property_ecfc3b67d2554fd9ae985e3e57ecdca5_Out_0_Vector2 = _Position;
            float2 _Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2;
            Unity_Subtract_float2((_UV_874892e473a34f6dbc88b1f804656769_Out_0_Vector4.xy), _Property_ecfc3b67d2554fd9ae985e3e57ecdca5_Out_0_Vector2, _Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2);
            float2 _Property_c3f7856863254c288c603001b50ba8ff_Out_0_Vector2 = _Ratio;
            float2 _Divide_bbaefc47cd0f463188f75f91c8846ac6_Out_2_Vector2;
            Unity_Divide_float2(_Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2, _Property_c3f7856863254c288c603001b50ba8ff_Out_0_Vector2, _Divide_bbaefc47cd0f463188f75f91c8846ac6_Out_2_Vector2);
            float _Length_cfe3565bc74d4090bf6fd91e1e81ff5e_Out_1_Float;
            Unity_Length_float2(_Divide_bbaefc47cd0f463188f75f91c8846ac6_Out_2_Vector2, _Length_cfe3565bc74d4090bf6fd91e1e81ff5e_Out_1_Float);
            float _Property_fe71b53d748a4cdf8fcd273e4e2ca4e6_Out_0_Float = _Distance;
            float _Power_a28c0469105048fc8cffa3077877b549_Out_2_Float;
            Unity_Power_float(_Property_fe71b53d748a4cdf8fcd273e4e2ca4e6_Out_0_Float, float(0.5), _Power_a28c0469105048fc8cffa3077877b549_Out_2_Float);
            float _Multiply_d019d20763b841c0b1e3c7b9cf246b4d_Out_2_Float;
            Unity_Multiply_float_float(_Length_cfe3565bc74d4090bf6fd91e1e81ff5e_Out_1_Float, _Power_a28c0469105048fc8cffa3077877b549_Out_2_Float, _Multiply_d019d20763b841c0b1e3c7b9cf246b4d_Out_2_Float);
            float _Power_a87d2c03897b4caaa34e210c8c8a1479_Out_2_Float;
            Unity_Power_float(_Multiply_d019d20763b841c0b1e3c7b9cf246b4d_Out_2_Float, float(2), _Power_a87d2c03897b4caaa34e210c8c8a1479_Out_2_Float);
            float _Property_647058a03fe446b48804baa913a1b34f_Out_0_Float = _Radius;
            float _Multiply_989b663afaf441319a0715f715a81e67_Out_2_Float;
            Unity_Multiply_float_float(_Power_a87d2c03897b4caaa34e210c8c8a1479_Out_2_Float, _Property_647058a03fe446b48804baa913a1b34f_Out_0_Float, _Multiply_989b663afaf441319a0715f715a81e67_Out_2_Float);
            float _Multiply_675a7cfba0094a858070d54dcd63b597_Out_2_Float;
            Unity_Multiply_float_float(_Multiply_989b663afaf441319a0715f715a81e67_Out_2_Float, 2, _Multiply_675a7cfba0094a858070d54dcd63b597_Out_2_Float);
            float _Divide_4202e6ad7f874154827f617c2306a0ad_Out_2_Float;
            Unity_Divide_float(float(1), _Multiply_675a7cfba0094a858070d54dcd63b597_Out_2_Float, _Divide_4202e6ad7f874154827f617c2306a0ad_Out_2_Float);
            float _OneMinus_151e1a1f7b8a42578a6fe655938f9d52_Out_1_Float;
            Unity_OneMinus_float(_Divide_4202e6ad7f874154827f617c2306a0ad_Out_2_Float, _OneMinus_151e1a1f7b8a42578a6fe655938f9d52_Out_1_Float);
            float2 _Multiply_aa08266616fd4bb99d0f0bc688b6d431_Out_2_Vector2;
            Unity_Multiply_float2_float2(_Subtract_1040dc22f9a4460f96200b1e0d5c34a8_Out_2_Vector2, (_OneMinus_151e1a1f7b8a42578a6fe655938f9d52_Out_1_Float.xx), _Multiply_aa08266616fd4bb99d0f0bc688b6d431_Out_2_Vector2);
            float2 _Add_a402e642760e4c60981ad0560b974d74_Out_2_Vector2;
            Unity_Add_float2(_Property_e75e244b614c4829b05138986a75fc12_Out_0_Vector2, _Multiply_aa08266616fd4bb99d0f0bc688b6d431_Out_2_Vector2, _Add_a402e642760e4c60981ad0560b974d74_Out_2_Vector2);
            float4 _UV_d6a0a4f19fa54d2d9c881392792ea071_Out_0_Vector4 = IN.uv0;
            float2 _Subtract_501f809b35684c189118f8eac45c849a_Out_2_Vector2;
            Unity_Subtract_float2(_Add_a402e642760e4c60981ad0560b974d74_Out_2_Vector2, (_UV_d6a0a4f19fa54d2d9c881392792ea071_Out_0_Vector4.xy), _Subtract_501f809b35684c189118f8eac45c849a_Out_2_Vector2);
            float4 _ScreenPosition_3c9593d030d1476aac2fcfca3e04743b_Out_0_Vector4 = float4(IN.NDCPosition.xy, 0, 0);
            float2 _Add_5a101a9abbae433db4310a1d90597fb2_Out_2_Vector2;
            Unity_Add_float2(_Subtract_501f809b35684c189118f8eac45c849a_Out_2_Vector2, (_ScreenPosition_3c9593d030d1476aac2fcfca3e04743b_Out_0_Vector4.xy), _Add_5a101a9abbae433db4310a1d90597fb2_Out_2_Vector2);
            float4 _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4 = SAMPLE_TEXTURE2D(_Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D.tex, _Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D.samplerstate, _Property_9868397fdaa84fe998423349aef9eebb_Out_0_Texture2D.GetTransformedUV(_Add_5a101a9abbae433db4310a1d90597fb2_Out_2_Vector2) );
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_R_4_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.r;
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_G_5_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.g;
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_B_6_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.b;
            float _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_A_7_Float = _SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4.a;
            float _Property_52231855222f4fbea0fb538009cb45fb_Out_0_Float = _CoreRadius;
            float _Property_33e8ef50dc4d498db98b948af9495bd4_Out_0_Float = _CoreBlur;
            float _Add_378db2f0aeae4e4bb001fcd3285618b9_Out_2_Float;
            Unity_Add_float(_Property_52231855222f4fbea0fb538009cb45fb_Out_0_Float, _Property_33e8ef50dc4d498db98b948af9495bd4_Out_0_Float, _Add_378db2f0aeae4e4bb001fcd3285618b9_Out_2_Float);
            float4 _UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4 = IN.uv0;
            float2 _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2 = float2(float(0.5), float(0.5));
            float _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float;
            Unity_Distance_float2((_UV_57f4be7db36947d99b27019b6d7c8c0a_Out_0_Vector4.xy), _Vector2_c05f40a1f17f4cffa91215a505734c43_Out_0_Vector2, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float);
            float _Smoothstep_ca941a008b414220ac943bd0a34ccb2a_Out_3_Float;
            Unity_Smoothstep_float(_Property_52231855222f4fbea0fb538009cb45fb_Out_0_Float, _Add_378db2f0aeae4e4bb001fcd3285618b9_Out_2_Float, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float, _Smoothstep_ca941a008b414220ac943bd0a34ccb2a_Out_3_Float);
            float4 _Multiply_0ae779bdc1ca451da0d842fb67a08712_Out_2_Vector4;
            Unity_Multiply_float4_float4(_SampleTexture2D_d6137b77374949799295a7dbf9fca2c7_RGBA_0_Vector4, (_Smoothstep_ca941a008b414220ac943bd0a34ccb2a_Out_3_Float.xxxx), _Multiply_0ae779bdc1ca451da0d842fb67a08712_Out_2_Vector4);
            float _Property_7860741471ae48ad83c819f704302922_Out_0_Float = _DistortionRange;
            float _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float = _DistortionFade;
            float _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float;
            Unity_Subtract_float(_Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Property_839d31fbe8b44e8ea8b5897e6c60507b_Out_0_Float, _Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float);
            float _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float;
            Unity_Smoothstep_float(_Subtract_6d1a664a94a547859e50c5cb3134988a_Out_2_Float, _Property_7860741471ae48ad83c819f704302922_Out_0_Float, _Distance_8f17ea9c41fd41309a6923b5cddcfd49_Out_2_Float, _Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float);
            float _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            Unity_OneMinus_float(_Smoothstep_4b92217cfdb74debadd38c7b3b5ac898_Out_3_Float, _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float);
            surface.BaseColor = (_Multiply_0ae779bdc1ca451da0d842fb67a08712_Out_2_Vector4.xyz);
            surface.Alpha = _OneMinus_d5e0bef5811f45a7b49e7916eb651243_Out_1_Float;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
        #if VFX_USE_GRAPH_VALUES
            uint instanceActiveIndex = asuint(UNITY_ACCESS_INSTANCED_PROP(PerInstance, _InstanceActiveIndex));
            /* WARNING: $splice Could not find named fragment 'VFXLoadGraphValues' */
        #endif
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        
            #if UNITY_UV_STARTS_AT_TOP
            output.PixelPosition = float2(input.positionCS.x, (_ProjectionParams.x < 0) ? (_ScaledScreenParams.y - input.positionCS.y) : input.positionCS.y);
            #else
            output.PixelPosition = float2(input.positionCS.x, (_ProjectionParams.x > 0) ? (_ScaledScreenParams.y - input.positionCS.y) : input.positionCS.y);
            #endif
        
            output.NDCPosition = output.PixelPosition.xy / _ScaledScreenParams.xy;
            output.NDCPosition.y = 1.0f - output.NDCPosition.y;
        
            output.uv0 = input.texCoord0;
        #if UNITY_ANY_INSTANCING_ENABLED
        #else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
        #endif
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
    }
    CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
    CustomEditorForRenderPipeline "UnityEditor.ShaderGraphUnlitGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
    FallBack "Hidden/Shader Graph/FallbackError"
}