// Adaptive sharpening
// Pass 2: vertical Gaussian blur, blend
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass2, front, strengthmap;
uniform float adsk_result_w, adsk_result_h;
uniform float sigma, strength;
uniform bool adaptive, onlyedges, showedges;
const float pi = 3.141592653589793238462643383279502884197969;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	float strength_here = strength * texture2D(strengthmap, xy * px).b;

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
	vec4 a = g.x * texture2D(adsk_results_pass2, xy * px);
	float energy = g.x;
	g.xy *= g.yz;

	// The rest
	for(int i = 1; i <= support; i++) {
		a += g.x * texture2D(adsk_results_pass2, (xy - vec2(0.0, float(i))) * px);
		a += g.x * texture2D(adsk_results_pass2, (xy + vec2(0.0, float(i))) * px);
		energy += 2.0 * g.x;
		g.xy *= g.yz;
	}
	a /= energy;
	vec4 unsharp = a;

	// Inflate edge pass a little
	float edginess = clamp(unsharp.a * 3.0, 0.0, 1.0);

	if(onlyedges) {
		edginess = 1.0 - edginess;
	}

	// Sharpen
	vec4 orig = texture2D(front, xy * px);
	vec4 sharp = orig + vec4(strength_here) * (orig - unsharp);

	if(adaptive){
		// Remove sharpening from edges
		sharp = edginess * orig + (1.0 - edginess) * sharp;
	}

	if(showedges) {
		sharp = vec4(edginess);
	}

	gl_FragColor = vec4(sharp.r, sharp.g, sharp.b, 1.0);
}
