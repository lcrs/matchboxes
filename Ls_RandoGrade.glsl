// Create random grades
// lewis@lewissaunders.com
// TODO:
//  o Prevent solarization somehow?
//  o HSV, Lab, YUV curve options?
//  o Curves overlay...

uniform float adsk_result_w, adsk_result_h, adsk_time;
uniform sampler2D front, matte;
uniform int rgbpoints;
float rgbseed = float(adsk_time);
uniform float rgbamount;
float crossseed = float(adsk_time);
uniform float crossamount;
uniform float mix, lockblack, lockwhite, smoothblack, smoothwhite;

float rando(float a, float b) {
	vec2 s = vec2(a, b);
    return 2.0 * fract(sin(dot(s.xy, vec2(12.9898, 78.233))) * 43758.5453) - 1.0;
}

float curve(float x, float seed, int npoints, float amount, float lock0, float smooth0, float lock1, float smooth1) {
	// Make some random control points, each at (x,y) with slope z
	vec3 points[20];
	for(int i = 0; i < npoints; i++) {
		points[i].x = (float(i) / float(npoints)) + (amount/3.0) * (rando(float(i)+00.0, seed) - 0.5);
		points[i].y = (float(i) / float(npoints)) + (amount/1.0) * (rando(float(i)+10.0, seed) - 0.5);
		points[i].z =                         1.0 + (amount/6.0) * (rando(float(i)+20.0, seed) - 0.5);;
	}

	/* Sort them by ascending x, naive insertion sort
	   It doesn't make sense to skip this, but it makes things jump when
	   points move enough in x that they pass each other...
	for(int i = 1; i < npoints; i++) {
		int j = i - 1;
		while(j >= 0 && points[j].x > points[i].x) {
			points[j + 1] = points[j];
			j--;
		}
		points[j + 1] = points[i];
	} */

	// Lock first and last points to ends, optionally lock output at 0/1 to 0/1
	points[0].x = 0.0;
	points[0].y = mix(points[0].y, 0.0, lock0);
	points[0].z = mix(points[0].z, 0.0, smooth0);
	points[npoints-1].x = 1.0;
	points[npoints-1].y = mix(points[npoints-1].y, 1.0, lock1);
	points[npoints-1].z = mix(points[npoints-1].z, 0.0, smooth1);

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
	vec3 mattepix = texture2D(matte, coords).rgb;

	// First, random cross-transfer between channels - red from green, red from blue etc
	mat3 m = mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
	mat3 r = mat3(1.0, rando(crossseed, 1.0) - 0.5, rando(crossseed, 2.0) - 0.5,
	              rando(crossseed, 3.0) - 0.5, 1.0, rando(crossseed, 5.0) - 0.5,
	              rando(crossseed, 6.0) - 0.5, rando(crossseed, 7.0) - 0.5, 1.0);
	vec3 crossed = frontpix * (m + crossamount * r);

	// Keep white white
	crossed = mix(frontpix, crossed, length(vec3(1.0, 1.0, 1.0) - frontpix));

	// Now random curves per RGB
	vec3 rgbcurved;
	rgbcurved.r = curve(crossed.r, rgbseed+7.0, rgbpoints, rgbamount, lockblack, smoothblack, lockwhite, smoothwhite);
	rgbcurved.g = curve(crossed.g, rgbseed+8.0, rgbpoints, rgbamount, lockblack, smoothblack, lockwhite, smoothwhite);
	rgbcurved.b = curve(crossed.b, rgbseed+9.0, rgbpoints, rgbamount, lockblack, smoothblack, lockwhite, smoothwhite);

	vec3 mixed = mix(frontpix, rgbcurved, mix * length(mattepix));

	gl_FragColor = vec4(mixed, 1.0);
}
