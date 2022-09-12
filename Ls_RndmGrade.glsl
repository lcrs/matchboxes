// Create random grades
// lewis@lewissaunders.com
// TODO:
//  o Prevent solarization somehow?
//  o HSV, Lab, YUV curve options?
//  o Make sure random numbers match between systems!

uniform float adsk_result_w, adsk_result_h, adsk_time;
uniform sampler2D front, matte;
uniform int rgbpoints;
uniform float rgbseed, rgbamount, colourfulness;
uniform float crossseed, crossamount;
uniform float mixx, lockblack, lockwhite, smoothblack, smoothwhite;
uniform bool clampnegs, overlays;

// RGB to Rec709 YPbPr
vec3 yuv(vec3 rgb) {
    return mat3(0.2215, -0.1145, 0.5016, 0.7154, -0.3855, -0.4556, 0.0721, 0.5, -0.0459) * rgb;
}

// Rec709 YPbPr to RGB
vec3 rgb(vec3 yuv) {
    return mat3(1.0, 1.0, 1.0, 0.0, -0.1870, 1.8556, 1.5701, -0.4664, 0.0) * yuv;
}

float rando(float a, float b) {
	vec2 s = vec2(a, b);
    return 2.0 * fract(sin(dot(s.xy, vec2(12.9898, 78.233))) * 43758.5453) - 1.0;
}

