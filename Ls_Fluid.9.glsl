// Pass 9 - get gradient of pressure field and subtract from original
// (modified to be super simple for debugging - this pass
//  combines previous passes and offsets in space a little to check
//  if accumulation is working)
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass8, adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	xy += vec2(10.0);

	vec3 a = texture2D(adsk_results_pass8, xy * px).rgb;
	a *= texture2D(adsk_results_pass1, xy * px).rgb;

	gl_FragColor = vec4(a, 1.0);
}
