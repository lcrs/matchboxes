// Pass 2: do the displace
// TODO:
//  o Extra per-step transform controls?
//  o Spread samples out along normal to path direction?
// lewis@lewissaunders.com

uniform sampler2D front, map, adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h, blength, spacing, maxlength;
uniform int samples, oversamples;
uniform vec2 bl, tr;
uniform bool radial, vectors, normalize, adsk_degrade, fade;

void main() {
	vec2 xy = gl_FragCoord.xy;

	// Factor to convert pixels to [0,1] texture coords
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

	// Crop
	vec2 xyn = xy * px;
	if((xyn.x < bl.x) || (xyn.x > tr.x)) {
		gl_FragColor = texture2D(front, xyn);
		return;
	}
	if((xyn.y < bl.y) || (xyn.y > tr.y)) {
		gl_FragColor = texture2D(front, xyn);
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

	vec4 acc = vec4(0.0);
	for(int j = 0; j < oversamples; j++) {
		for(int k = 0; k < oversamples; k++) {
			// Starting point for this sample
			xy = gl_FragCoord.xy + spacing * vec2(float(j) / (float(oversamples) + 1.0), float(k) / (float(oversamples) + 1.0));
			float dist = 0.0;
			// Walk along path by sampling vector image, moving, sampling, moving...
			for(float i = 0.0; i < sam; i++) {
				d = texture2D(adsk_results_pass1, xy * px).xy;
				xy += d * (blength/sam);
				dist += length(d * (blength/sam));
			}
			// Sample front image where our walk ended up
			acc += texture2D(front, xy * px);
			// Darken it if it came from miles away
			if(fade) {
				acc *= 1.0 - clamp(abs(dist)/maxlength, 0.0, 1.0);
			}
		}
	}
	acc /= float(oversamples * oversamples);

	gl_FragColor = acc; 
}
