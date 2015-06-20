// Create random grade curves
// lewis@lewissaunders.com
// TODO:
//  o Lock 0 and 1, lock their slopes, slope overrides = crush shadows/highs?
//  o Prevent solarization
//  o Luma, R, G, B, crosstalk options
//  o HSV, Lab, YUV curve options
//  o Mix control, matte input

uniform float adsk_result_w, adsk_result_h, adsk_time;
uniform sampler2D front;
float rgbseed = float(adsk_time);
uniform int rgbpoints;

float rando(float a, float b) {
	vec2 s = vec2(a, b);
    return 2.0 * fract(sin(dot(s.xy, vec2(12.9898, 78.233))) * 43758.5453) - 1.0;
}

float curve(float x, float seed, int npoints) {
	// Make some random control points, each at (x,y) with slope z
	vec3 points[20];
	for(int i = 0; i < npoints; i++) {
		points[i].x = float(i) / float(npoints);
		points[i].y = (float(i) / float(npoints)) + 0.1 * (rando(float(i), seed) - 0.5);
		points[i].z = 1.0;
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

	// Lock first and last points to ends
	points[0] = vec3(0.0, 0.0, 0.0);
	points[npoints-1] = vec3(1.0, 1.0, 0.0);

	// Evaluate spline - first find the control points before and after the input in x
	int i = 1;
	while(points[i].x < x && i < npoints - 1) i++;
	float x1 = points[i - 1].x;
	float x2 = points[i].x;
	float y1 = points[i - 1].y;
	float y2 = points[i].y;
	float k1 = points[i - 1].z;
	float k2 = points[i].z;

	// https://en.wikipedia.org/wiki/Spline_interpolation#Algorithm_to_find_the_interpolating_cubic_spline
	float t = (x - x1) / (x2 - x1);
	float a =  k1 * (x2 - x1) - (y2 - y1);
	float b =  -k2 * (x2 - x1) + (y2 - y1);
	float q = (1.0 - t) * y1 + t * y2 + t * (1.0 - t) * (a * (1.0 - t) + b * t);
	return q;
}

void main() {
	vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
	vec3 frontpix = texture2D(front, coords).rgb;

	vec3 rgbcurved;
	rgbcurved.r = curve(frontpix.r, rgbseed, rgbpoints);
	rgbcurved.g = curve(frontpix.g, rgbseed+1.0, rgbpoints);
	rgbcurved.b = curve(frontpix.b, rgbseed+2.0, rgbpoints);

	gl_FragColor = vec4(rgbcurved, 1.0);
}
