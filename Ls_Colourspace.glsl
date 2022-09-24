#version 120

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
uniform int inspace, outspace;
uniform float ingamma, outgamma;
vec2 res = vec2(adsk_result_w, adsk_result_h);

// Everything below uses illuminant D65, and RGB refers to linear light with sRGB primaries

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

vec3 lchab2xyz(vec3 lchab) {
	
}

vec3 xyz2lchab(vec3 xyz) {
	
}

vec3 hsv2xyz(vec3 hsv) {
	float c = hsv.b * hsv.g;
	float h1 = hsv.r / (60.0/360.0);
	float x = c * (1 - abs(mod(h1, 2) - 1));
	vec3 rgb = vec3(0);
	if(h1 < 1) {
		rgb = vec3(c, x, 0);
	} else if(h1 < 2) {
		rgb = vec3(x, c, 0);
	} else if(h1 < 3) {
		rgb = vec3(0, c, x);
	} else if(h1 < 4) {
		rgb = vec3(0, x, c);
	} else if(h1 < 5) {
		rgb = vec3(x, 0, c);
	} else if(h1 < 6) {
		rgb = vec3(c, 0, x);
	}
	float m = hsv.b - c;
	rgb += vec3(m);
	return rgb2xyz(rgb);
}

vec3 xyz2hsv(vec3 xyz) {
	vec3 rgb = xyz2rgb(xyz);
	float v = max(max(rgb.r, rgb.g), rgb.b);
	float xmin = min(min(rgb.r, rgb.g), rgb.b);
	float c = v - xmin;
	float h = 0;
	if(c == 0) {
		h = 0;
	} else if(v == rgb.r) {
		h = (60.0/360.0) * (0 + ((rgb.g - rgb.b)/c));
	} else if(v == rgb.g) {
		h = (60.0/360.0) * (2 + ((rgb.b - rgb.r)/c));
	} else if(v == rgb.b) {
		h = (60.0/360.0) * (4 + ((rgb.r - rgb.g)/c));
	}
	if(h < 0.0) h += 1.0;
	float s = v == 0 ? 0 : c/v;
	return vec3(h, s, v);
}

vec3 hsl2xyz(vec3 hsl) {
	vec3 hsv = vec3(0.0);
	hsv.r = hsl.r;
	hsv.b = hsl.b + hsl.g * min(hsl.b, 1 - hsl.b);
	hsv.g = hsv.b == 0 ? 0 : 2.0 * (1.0 - (hsl.b/hsv.b));
	return hsv2xyz(hsv);
}

vec3 xyz2hsl(vec3 xyz) {
	vec3 hsv = xyz2hsv(xyz);
	vec3 hsl = vec3(0.0);
	hsl.r = hsv.r;
	hsl.b = hsv.b * (1.0 - (hsv.g/2.0));
	if(hsl.b == 0 || hsl.b == 1) {
		hsl.g = 0;
	} else {
		hsl.g = (hsv.b - hsl.b) / (min(hsl.b, 1 - hsl.b));
	}
	return hsl;
}

void main(void) {
	vec3 inp = texture2D(front, gl_FragCoord.xy / res).rgb;
	if(inp.r > 0.0) inp.r = pow(inp.r, ingamma);
	if(inp.g > 0.0) inp.g = pow(inp.g, ingamma);
	if(inp.b > 0.0) inp.b = pow(inp.b, ingamma);

	// First convert from input space to XYZ
	vec3 xyz = vec3(0.0);
	if(inspace == 0) {
		xyz = rgb2xyz(inp);
	} else if(inspace == 1) {
		xyz = inp;
	} else if(inspace == 2) {
		xyz = lab2xyz(inp);
	} else if(inspace == 3) {
		xyz = lchab2xyz(inp);
	} else if(inspace == 4) {
		xyz = hsv2xyz(inp);
	} else if(inspace == 5) {
		xyz = hsl2xyz(inp);
	}

	// Then convert from XYZ to output space
	vec3 outp = vec3(0.0);
	if(outspace == 0) {
		outp = xyz2rgb(xyz);
	} else if(outspace == 1) {
		outp = xyz;
	} else if(outspace == 2) {
		outp = xyz2lab(xyz);
	} else if(outspace == 3) {
		outp = xyz2lchab(xyz);
	} else if(outspace == 4) {
		outp = xyz2hsv(xyz);
	} else if(outspace == 5) {
		outp = xyz2hsl(xyz);
	}


	if(outp.r > 0.0) outp.r = pow(outp.r, 1.0/outgamma);
	if(outp.g > 0.0) outp.g = pow(outp.g, 1.0/outgamma);
	if(outp.b > 0.0) outp.b = pow(outp.b, 1.0/outgamma);
	gl_FragColor = vec4(outp, 0.0);
}
