// Create random grade curves
// lewis@lewissaunders.com
// TODO:
//  o everything

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D front;
uniform float seed;
uniform int npoints;

vec3 points[20];

float rando(float a, float b) {
	vec2 s = vec2(a, b);
    return 2.0 * fract(sin(dot(s.xy, vec2(12.9898, 78.233))) * 43758.5453) - 1.0;
}

void main() {
	vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
	vec3 frontpix = texture2D(front, coords).rgb;

	// Make random control points at x,y with derivative z
	for(int i = 0; i < npoints; i++) {
		//points[i].x = rando(float(i), seed);
		points[i].y = (float(i) / float(npoints)) + 0.2 * rando(float(i)+99.0, seed);
		points[i].z = 2.0 * rando(float(i)+199.0, seed) - 1.0;

		points[i].x = float(i) / float(npoints);
		//points[i].y = (float(i) / float(npoints)) * (float(i) / float(npoints));
		//points[i].z = 1.0;
	}

	// Sort them by x
	/*for (int j = 1; j < npoints; j++) {
		int i = j - 1;
		while(i >= 0 && points[i].x > points[j].x) {
			points[i + 1] = points[i];
			i--;
		}
		points[i + 1] = points[j];
	}*/

	// Evaluate spline
	float x = frontpix.r;
	int i = 1;
	while(points[i].x < x && i < npoints - 1) i++;
	float t = (x - points[i-1].x) / (points[i].x - points[i-1].x);
	float a =   points[i-1].z * (points[i].x - points[i-1].x) - (points[i].y - points[i-1].y);
	float b =  -points[i].z   * (points[i].x - points[i-1].x) + (points[i].y - points[i-1].y);
	float f = (1.0 - t) * points[i-1].y + t * points[i].y + t * (1.0 - t) * (a * (1.0 - t) + b * t);

	gl_FragColor = vec4(f);
}
