// Pass 6 - Gaussian blur 3, horizontal
// (modified to be super simple for debugging - this pass
//  just does a little colour correct)
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass5;
uniform float adsk_result_w, adsk_result_h;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	vec3 a = texture2D(adsk_results_pass5, xy * px).rgb;
	a += vec3(0.0, 0.1, 0.1);

	gl_FragColor = vec4(a, 1.0);
}
