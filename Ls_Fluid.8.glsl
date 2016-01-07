// Pass 8 - combine to get pressure field
// (modified to be super simple for debugging - this pass
//  combines previous passes)
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass3, adsk_results_pass5, adsk_results_pass7;
uniform float adsk_result_w, adsk_result_h;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	vec3 a = texture2D(adsk_results_pass3, xy * px).rgb;
	a *= texture2D(adsk_results_pass5, xy * px).rgb;
	a *= texture2D(adsk_results_pass7, xy * px).rgb;

	gl_FragColor = vec4(a.g);
}
