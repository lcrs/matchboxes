// Pass 1: advect the vectors by themselves
// lewis@lewissaunders.com

uniform sampler2D vecs, adsk_accum_texture;
uniform float adsk_result_w, adsk_result_h, velocity, spacing, sidestep;
uniform vec2 offset;
uniform int samples, oversamples;
uniform bool adsk_accum_no_prev_frame;

vec4 get(vec2 uv) {
	if(adsk_accum_no_prev_frame) {
		// First frame is input vectors in rg, UV map in ba
		return vec4(texture2D(vecs, uv).rg, uv);
	} else {
		return texture2D(adsk_accum_texture, uv);
	}
}

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h); // Factor to convert pixels to [0,1] texture coords

	float sam = float(samples);
	vec4 acc = vec4(0.0);
	vec2 v;
	for(int j = 0; j < oversamples; j++) {
		for(int k = 0; k < oversamples; k++) {
			// Starting point for this sample
			xy = gl_FragCoord.xy + spacing * vec2(float(j) / (float(oversamples) + 1.0), float(k) / (float(oversamples) + 1.0));
			// Walk along path by sampling vector image, moving, sampling, moving...
			for(float i = 0.0; i < sam; i++) {
				v = get(xy * px).rg;
				if(length(v) == 0.0) {
					// No gradient at this point in the map, early out
					break;
				}
				xy -= v * (velocity/sam) + sidestep/100.0 * vec2(-v.y, v.x) + offset;
			}
			// Sample front image where our walk ended up
			acc += get(xy * px);

		}
	}
	acc /= float(oversamples * oversamples);

	gl_FragColor = acc;
}
