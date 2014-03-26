// Bevel
// Pass 4: gradient detection and actual beveling
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass3, adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h;
uniform float ksize, direction, ambient;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	float sigma = 1.0;

	// Find gradients with X/Y Sobel convolution
	vec2 d;
	d.x  =  1.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2(-1.0, -1.0)) * px).g;
	d.x +=  2.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2(-1.0,  0.0)) * px).g;
	d.x +=  1.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2(-1.0, +1.0)) * px).g;
	d.x += -1.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2(+1.0, -1.0)) * px).g;
	d.x += -2.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2(+1.0,  0.0)) * px).g;
	d.x += -1.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2(+1.0, +1.0)) * px).g;
	d.y  =  1.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2(-1.0, -1.0)) * px).g;
	d.y +=  2.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2( 0.0, -1.0)) * px).g;
	d.y +=  1.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2(+1.0, -1.0)) * px).g;
	d.y += -1.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2(-1.0, +1.0)) * px).g;
	d.y += -2.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2( 0.0, +1.0)) * px).g;
	d.y += -1.0 * texture2D(adsk_results_pass3, (xy + ksize * vec2(+1.0, +1.0)) * px).g;
	d = normalize(d);

	vec4 f = texture2D(adsk_results_pass1, xy * px);
	vec4 o = vec4(d.x) * f;
	o = mix(o, f, ambient);

	gl_FragColor = o;
}
