#version 120

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
uniform int inspace, outspace;
uniform float ingamma, outgamma;
vec2 res = vec2(adsk_result_w, adsk_result_h);

vec3 rgb2xyz(vec3 rgb) {
	return mat3(0.4124, 0.2126, 0.0193, 0.3576, 0.7152, 0.1192, 0.1805, 0.0722, 0.9505) * rgb;
}

vec3 xyz2rgb(vec3 xyz) {
	return mat3(3.2406, -0.9689, 0.0557, -1.5372, 1.8758, -0.2040, -0.4986, 0.0415, 1.0570) * xyz;
}

vec3 lab2xyz(vec3 lab) {
	lab *= 100.0;
	float x1 = ((lab.r + 16.0)/116.0) + (lab.g/500.0);
	float y1 = (lab.r + 16.0)/116.0;
	float z1 = ((lab.r + 16.0)/116.0) - (lab.b/200.0);
	float bp = 6.0/29.0;
	x1 = x1 > bp ? pow(x1, 3) : 3.0 * bp*bp * (x1 - (4.0/29.0));
	y1 = y1 > bp ? pow(y1, 3) : 3.0 * bp*bp * (y1 - (4.0/29.0));
	z1 = z1 > bp ? pow(z1, 3) : 3.0 * bp*bp * (z1 - (4.0/29.0));
	return 0.01 * vec3(95.0489 * x1, 100 * y1, 108.8840 * z1);
}

vec3 xyz2lab(vec3 xyz) {
	xyz *= 100.0;
	float x1 = xyz.r/95.0489;
	float y1 = xyz.g/100.0;
	float z1 = xyz.b/108.8840;
	float bp = 6.0/29.0;
	x1 = x1 > pow(bp, 3) ? pow(x1, 1.0/3.0) : (x1/(3.0 * bp*bp)) + (4.0/29.0);
	y1 = y1 > pow(bp, 3) ? pow(y1, 1.0/3.0) : (y1/(3.0 * bp*bp)) + (4.0/29.0);
	z1 = z1 > pow(bp, 3) ? pow(z1, 1.0/3.0) : (z1/(3.0 * bp*bp)) + (4.0/29.0);
	return 0.01 * vec3(116.0 * y1 - 16.0, 500.0 * (x1 - y1), 200.0 * (y1 - z1));
}

void main(void) {
	vec3 inp = texture2D(front, gl_FragCoord.xy / res).rgb;
	if(inp.r > 0.0) inp.r = pow(inp.r, ingamma);
	if(inp.g > 0.0) inp.g = pow(inp.g, ingamma);
	if(inp.b > 0.0) inp.b = pow(inp.b, ingamma);

	vec3 xyz = vec3(0.0);
	if(inspace == 0) {
		xyz = rgb2xyz(inp);
	} else if(inspace == 1) {
		xyz = inp;
	} else if(inspace == 2) {
		xyz = lab2xyz(inp);
	}

	vec3 outp = vec3(0.0);
	if(outspace == 0) {
		outp = xyz2rgb(xyz);
	} else if(outspace == 1) {
		outp = xyz;
	} else if(outspace == 2) {
		outp = xyz2lab(xyz);
	}

	if(outp.r > 0.0) outp.r = pow(outp.r, 1.0/outgamma);
	if(outp.g > 0.0) outp.g = pow(outp.g, 1.0/outgamma);
	if(outp.b > 0.0) outp.b = pow(outp.b, 1.0/outgamma);
	gl_FragColor = vec4(outp, 0.0);
}
