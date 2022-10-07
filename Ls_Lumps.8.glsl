// Lumps filter vertical pass
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass2, adsk_results_pass4, adsk_results_pass7, colourt, lumpst;
uniform float adsk_result_w, adsk_result_h;
uniform float lumpsfiltersize, lumpssharpenamnt;
uniform bool recombine;
const float pi = 3.141592653589793238462643383279502884197969;

vec4 getcolour(vec2 xy) {
    if(recombine) {
        // Use node's colour input
        return texture2D(colourt, xy);
    } else {
        // Use our calculated colour band
        return texture2D(adsk_results_pass2, xy);
    }
}

vec4 getlumps(vec2 xy) {
    if(recombine) {
        // Use node's lumps input
        return texture2D(lumpst, xy);
    } else {
        // Use our calculated lumps band
        return texture2D(adsk_results_pass4, xy) - texture2D(adsk_results_pass2, xy);
    }
}

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	float sigma = lumpsfiltersize;
	int support = int(sigma * 3.0);

	// Incremental coefficient calculation setup as per GPU Gems 3
	vec3 g;
	g.x = 1.0 / (sqrt(2.0 * pi) * sigma);
	g.y = exp(-0.5 / (sigma * sigma));
	g.z = g.y * g.y;

	if(sigma == 0.0) {
		g.x = 1.0;
	}

	// Centre sample
	vec4 a = g.x * texture2D(front, xy * px);
	float energy = g.x;
	g.xy *= g.yz;

	// The rest
	for(int i = 1; i <= support; i++) {
		a += g.x * texture2D(adsk_results_pass7, (xy - vec2(0.0, float(i))) * px);
		a += g.x * texture2D(adsk_results_pass7, (xy + vec2(0.0, float(i))) * px);
		energy += 2.0 * g.x;
		g.xy *= g.yz;
	}
	a /= energy;

	vec4 filtered = a;
	vec4 lumps = getlumps(xy);
	if(lumpsfiltersize < 0.0) {
		// Sharpen rather than blur
		filtered = lumps + lumpssharpenamnt * (lumps - filtered);
	}

	gl_FragColor = filtered;
}
