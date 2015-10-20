// Undiverge a vector field
// Pass 9 - get gradient of pressure field and subtract from original
// lewis@lewissaunders.com

uniform sampler2D start, adsk_results_pass8, adsk_accum_texture;
uniform float adsk_result_w, adsk_result_h;
uniform float dpressure, amountmaster;
uniform bool adsk_accum_no_prev_frame;

vec2 get(vec2 uv) {
	if(adsk_accum_no_prev_frame){
		return texture2D(start, uv).xy;
	} else {
		return texture2D(adsk_accum_texture, uv).xy;
	}
}

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	vec3 frontpix = texture2D(start, xy * px).rgb;
	float pressure = texture2D(adsk_results_pass8, xy * px).g;

	vec3 d = vec3(0.0);
	d.r -= texture2D(adsk_results_pass8, (xy + vec2(+dpressure, 0.0)) * px).g;
	d.r += texture2D(adsk_results_pass8, (xy + vec2(-dpressure, 0.0)) * px).g;
	d.g -= texture2D(adsk_results_pass8, (xy + vec2(0.0, +dpressure)) * px).g;
	d.g += texture2D(adsk_results_pass8, (xy + vec2(0.0, -dpressure)) * px).g;

	vec3 undiverged = frontpix + amountmaster * d;
	undiverged.b = frontpix.b;

	gl_FragColor = vec4(undiverged, pressure);
}
