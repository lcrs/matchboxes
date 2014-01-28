// Pass 2: do the displace
// lewis@lewissaunders.com

uniform sampler2D front, map, adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h, blength;
uniform int samples;
uniform bool radial, vectors, normalize, adsk_degrade;

void main() {
	vec2 xy = gl_FragCoord.xy;

	// Factor to convert [0,1] texture coords to pixels
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	// Get vectors from previous pass
	vec2 d = texture2D(adsk_results_pass1, xy * px).xy;

	if(vectors) {
		// Return the vectors, not the blur
		if(normalize) {
			// Bodge factor for a resonable result from PixelSpread
			d /= 4.0;
			d += 0.5;
			gl_FragColor = vec4(d.x, d.y, 1.0, 1.0);
		} else {
			gl_FragColor = vec4(d.x, d.y, 0.0, 1.0);
		}
		return;
	}

	if(length(d) == 0.0) {
		// No gradient at this point in the map, early out
		gl_FragColor = texture2D(front, xy * px);
		return;
	}
	
	float sam = float(samples);
	if(adsk_degrade) {
		sam /= 4.0;
	}

	// Walk along the path...
	for(float i = 0.0; i < sam; i++) {
		d = texture2D(adsk_results_pass1, xy * px).xy;
		xy += d * (blength/sam);
	}

	// ...and sample where we ended up
	gl_FragColor = texture2D(front, xy * px);
}
