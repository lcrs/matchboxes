// Undiverge a vector field
// Pass 9 - get gradient of pressure field and subtract from original
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass8, adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h;
uniform float dpressure, amountmaster;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	vec3 v = texture2D(adsk_results_pass1, xy * px).rgb;

	float pressure = texture2D(adsk_results_pass8, xy * px).g;

	vec3 d = vec3(0.0);
	d.r -= texture2D(adsk_results_pass8, (xy + vec2(+dpressure, 0.0)) * px).g;
	d.r += texture2D(adsk_results_pass8, (xy + vec2(-dpressure, 0.0)) * px).g;
	d.g -= texture2D(adsk_results_pass8, (xy + vec2(0.0, +dpressure)) * px).g;
	d.g += texture2D(adsk_results_pass8, (xy + vec2(0.0, -dpressure)) * px).g;

	vec3 undiverged = v + amountmaster * d;

	gl_FragColor = vec4(undiverged, pressure);
}
