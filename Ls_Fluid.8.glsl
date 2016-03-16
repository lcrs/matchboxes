// Undiverge a vector field
// Pass 8 - combine the three blurs, and differentiate to get an approximation of the
// pressure field
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass3, adsk_results_pass5, adsk_results_pass7;
uniform float adsk_result_w, adsk_result_h;
uniform float d1, d2, d3, amount1, amount2, amount3;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	vec3 a = vec3(0.0);
	a.r -= (amount1/d1) * texture2D(adsk_results_pass3, (xy + vec2(+d1, 0.0)) * px).r;
	a.r += (amount1/d1) * texture2D(adsk_results_pass3, (xy + vec2(-d1, 0.0)) * px).r;
	a.g -= (amount1/d1) * texture2D(adsk_results_pass3, (xy + vec2(0.0, +d1)) * px).g;
	a.g += (amount1/d1) * texture2D(adsk_results_pass3, (xy + vec2(0.0, -d1)) * px).g;
	a.r -= (amount2/d2) * texture2D(adsk_results_pass5, (xy + vec2(+d2, 0.0)) * px).r;
	a.r += (amount2/d2) * texture2D(adsk_results_pass5, (xy + vec2(-d2, 0.0)) * px).r;
	a.g -= (amount2/d2) * texture2D(adsk_results_pass5, (xy + vec2(0.0, +d2)) * px).g;
	a.g += (amount2/d2) * texture2D(adsk_results_pass5, (xy + vec2(0.0, -d2)) * px).g;
	a.r -= (amount3/d3) * texture2D(adsk_results_pass7, (xy + vec2(+d3, 0.0)) * px).r;
	a.r += (amount3/d3) * texture2D(adsk_results_pass7, (xy + vec2(-d3, 0.0)) * px).r;
	a.g -= (amount3/d3) * texture2D(adsk_results_pass7, (xy + vec2(0.0, +d3)) * px).g;
	a.g += (amount3/d3) * texture2D(adsk_results_pass7, (xy + vec2(0.0, -d3)) * px).g;

	float pressure = a.r + a.g;

	gl_FragColor = vec4(pressure);
}
