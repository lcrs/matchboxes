// Undiverge a vector field
// Pass 9 - get gradient of pressure field and subtract from original
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass8, adsk_results_pass1, vecs;
uniform float adsk_result_w, adsk_result_h;
uniform float dpressure, amountmaster, excitablity, inputamount;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	vec4 v = texture2D(adsk_results_pass1, xy * px);
	vec3 inputvecs = texture2D(vecs, xy * px).rgb;

	float pressure = texture2D(adsk_results_pass8, xy * px).g;

	vec2 d = vec2(0.0);
	d.r -= texture2D(adsk_results_pass8, (xy + vec2(+dpressure, 0.0)) * px).g / dpressure;
	d.r += texture2D(adsk_results_pass8, (xy + vec2(-dpressure, 0.0)) * px).g / dpressure;
	d.g -= texture2D(adsk_results_pass8, (xy + vec2(0.0, +dpressure)) * px).g / dpressure;
	d.g += texture2D(adsk_results_pass8, (xy + vec2(0.0, -dpressure)) * px).g / dpressure;

	vec2 undiverged = v.rg + 10.0 * amountmaster * d;

	undiverged.rg += inputamount * inputvecs.rg;
	undiverged.rg *= excitablity/100.0;

	gl_FragColor = vec4(undiverged.r, undiverged.g, v.b, v.a);
}
