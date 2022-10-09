// Colour filter vertical pass
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass2, adsk_results_pass5, colourt;
uniform float adsk_result_w, adsk_result_h;
uniform float colourfiltersize, coloursharpenamnt;
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

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	float sigma = abs(colourfiltersize);
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
	vec4 a = g.x * texture2D(adsk_results_pass5, xy * px);
	float energy = g.x;
	g.xy *= g.yz;

	// The rest
	for(int i = 1; i <= support; i++) {
		a += g.x * texture2D(adsk_results_pass5, (xy - vec2(0.0, float(i))) * px);
		a += g.x * texture2D(adsk_results_pass5, (xy + vec2(0.0, float(i))) * px);
		energy += 2.0 * g.x;
		g.xy *= g.yz;
	}
	a /= energy;

	vec4 filtered = a;
	vec4 colour = getcolour(xy * px);
	if(colourfiltersize < 0.0) {
		// Sharpen rather than blur
		filtered = colour + coloursharpenamnt * (colour - filtered);
	}

	gl_FragColor = filtered;
}
