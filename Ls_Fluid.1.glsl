// Pass 1: advect the vectors by themselves
// lewis@lewissaunders.com

uniform sampler2D start, adsk_accum_texture;
uniform float adsk_result_w, adsk_result_h, blength, spacing, maxlength, sidestep;
uniform vec2 offset;
uniform int samples, oversamples;
uniform vec2 bl, tr;
uniform bool radial, normalize, adsk_degrade, adsk_accum_no_prev_frame;

vec2 get(vec2 uv) {
	if(adsk_accum_no_prev_frame){
		return texture2D(start, uv).xy;
	} else {
		return texture2D(adsk_accum_texture, uv).xy;
	}
}

void main() {
	vec2 xy = gl_FragCoord.xy;

	// Factor to convert pixels to [0,1] texture coords
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	vec2 d = get(xy * px);
	
	float sam = float(samples);
	if(adsk_degrade) {
		sam /= 4.0;
	}

	vec3 acc = vec3(0.0);
	for(int j = 0; j < oversamples; j++) {
		for(int k = 0; k < oversamples; k++) {
			// Starting point for this sample
			xy = gl_FragCoord.xy + spacing * vec2(float(j) / (float(oversamples) + 1.0), float(k) / (float(oversamples) + 1.0));
			float dist = 0.0;
			// Walk along path by sampling vector image, moving, sampling, moving...
			for(float i = 0.0; i < sam; i++) {
				d = get(xy * px);
				if(length(d) == 0.0) {
					// No gradient at this point in the map, early out
					break;
				}
				xy += d * (blength/sam) + blength * sidestep/1000.0 * vec2(-d.y, d.x) + (blength/32.0) * offset;
			}
			// Sample front image where our walk ended up
			acc.rg += get(xy * px);

			// Diffusion?
			/*for(float ix = 0.0; ix < diffusion; ix++) {
				for(float iy = 0.0; iy < diffusion; iy++) {
					acc.rgb += texture2D(front, (xy + vec2(ix, iy) * dist * px)).rgb * length(vec2(ix, iy)-vec2(diffusion/2.0, diffusion/2.0)) / (diffusion * diffusion * 32.0);
				}
			}*/
		}
	}
	acc /= float(oversamples * oversamples);

	gl_FragColor = vec4(acc, 0.0);
}
