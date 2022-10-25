#version 120

// This single pass runs several times, first doing repeated
// 3x3 medians and then keying locally-hot pixels and replacing
// them with the median

uniform sampler2D front, strength, adsk_results_pass1;
uniform int iterations, adsk_result_execution;
uniform float sensitivity, trimnoise;
uniform bool showfireflies, showmedian;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

// Macros for sorting network below
#define COMPARE(a, b) length(v[a]) < length(v[b])
#define SWAP(a, b) temp = v[a]; v[a] = v[b]; v[b] = temp;
#define COMPARESWAP(a, b) if(COMPARE(a, b)) { SWAP(a, b) }

void main(void) {
	vec2 xy = gl_FragCoord.xy;

	if(adsk_result_execution == 0) {
		// First time we just pass through the front input
		gl_FragColor = texture2D(front, xy / res);
		return;
	} else if(adsk_result_execution <= iterations) {
		// 3x3 brightness-based median using a 9-input sorting network
		// The comparator order comes from Ls_Fireflies_sortingnetwork.pl
		vec3 v[9];		
		v[0] = texture2D(adsk_results_pass1, (xy + vec2(-1, -1)) / res).rgb;
		v[1] = texture2D(adsk_results_pass1, (xy + vec2(-1, 0)) / res).rgb;
		v[2] = texture2D(adsk_results_pass1, (xy + vec2(-1, 1)) / res).rgb;
		v[3] = texture2D(adsk_results_pass1, (xy + vec2(0, -1)) / res).rgb;
		v[4] = texture2D(adsk_results_pass1, (xy + vec2(0, 0)) / res).rgb;
		v[5] = texture2D(adsk_results_pass1, (xy + vec2(0, 1)) / res).rgb;
		v[6] = texture2D(adsk_results_pass1, (xy + vec2(1, -1)) / res).rgb;
		v[7] = texture2D(adsk_results_pass1, (xy + vec2(1, 0)) / res).rgb;
		v[8] = texture2D(adsk_results_pass1, (xy + vec2(1, 1)) / res).rgb;
		vec3 temp;
		COMPARESWAP(2, 6)
		COMPARESWAP(0, 5)
		COMPARESWAP(1, 4)
		COMPARESWAP(7, 8)
		COMPARESWAP(0, 7)
		COMPARESWAP(1, 2)
		COMPARESWAP(3, 5)
		COMPARESWAP(4, 6)
		COMPARESWAP(5, 8)
		COMPARESWAP(1, 3)
		COMPARESWAP(2, 7)
		COMPARESWAP(6, 8)
		COMPARESWAP(0, 1)
		COMPARESWAP(4, 5)
		COMPARESWAP(3, 7)
		COMPARESWAP(3, 4)
		COMPARESWAP(5, 6)
		COMPARESWAP(1, 2)
		COMPARESWAP(1, 3)
		COMPARESWAP(6, 7)
		COMPARESWAP(4, 5)
		COMPARESWAP(2, 4)
		COMPARESWAP(5, 6)
		COMPARESWAP(2, 3)
		COMPARESWAP(4, 5)
		gl_FragColor = vec4(v[4], 0.0);
		return;
	} else if(adsk_result_execution == (iterations+1)) {
		// Key and replace hot pixels
		vec3 surround = vec3(0.0);
		surround += texture2D(front, (xy + vec2(-1, -1)) / res).rgb;
		surround += texture2D(front, (xy + vec2(-1, 0)) / res).rgb;
		surround += texture2D(front, (xy + vec2(-1, 1)) / res).rgb;
		surround += texture2D(front, (xy + vec2(0, -1)) / res).rgb;
		surround += texture2D(front, (xy + vec2(0, 1)) / res).rgb;
		surround += texture2D(front, (xy + vec2(1, -1)) / res).rgb;
		surround += texture2D(front, (xy + vec2(1, 0)) / res).rgb;
		surround += texture2D(front, (xy + vec2(1, 1)) / res).rgb;
		surround /= vec3(8.0);

		vec3 frontpix = texture2D(front, xy / res).rgb;
		float strength = texture2D(strength, xy / res).b;
		float difference = length(clamp(frontpix - surround, vec3(-trimnoise), vec3(1.0)));
		float blend = clamp(difference * sensitivity * strength, 0.0, 1.0);

		vec3 median = texture2D(adsk_results_pass1, xy / res).rgb;
		vec3 outpix = mix(frontpix, median, blend);
		if(showfireflies) outpix = mix(vec3(0.0), frontpix, blend);
		if(showmedian) outpix = median;

		gl_FragColor = vec4(outpix, blend);
		return;
	} else {
		// Pass through previous result (we may run more times than needed)
		gl_FragColor = texture2D(adsk_results_pass1, xy / res);
		return;
	}
}
