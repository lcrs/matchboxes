// Pass 1: advect the vectors by themselves
// (modified to be super simple for debugging - this pass
//  picks up the accumulation result and does a little colour correct)
// lewis@lewissaunders.com

uniform sampler2D start, adsk_accum_texture;
uniform float adsk_result_w, adsk_result_h;
uniform bool adsk_accum_no_prev_frame;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	vec3 acc;
	if(adsk_accum_no_prev_frame) {
		acc = texture2D(start, xy*px).rgb;
	} else {
		acc = texture2D(adsk_accum_texture, xy*px).rgb;
	}

	gl_FragColor = vec4(acc, 1.0);
}
