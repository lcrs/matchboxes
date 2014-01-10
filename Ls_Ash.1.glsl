// Adaptive sharpening
// Pass 1: edge detection
// lewis@lewissaunders.com

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
uniform float ksize, threshold;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	vec4 orig = texture2D(front, xy * px);

	float ksize = 1.0;

	// Find gradients of front with X/Y Sobel convolution
	vec2 d;
	d.x  =  1.0 * texture2D(front, (xy + ksize * vec2(-1.0, -1.0)) * px).g;
	d.x +=  2.0 * texture2D(front, (xy + ksize * vec2(-1.0,  0.0)) * px).g;
	d.x +=  1.0 * texture2D(front, (xy + ksize * vec2(-1.0, +1.0)) * px).g;
	d.x += -1.0 * texture2D(front, (xy + ksize * vec2(+1.0, -1.0)) * px).g;
	d.x += -2.0 * texture2D(front, (xy + ksize * vec2(+1.0,  0.0)) * px).g;
	d.x += -1.0 * texture2D(front, (xy + ksize * vec2(+1.0, +1.0)) * px).g;
	d.y  =  1.0 * texture2D(front, (xy + ksize * vec2(-1.0, -1.0)) * px).g;
	d.y +=  2.0 * texture2D(front, (xy + ksize * vec2( 0.0, -1.0)) * px).g;
	d.y +=  1.0 * texture2D(front, (xy + ksize * vec2(+1.0, -1.0)) * px).g;
	d.y += -1.0 * texture2D(front, (xy + ksize * vec2(-1.0, +1.0)) * px).g;
	d.y += -2.0 * texture2D(front, (xy + ksize * vec2( 0.0, +1.0)) * px).g;
	d.y += -1.0 * texture2D(front, (xy + ksize * vec2(+1.0, +1.0)) * px).g;

	// Magnitude of gradients finds edges
	float mag = length(d);
	float edginess = mag;

	// Threshold removes minor edges
	edginess *= 1.0 - threshold;
	edginess -= threshold;

	gl_FragColor = vec4(orig.r, orig.g, orig.b, edginess);
}
