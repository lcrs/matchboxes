// Sweat, pass 3: read sim matte and derive UVs
// This is in a seperate pass to cache the UVs so we can multisample
// them more cheaply
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass2, front;
uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform float ksize;

void main() {
  vec2 res = vec2(adsk_result_w, adsk_result_h);
  vec2 xy = gl_FragCoord.xy;
  float h = texture2D(adsk_results_pass2, xy/res).r;

	// Convolve by x and y Sobel matrices to get gradient vector
  vec2 d;
	d.x  = -1.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2(-1.0, -1.0)) / res).g;
	d.x += -2.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2(-1.0,  0.0)) / res).g;
	d.x += -1.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2(-1.0, +1.0)) / res).g;
	d.x +=  1.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2(+1.0, -1.0)) / res).g;
	d.x +=  2.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2(+1.0,  0.0)) / res).g;
	d.x +=  1.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2(+1.0, +1.0)) / res).g;
	d.y  = -1.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2(-1.0, -1.0)) / res).g;
	d.y += -2.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2( 0.0, -1.0)) / res).g;
	d.y += -1.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2(+1.0, -1.0)) / res).g;
	d.y +=  1.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2(-1.0, +1.0)) / res).g;
	d.y +=  2.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2( 0.0, +1.0)) / res).g;
	d.y +=  1.0 * texture2D(adsk_results_pass2, (xy + ksize * vec2(+1.0, +1.0)) / res).g;
  d /= ksize;
  
  gl_FragColor = vec4(d, h, h);
}
