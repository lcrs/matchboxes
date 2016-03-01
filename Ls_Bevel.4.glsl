// Bevel
// Pass 4: gradient detection and actual beveling
// Broadly, we use the gradient vector of the blurred
// image as the X/Y components of a normal vector, which
// we then dot with the light direction.
// To get the sharp edge, we normalize the gradient, then
// use smoothstep() to remove the nasty artifacts where
// it was near zero.  This gives us a kinda level-set iso-line
// of the blurred image, which roughly follows the outline of
// the text.  It ain't perfect!
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass3, adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h;
uniform float sigma, ambient, smoothy;
uniform vec3 lite;
uniform bool normals;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);
	float fron = texture2D(adsk_results_pass1, xy * px).g;

	// Find gradients with X/Y Sobel convolution
	vec2 d;
	float ksize = sigma/2.0;
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
	d /= ksize;

	float len = length(d);
	float edge = smoothstep(0.0, smoothy/100.0, len);

	d = normalize(d);

	if(normals) {
		vec3 n = vec3(d.x, d.y, 1.0);
		n = mix(vec3(0.0, 0.0, 1.0), n, edge);
		gl_FragColor = vec4(n, fron);
		return;
	}

	float l = dot(d, normalize(lite.xy - vec2(0.5)));
	l = mix(l, fron, ambient);
	l = mix(ambient * fron, l, edge);
	l *= fron;

	vec4 o = vec4(l, l, l, fron);
	gl_FragColor = o;
}
