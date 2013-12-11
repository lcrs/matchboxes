// Directional blur driven by gradient vectors of front input
// Pass 2: do the blur
// lewis@lewissaunders.com
// TOOD:
//  o Adaptive sampling based on length?
//  o Figure out correct calibration of length slider to pixel lengths?
//  o Triangular or gaussian window on samples?
//  o Normalize gradient vector and use another input for length control?
//    Currently, normalizing would give a super hard edge where the front
//    image is a solid colour
//  o Variable mix between the two algorithms would be neat

uniform sampler2D front, map, adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h, blength;
uniform int samples;
uniform bool radial, vectors, normalize, pathy, adsk_degrade;

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

	vec4 a = vec4(0.0);
	float sam = float(samples);
	float steps;
	bool odd = false;

	if(adsk_degrade) {
		sam /= 4.0;
	}

	if(!pathy) {
		// Do a way simpler blur along a line and get outta here
		vec2 step = d * blength / (sam - 1.0);
		for(float i = 0.0; i < sam; i++) {
			a += texture2D(front, (xy + (i - ((sam-1.0)/2.0)) * step) * px);
		}
		a /= sam;
		gl_FragColor = a;
		return;
	}

	if(mod(sam, 2.0) == 1.0) {
		odd = true;
	}
	if(odd) {
		// Odd number of samples, start with a sample from the current position
		a = texture2D(front, xy * px);
		steps = (sam - 1.0) / 2.0;
	} else {
		// Even number of samples, start with nothing
		a = vec4(0.0);
		steps = (sam / 2.0) - 1.0;
	}

	// Now accumulate along the path forwards...
	if(!odd) {
		// Even number of samples, first step is half length
		xy += 0.5 * d * blength / (sam - 1.0);
		a += texture2D(front, xy * px);
	}
	for(float i = 0.0; i < steps; i++) {
		d = texture2D(adsk_results_pass1, xy * px).xy;
		xy += d * blength / (sam - 1.0);
		a += texture2D(front, xy * px);
	}
	
	// ...and backwards
	xy = gl_FragCoord.xy;
	d = texture2D(adsk_results_pass1, xy * px).xy;
	if(!odd) {
		// Even number of samples, first step is half length
		xy -= 0.5 * d * blength / (sam - 1.0);
		a += texture2D(front, xy * px);
	}
	for(float i = 0.0; i < steps; i++) {
		xy -= d * blength / (sam - 1.0);
		a += texture2D(front, xy * px);
		d = texture2D(adsk_results_pass1, xy * px).xy;
	}

	a /= sam;
	gl_FragColor = a;
}
