// Recursively warp an image by motion vectors to stick it to something
// lewis@lewissaunders.com
// Pass 2: comp and output distorted image

uniform sampler2D front, matte, back, adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h;
uniform bool accumulateUVs;
uniform bool outputUVs;
uniform bool comp, ispremult;

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 uv = gl_FragCoord.xy / res;
	vec4 o;

	if(accumulateUVs) {
		vec2 accumulatedUV = texture2D(adsk_results_pass1, uv).rg;
		if(outputUVs) {
			// Output accumulated UVs directly
			o.rg = accumulatedUV;
			o.ba = vec2(0.0);
		} else {
			// Output of pass 1 is UVs, distort front and matte using them
			o.rgb = texture2D(front, accumulatedUV).rgb;
			o.a = texture2D(matte, accumulatedUV).b;
		}
	} else {
		// Output of pass 1 is image, we can use directly
		o.rgb = texture2D(adsk_results_pass1, uv).rgb;
		o.a = texture2D(adsk_results_pass1, uv).a;
	}

	if(!(outputUVs && accumulateUVs) && comp) {
		vec3 bg = texture2D(back, uv).rgb;
		if(ispremult) {
			o.rgb = bg * (1.0 - o.a) + o.rgb;
		} else {
			o.rgb = mix(bg.rgb, o.rgb, o.a);
		}
	}

	gl_FragColor = o;
}
