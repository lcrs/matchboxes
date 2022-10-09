// Colour filter horizontal pass
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass2, colourt;
uniform float adsk_result_w, adsk_result_h;
uniform float colourfiltersize;
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
	vec4 a = g.x * getcolour(xy * px);
	float energy = g.x;
	g.xy *= g.yz;

	// The rest
	for(int i = 1; i <= support; i++) {
		a += g.x * getcolour((xy - vec2(float(i), 0.0)) * px);
		a += g.x * getcolour((xy + vec2(float(i), 0.0)) * px);
		energy += 2.0 * g.x;
		g.xy *= g.yz;
	}
	a /= energy;

	gl_FragColor = a;
}
