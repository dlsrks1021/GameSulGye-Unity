﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/SimplePlaneShader"
{
	Properties
	{
		_Color("Main Color", Color) = (1,1,1,1)
		_MainTex("Base (RGB) Alpha (A)", 2D) = "white" {}
	}
	SubShader
	{
		Tags{ "Queue" = "Geometry" "RenderType" = "Opaque" }
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }                      // This Pass tag is important or Unity may not give it the correct light information.
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase                       // This line tells Unity to compile this pass for forward base.

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct vertex_input
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord : TEXCOORD0;
			};

			struct vertex_output
			{
				float4  pos         : SV_POSITION;
				float2  uv          : TEXCOORD0;
				float3  lightDir    : TEXCOORD1;
				float3  normal		: TEXCOORD2;
				LIGHTING_COORDS(3,4)                            // Macro to send shadow & attenuation to the vertex shader.
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed4 _LightColor0;

			vertex_output vert(vertex_input v)
			{
				vertex_output o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;

				o.lightDir = ObjSpaceLightDir(v.vertex);

				o.normal = v.normal;

				TRANSFER_VERTEX_TO_FRAGMENT(o);                 // Macro to send shadow & attenuation to the fragment shader.

				return o;
			}

			fixed4 frag(vertex_output i) : COLOR
			{
				i.lightDir = normalize(i.lightDir);
				fixed atten = LIGHT_ATTENUATION(i); // Macro to get you the combined shadow & attenuation value.

				fixed4 tex = tex2D(_MainTex, i.uv);
				tex *= _Color;

				fixed diff = saturate(dot(i.normal, i.lightDir));

				fixed4 c;
				c.rgb = (UNITY_LIGHTMODEL_AMBIENT.rgb * 2 * tex.rgb);         // Ambient term. Only do this in Forward Base. It only needs calculating once.
				c.rgb += (tex.rgb * _LightColor0.rgb * diff) * (atten * 2); // Diffuse and specular.
				c.a = tex.a + _LightColor0.a * atten;
				return c;
			}
		ENDCG
		}

		Pass
		{
			Tags{ "LightMode" = "ForwardAdd" }                       // Again, this pass tag is important otherwise Unity may not give the correct light information.
			Blend One One                                           // Additively blend this pass with the previous one(s). This pass gets run once per pixel light.
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd_fullshadows               // This line tells Unity to compile this pass for forward add, giving attenuation information for the light with full shadow information.

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct v2f
			{
				float4  pos         : SV_POSITION;
				float2  uv          : TEXCOORD0;
				float3  lightDir    : TEXCOORD2;
				float3 normal		: TEXCOORD1;
				LIGHTING_COORDS(3,4)                            // Macro to send shadow & attenuation to the vertex shader.
			};

			v2f vert(appdata_tan v)
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;

				o.lightDir = ObjSpaceLightDir(v.vertex);

				o.normal = v.normal;
				TRANSFER_VERTEX_TO_FRAGMENT(o);                 // Macro to send shadow & attenuation to the fragment shader.
				return o;
			}

			sampler2D _MainTex;
			fixed4 _Color;

			fixed4 _LightColor0; // Colour of the light used in this pass.

			fixed4 frag(v2f i) : COLOR
			{
				i.lightDir = normalize(i.lightDir);

				fixed atten = LIGHT_ATTENUATION(i); // Macro to get you the combined shadow & attenuation value.

				fixed4 tex = tex2D(_MainTex, i.uv);

				tex *= _Color;

				fixed3 normal = i.normal;
				fixed diff = saturate(dot(normal, i.lightDir));


				fixed4 c;
				c.rgb = (tex.rgb * _LightColor0.rgb * diff) * (atten * 2); // Diffuse and specular.
				c.a = tex.a;
				return c;
			}
			ENDCG
		}
	}
	FallBack "VertexLit"    // Use VertexLit's shadow caster/receiver passes.
}