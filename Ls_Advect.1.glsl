// Pass 1: make the vectors
// lewis@lewissaunders.com
// TODO:
//  o Pre-blur input in case of kinks?

uniform sampler2D map;
uniform float adsk_result_w, adsk_result_h, ksize;
uniform bool radial, directvectors;

void main() {
	vec2 xy = gl_FragCoord.xy;

	// Factor to convert pixels to [0,1] texture coords
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	vec2 d = vec2(0.0);

	if(directvectors) {
		// Map input is already vectors, yay!
		d = texture2D(map, xy * px).xy;
		if(radial) {
			// Rotate 90 degrees
			d = vec2(-d.y, d.x);
		}
		gl_FragColor = vec4(d.x, d.y, 0.0, 1.0);
		return;
	}

	// Convolve by x and y Sobel matrices to get gradient vector
	d.x  =  1.0 * texture2D(map, (xy + ksize * vec2(-1.0, -1.0)) * px).g;
	d.x +=  2.0 * texture2D(map, (xy + ksize * vec2(-1.0,  0.0)) * px).g;
	d.x +=  1.0 * texture2D(map, (xy + ksize * vec2(-1.0, +1.0)) * px).g;
	d.x += -1.0 * texture2D(map, (xy + ksize * vec2(+1.0, -1.0)) * px).g;
	d.x += -2.0 * texture2D(map, (xy + ksize * vec2(+1.0,  0.0)) * px).g;
	d.x += -1.0 * texture2D(map, (xy + ksize * vec2(+1.0, +1.0)) * px).g;
	d.y +=  1.0 * texture2D(map, (xy + ksize * vec2(-1.0, -1.0)) * px).g;
	d.y +=  2.0 * texture2D(map, (xy + ksize * vec2( 0.0, -1.0)) * px).g;
	d.y +=  1.0 * texture2D(map, (xy + ksize * vec2(+1.0, -1.0)) * px).g;
	d.y += -1.0 * texture2D(map, (xy + ksize * vec2(-1.0, +1.0)) * px).g;
	d.y += -2.0 * texture2D(map, (xy + ksize * vec2( 0.0, +1.0)) * px).g;
	d.y += -1.0 * texture2D(map, (xy + ksize * vec2(+1.0, +1.0)) * px).g;

	if(!radial) {
		// Rotate 90 degrees
		d = vec2(-d.y, d.x);
	}

	// Bit of a bodge factor right here
	d *= 32.0 / ksize;

	// Output vectors for second pass
	gl_FragColor = vec4(d.x, d.y, 0.0, 1.0);
}
