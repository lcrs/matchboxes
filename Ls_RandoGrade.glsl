// Create random grade curves
// lewis@lewissaunders.com
// TODO:
//  o Lock 0 and 1, lock their slopes, slope overrides = crush shadows/highs?
//  o Prevent solarization
//  o Luma, R, G, B, crosstalk options
//  o HSV, Lab, YUV curve options

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

	// Make some random control points, each at (x,y) with slope z
	for(int i = 0; i < npoints; i++) {
		points[i].x = float(i) / float(npoints);
		points[i].y = (float(i) / float(npoints)) + 0.2 * rando(float(i)+99.0, seed);
		points[i].z = 2.0 * rando(float(i)+199.0, seed) - 1.0;
	}

	// Sort them by ascending x, naive insertion sort
	for(int i = 1; i < npoints; i++) {
		int j = i - 1;
		while(j >= 0 && points[j].x > points[i].x) {
			points[j + 1] = points[j];
			j--;
		}
		points[j + 1] = points[i];
	}

	// Evaluate spline - first find which control point indices are before and after the current point
	float x = frontpix.r;
	int i = 1;
	while(points[i].x < x && i < npoints - 1) i++;

	// See https://en.wikipedia.org/wiki/Spline_interpolation#Algorithm_to_find_the_interpolating_cubic_spline
	float x1 = points[i-1].x;
	float x2 = points[i].x;
	float y1 = points[i-1].y;
	float y2 = points[i].y;
	float k1 = points[i-1].z;
	float k2 = points[i].z;
	float t = (x - x1) / (x2 - x1);
	float a =  k1 * (x2 - x1) - (y2 - y1);
	float b =  -k2 * (x2 - x1) + (y2 - y1);
	float q = (1.0 - t) * y1 + t * y2 + t * (1.0 - t) * (a * (1.0 - t) + b * t);

	gl_FragColor = vec4(q);
}