// Returns value of a random 1D spline curve for input x
float curve(float x, float seed, int npoints, float amount, float lock0, float smooth0, float lock1, float smooth1) {
	// Make some random control points, each at (x,y) with slope z
	vec3 points[20];
	for(int i = 0; i < 20; i++) {
		points[i].x = (float(i) / float(npoints - 1)) + (amount/3.0) * (rando(float(i)+00.0, seed) - 0.5);
		points[i].y = (float(i) / float(npoints - 1)) + (amount/1.0) * (rando(float(i)+10.0, seed) - 0.5);
		points[i].z =                         1.0 + (amount/6.0) * (rando(float(i)+20.0, seed) - 0.5);
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

// Random curves per RGB
vec3 rgbcurves(vec3 i) {
	vec3 rgbcurved;
	rgbcurved.r = curve(i.r, rgbseed+7.0, rgbpoints, rgbamount/10.0, lockblack, smoothblack, lockwhite, smoothwhite);
	rgbcurved.g = curve(i.g, rgbseed+8.0, rgbpoints, rgbamount/10.0, lockblack, smoothblack, lockwhite, smoothwhite);
	rgbcurved.b = curve(i.b, rgbseed+9.0, rgbpoints, rgbamount/10.0, lockblack, smoothblack, lockwhite, smoothwhite);

	vec3 diff = rgbcurved - i;
	float avgdiff = (diff.r + diff.g + diff.b) / 3.0;
	vec3 nocolourfulness = i + avgdiff;
	rgbcurved = mix(nocolourfulness, rgbcurved, colourfulness);

	if(clampnegs) rgbcurved = clamp(rgbcurved, 0.0, 999999.0);

	return rgbcurved;
}

// Random cross-transfer between channels - red from green, red from blue etc
vec3 rgbmatrix(vec3 i) {
	mat3 m = mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
	mat3 r = mat3(1.0, rando(crossseed, 1.0) - 0.5, rando(crossseed, 2.0) - 0.5,
	              rando(crossseed, 3.0) - 0.5, 1.0, rando(crossseed, 5.0) - 0.5,
	              rando(crossseed, 6.0) - 0.5, rando(crossseed, 7.0) - 0.5, 1.0);
	vec3 crossed = i * (m + crossamount * r);

	// Don't affect the grayscale
	vec3 desat = vec3((i.r + i.g + i.b) / 3.0);
	float sat = length(i - desat);
	return mix(i, crossed, sat);
}

// Draw RGB curves as a graph
vec3 graph(vec3 i, vec2 xy) {
	vec2 pos = xy * 4.0;
	pos.x *= adsk_result_w / adsk_result_h;
	pos -= vec2(0.1, 0.1);
	if(pos.x < -0.1 || pos.x > 1.1 || pos.y < -0.1 || pos.y > 1.1) {
		return i;
	}
	float ry = rgbcurves(vec3(pos.x)).r;
	float gy = rgbcurves(vec3(pos.x)).g;
	float by = rgbcurves(vec3(pos.x)).b;
	float rdist = abs(ry - pos.y);
	float gdist = abs(gy - pos.y);
	float bdist = abs(by - pos.y);

	// http://iquilezles.org/www/articles/distance/distance.htm
	// (sadly dFd... sometimes returns really wrong things)
	/* rdist /= min(length(vec2(dFdx(rdist), dFdy(rdist))), 0.005);
	gdist /= min(length(vec2(dFdx(gdist), dFdy(gdist))), 0.005);
	bdist /= min(length(vec2(dFdx(bdist), dFdy(bdist))), 0.005);
	*/
	rdist *= 200.0;
	gdist *= 200.0;
	bdist *= 200.0;

	float rgraph = 1.0 - smoothstep(0.0, 1.0, rdist);
	float ggraph = 1.0 - smoothstep(0.0, 1.0, gdist);
	float bgraph = 1.0 - smoothstep(0.0, 1.0, bdist);
	vec3 graph = vec3(rgraph, ggraph, bgraph);
	vec2 lines = 1.0 - smoothstep(0.0, 0.08, fract(pos*20.04));
	if(pos.x > -0.1 && pos.x < 1.1 && pos.y > -0.1 && pos.y < 1.1) {
		graph += 0.15 * length(lines);
	}
	return mix(i, graph, 0.85);
}

// Draw vectorscope-type thing
vec3 hues(vec3 i, vec2 xy) {
	vec2 pos = xy * 4.0;
	pos.x *= adsk_result_w / adsk_result_h;
	pos -= vec2(0.1, 0.1);
	pos.x -= 1.2;
	if(pos.x < -0.1 || pos.x > 1.1 || pos.y < -0.1 || pos.y > 1.1) {
		return i;
	}
	vec3 graph = vec3(0.0);
	vec3 cols[7];
	cols[0] = vec3(1.0, 0.0, 0.0);
	cols[1] = vec3(0.0, 1.0, 0.0);
	cols[2] = vec3(0.0, 0.0, 1.0);
	cols[3] = vec3(0.0, 1.0, 1.0);
	cols[4] = vec3(1.0, 0.0, 1.0);
	cols[5] = vec3(1.0, 1.0, 0.0);
	cols[6] = vec3(0.5, 0.5, 0.5);
	for(int i = 0; i < 7; i++) {
		vec3 from = cols[i];
		vec3 to = rgbmatrix(from);
		if(i == 6) to = rgbcurves(from);
		vec2 fromcoords = yuv(from).gb / 2.0 + 0.5;
		vec2 tocoords = yuv(to).gb / 2.0 + 0.5;
		float fromring = 1.0 - smoothstep(0.0, 0.0055, abs(0.03 - length(pos - fromcoords)));
		float tocircle = 1.0 - smoothstep(0.02, 0.022, length(pos - tocoords));
		graph += 0.5 * fromring * from + 0.75 * tocircle * to;
	}

	float circle = smoothstep(0.995, 1.0, 1.0 - abs(0.5 - length(pos - vec2(0.5, 0.5))));
	float lines = length(1.0 - smoothstep(0.0, 0.016, fract(pos*2.01)));
	if((pos.x > 0.48 && pos.x < 0.52) || (pos.y > 0.48 && pos.y < 0.52)) {
		lines += length(1.0 - smoothstep(0.0, 0.1, fract(pos*20.08)));
	}
	if(length(pos - vec2(0.5, 0.5)) > 0.5) lines = 0.0;
	graph += 0.15 * max(lines, circle);
	return mix(i, graph, 0.85);
}

void main() {
	vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
	vec3 frontpix = texture2D(front, coords).rgb;
	vec3 mattepix = texture2D(matte, coords).rgb;

	vec3 crossed = rgbmatrix(frontpix);
	vec3 rgbcurved = rgbcurves(crossed);
	vec3 mixed = mix(frontpix, rgbcurved, mixx * length(mattepix));

	if(overlays) {
		mixed = graph(mixed, coords);
		mixed = hues(mixed, coords);
	}

	gl_FragColor = vec4(mixed, 1.0);
}
