// Blur only similar pixels
// Pass 2: horizontal blur
// lewis@lewissaunders.com

uniform sampler2D front, strength;
uniform float adsk_result_w, adsk_result_h;
uniform float sigma, threshold;
uniform bool slow;
uniform int quality;
const float pi = 3.141592653589793238462643383279502884197969;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	float strength_here = texture2D(strength, xy * px).b;
	float sigma_here = sigma * strength_here;

	int support = int(sigma_here * 3.0);

	float kernelhyp = length(vec2(support, support));
	float rgbhyp = length(vec3(1.0, 1.0, 1.0));

	if(slow) {
		// Use straightforward but slow algorithm
		vec4 centre = texture2D(front, xy * px);

		vec4 a = vec4(0.0);
		float energy = 0.0;

		float inc = pow(2.0, 3.0 - float(quality));

		// Factor to make apparant sharpness of two algorithms similar
		float m = 1.666;

		// Yes, this is brute force and dirty
		// Making bilateral filtering separable is really hard
		// c.f. any number of SIGGRAPH papers
		for(float x = -sigma_here * m; x <= sigma_here * m; x += inc) {
			for(float y = -sigma_here * m; y <= sigma_here * m; y += inc) {
				vec4 b = texture2D(front, (xy + vec2(x, y)) * px);
				b.a = 1.0;

				// Mult this sample by colour similarity
				float fac = 1.0 - (length(b - centre) / rgbhyp);
				fac = pow(fac, threshold);
				b *= clamp(fac, 0.001, 1.0);

				// Mult this sample by distance from centre, i.e. triangular kernel
				b *= kernelhyp - length(vec2(x, y));

				// Accumulate
				a += b;
				energy += b.a;
			}
		}

		if(energy < 0.05) {
			// No samples were taken!
			gl_FragColor = texture2D(front, xy * px);
			return;
		}

		a /= energy;
		gl_FragColor = a;
		return;
	}

	// Okay.  On to complicated two-pass algorithm
	// Incremental coefficient calculation setup as per GPU Gems 3
	vec3 g;
	g.x = 1.0 / (sqrt(2.0 * pi) * sigma_here);
	g.y = exp(-0.5 / (sigma_here * sigma_here));
	g.z = g.y * g.y;

	if(sigma_here == 0.0) {
		g.x = 1.0;
	}

	vec4 a, b, c;
	a = vec4(0.0);
	float fac, energy = 0.0;

	// Centre sample
	vec4 orig = texture2D(front, xy * px);
	a += g.x * orig;
	energy += g.x;
	g.xy *= g.yz;

	int inc = int(pow(2.0, 3.0 - float(quality)));

	// The rest
	for(int i = 1; i <= support; i += inc) {
		b = texture2D(front, (xy - vec2(float(i), 0.0)) * px);
		c = texture2D(front, (xy + vec2(float(i), 0.0)) * px);

		b.a = 1.0;
		c.a = 1.0;

		fac = 1.0 - (length(b - orig) / rgbhyp);
		fac = pow(fac, threshold);
		b *= g.x * clamp(fac, 0.001, 1.0);
		a += b;
		energy += b.a;

		fac = 1.0 - (length(c - orig) / rgbhyp);
		fac = pow(fac, threshold);
		c *= g.x * clamp(fac, 0.001, 1.0);
		a += c;
		energy += c.a;

		g.xy *= g.yz;
	}
	a /= energy;

	gl_FragColor = a;
}
