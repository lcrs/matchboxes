#version 120

// Pass 4: create shadow plate and combine with blurred original

uniform sampler2D adsk_results_pass1, adsk_results_pass3;
uniform float adsk_result_w, adsk_result_h;
uniform int space, keysource, repeats;
uniform float keymin, keymax, keysmooth, gain;
uniform bool replace1, replace2, replace3, grade1, grade2, grade3;
vec2 res = vec2(adsk_result_w, adsk_result_h);

// S-shaped function with variable steepness s
// Maps 0..1 to 0..1
float smoothishstep(float x, float s) {
  if(x < 0.5) {
    return 0.5*((s*2.0*x - 2.0*x)/(2.0*s*2.0*x - s - 1.0));
  } else {
    float z = x - 0.5;
    float t = -s;
    return 0.5*((t*2.0*z - 2.0*z)/(2.0*t*2.0*z - t - 1.0)) + 0.5;
  }
}

// Colourspace conversions below are borrowed from Ls_Colourspace.glsl
#define PI 3.14159265358979

vec3 rgb2xyz(vec3 rgb) {
	// Assumes linear input with sRGB primaries and D65 reference white
	// See https://en.wikipedia.org/wiki/SRGB#From_sRGB_to_CIE_XYZ
	return mat3(0.4124, 0.2126, 0.0193, 0.3576, 0.7152, 0.1192, 0.1805, 0.0722, 0.9505) * rgb;
}

vec3 xyz2rgb(vec3 xyz) {
	// Assumes linear input with sRGB primaries and D65 reference white
	// See https://en.wikipedia.org/wiki/SRGB#From_CIE_XYZ_to_sRGB
	return mat3(3.2406, -0.9689, 0.0557, -1.5372, 1.8758, -0.2040, -0.4986, 0.0415, 1.0570) * xyz;
}

vec3 xyy2xyz(vec3 xyy) {
	// See https://en.wikipedia.org/wiki/CIE_1931_color_space#CIE_xy_chromaticity_diagram_and_the_CIE_xyY_color_space
	float x = xyy.x * xyy.b/xyy.g;
	float z = (xyy.b/xyy.g) * (1 - xyy.r - xyy.g);
	return vec3(x, xyy.b, z);
}

vec3 xyz2xyy(vec3 xyz) {
	// See https://en.wikipedia.org/wiki/CIE_1931_color_space#CIE_xy_chromaticity_diagram_and_the_CIE_xyY_color_space
	float sum = xyz.r + xyz.g + xyz.b;
	return vec3(xyz.r / sum, xyz.g / sum, xyz.g);
}

vec3 lab2xyz(vec3 lab) {
	// Our Lab is in [0,1] but typical conversion routines use [0,100]
	lab *= 100.0;

	// See https://en.wikipedia.org/wiki/CIELAB_color_space#From_CIELAB_to_CIEXYZ
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
	// Our XYZ is in [0,1] but typical conversion routines use [0,100]
	xyz *= 100.0;

	// See https://en.wikipedia.org/wiki/CIELAB_color_space#From_CIEXYZ_to_CIELAB
	float x1 = xyz.r/95.0489;
	float y1 = xyz.g/100.0;
	float z1 = xyz.b/108.8840;
	float bp = 6.0/29.0;
	x1 = x1 > pow(bp, 3) ? pow(x1, 1.0/3.0) : (x1/(3.0 * bp*bp)) + (4.0/29.0);
	y1 = y1 > pow(bp, 3) ? pow(y1, 1.0/3.0) : (y1/(3.0 * bp*bp)) + (4.0/29.0);
	z1 = z1 > pow(bp, 3) ? pow(z1, 1.0/3.0) : (z1/(3.0 * bp*bp)) + (4.0/29.0);
	return 0.01 * vec3(116.0 * y1 - 16.0, 500.0 * (x1 - y1), 200.0 * (y1 - z1));
}

vec3 lab05cc2xyz(vec3 lab05cc) {
	// a, b components centred around 0.5 instead of 0.0
	return lab2xyz(lab05cc - vec3(0, 0.5, 0.5));
}

vec3 xyz2lab05cc(vec3 xyz) {
	// a, b components centred around 0.5 instead of 0.0
	return xyz2lab(xyz) + vec3(0.0, 0.5, 0.5);
}

vec3 lchab2xyz(vec3 lchab) {
	// See https://en.wikipedia.org/wiki/CIELAB_color_space#Cylindrical_model
	float angle = lchab.b;
	angle = (angle > 0.5 ? angle - 1 : angle) * (2 * PI);
	float a = lchab.g * cos(angle);
	float b = lchab.g * sin(angle);
	return lab2xyz(vec3(lchab.r, a, b));
}

vec3 xyz2lchab(vec3 xyz) {
	// See https://en.wikipedia.org/wiki/CIELAB_color_space#Cylindrical_model
	vec3 lab = xyz2lab(xyz);
	float c = sqrt(lab.g*lab.g + lab.b*lab.b);
	float h = mod(atan(lab.b, lab.g) / (2 * PI), 1);
	return vec3(lab.r, c, h);
}

vec3 luv2xyz(vec3 luv) {
	// Find D65 reference white in XYZ by converting RGB 1,1,1
	vec3 xyzn = rgb2xyz(vec3(1.0));

	// See https://en.wikipedia.org/wiki/CIELUV#The_reverse_transformation
	float u1n = (4*xyzn.r) / (xyzn.r + 15*xyzn.g + 3*xyzn.b);
	float v1n = (9*xyzn.g) / (xyzn.r + 15*xyzn.g + 3*xyzn.b);
	float u1 = (luv.g / (13*luv.r)) + u1n;
	float v1 = (luv.b / (13*luv.r)) + v1n;
	float y = lab2xyz(luv).g;
	float x = y * ((9*u1)/(4*v1));
	float z = y * ((12 - 3*u1 - 20*v1)/(4*v1));
	return vec3(x, y, z);
}

vec3 xyz2luv(vec3 xyz) {
	// L is the same as for Lab, but our Lab is in [0,1]
	float l = 100.0 * xyz2lab(xyz).r;

	// Find D65 reference white in XYZ by converting RGB 1,1,1
	vec3 xyzn = rgb2xyz(vec3(1.0));

	// See https://en.wikipedia.org/wiki/CIELUV#The_forward_transformation
	float u1 = (4*xyz.r) / (xyz.r + 15*xyz.g + 3*xyz.b);
	float v1 = (9*xyz.g) / (xyz.r + 15*xyz.g + 3*xyz.b);
	float u1n = (4*xyzn.r) / (xyzn.r + 15*xyzn.g + 3*xyzn.b);
	float v1n = (9*xyzn.g) / (xyzn.r + 15*xyzn.g + 3*xyzn.b);
	float u = 13*l * (u1 - u1n);
	float v = 13*l * (v1 - v1n);

	// Return LUV in [0,1] rather than [0,100]
	return 0.01 * vec3(l, u, v);
}

vec3 luv05cc2xyz(vec3 luv05cc) {
	// u, v components centred around 0.5 instead of 0.0
	return luv2xyz(luv05cc - vec3(0, 0.5, 0.5));
}

vec3 xyz2luv05cc(vec3 xyz) {
	// u, v components centred around 0.5 instead of 0.0
	return xyz2luv(xyz) + vec3(0.0, 0.5, 0.5);
}

vec3 lchuv2xyz(vec3 lchuv) {
	// See https://en.wikipedia.org/wiki/CIELUV#Cylindrical_representation_(CIELCh)
	float angle = lchuv.b;
	angle = (angle > 0.5 ? angle - 1 : angle) * (2 * PI);
	float u = lchuv.g * cos(angle);
	float v = lchuv.g * sin(angle);
	return luv2xyz(vec3(lchuv.r, u, v));
}

vec3 xyz2lchuv(vec3 xyz) {
	// See https://en.wikipedia.org/wiki/CIELUV#Cylindrical_representation_(CIELCh)
	vec3 lab = xyz2luv(xyz);
	float c = sqrt(lab.g*lab.g + lab.b*lab.b);
	float h = mod(atan(lab.b, lab.g) / (2 * PI), 1);
	return vec3(lab.r, c, h);
}

vec3 oklab2xyz(vec3 oklab) {
	// See https://bottosson.github.io/posts/oklab/
	vec3 lms = mat3(1, 1, 1, 0.3963377774, -0.1055613458, -0.0894841775, 0.2158037573, -0.0638541728, -1.2914855480) * oklab;
	if(lms.r > 0.0) lms.r = pow(lms.r, 3);
	if(lms.g > 0.0) lms.g = pow(lms.g, 3);
	if(lms.b > 0.0) lms.b = pow(lms.b, 3);
	return mat3(1.2270138511, -0.0405801784, -0.0763812845, -0.5577999807, 1.1122568696, -0.4214819784, 0.2812561490, -0.0716766787, 1.5861632204) * lms;
}

vec3 xyz2oklab(vec3 xyz) {
	// See https://bottosson.github.io/posts/oklab/
	vec3 lms = mat3(0.8189330101, 0.0329845436, 0.0482003018, 0.3618667424, 0.9293118715, 0.2643662691, -0.1288597137, 0.0361456387, 0.6338517070) * xyz;
	if(lms.r > 0.0) lms.r = pow(lms.r, 1.0/3.0);
	if(lms.g > 0.0) lms.g = pow(lms.g, 1.0/3.0);
	if(lms.b > 0.0) lms.b = pow(lms.b, 1.0/3.0);
	return mat3(0.2104542553, 1.9779984951, 0.0259040371, 0.7936177850, -2.4285922050, 0.7827717662, -0.0040720468, 0.4505937099, -0.8086757660) * lms;
}

vec3 oklab05cc2xyz(vec3 oklab05cc) {
	// a, b components centred around 0.5 instead of 0.0
	return oklab2xyz(oklab05cc - vec3(0, 0.5, 0.5));
}

vec3 xyz2oklab05cc(vec3 xyz) {
	// a, b components centred around 0.5 instead of 0.0
	return xyz2oklab(xyz) + vec3(0.0, 0.5, 0.5);
}

vec3 hsv2xyz(vec3 hsv) {
	// See https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_RGB
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

	// Assume we get BT1886 display-referred video after converting from HSV
	// for consistency with other apps
	if(rgb.r > 0.0) rgb.r = pow(rgb.r, 2.4);
	if(rgb.g > 0.0) rgb.g = pow(rgb.g, 2.4);
	if(rgb.b > 0.0) rgb.b = pow(rgb.b, 2.4);
	return rgb2xyz(rgb);
}

vec3 xyz2hsv(vec3 xyz) {
	// Assume we want BT1886 display-referred video before converting to HSV
	// for consistency with other apps
	vec3 rgb = xyz2rgb(xyz);
	if(rgb.r > 0.0) rgb.r = pow(rgb.r, 1/2.4);
	if(rgb.g > 0.0) rgb.g = pow(rgb.g, 1/2.4);
	if(rgb.b > 0.0) rgb.b = pow(rgb.b, 1/2.4);

	// See https://en.wikipedia.org/wiki/HSL_and_HSV#From_RGB
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
	// See https://en.wikipedia.org/wiki/HSL_and_HSV#HSL_to_HSV
	vec3 hsv = vec3(0.0);
	hsv.r = hsl.r;
	hsv.b = hsl.b + hsl.g * min(hsl.b, 1 - hsl.b);
	hsv.g = hsv.b == 0 ? 0 : 2.0 * (1.0 - (hsl.b/hsv.b));
	return hsv2xyz(hsv);
}

vec3 xyz2hsl(vec3 xyz) {
	// See https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_HSL
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

vec3 ypbpr2xyz(vec3 ypbpr) {
	// See https://en.wikipedia.org/wiki/YCbCr#R'G'B'_to_Y'PbPr
	vec3 k = vec3(0.2126, 0.7152, 0.0722);
	vec3 rgb = mat3(1, 1, 1, 0, (-k.b/k.g) * (2 - 2*k.b), 2 - 2*k.b, 2 - 2*k.r, (-k.r/k.g)*(2-2*k.r), 0) * ypbpr;

	// Assuming display-referred BT.1886 output, rather than rec709 camera
	if(rgb.r > 0.0) rgb.r = pow(rgb.r, 2.4);
	if(rgb.g > 0.0) rgb.g = pow(rgb.g, 2.4);
	if(rgb.b > 0.0) rgb.b = pow(rgb.b, 2.4);
	return rgb2xyz(rgb);
}

vec3 xyz2ypbpr(vec3 xyz) {
	// Assuming display-referred BT.1886 input, rather than rec709 camera
	vec3 rgb = xyz2rgb(xyz);
	if(rgb.r > 0.0) rgb.r = pow(rgb.r, 1/2.4);
	if(rgb.g > 0.0) rgb.g = pow(rgb.g, 1/2.4);
	if(rgb.b > 0.0) rgb.b = pow(rgb.b, 1/2.4);

	// See https://en.wikipedia.org/wiki/YCbCr#R'G'B'_to_Y'PbPr
	vec3 k = vec3(0.2126, 0.7152, 0.0722);
	vec3 ypbpr = mat3(k.r, -0.5*k.r/(1-k.b), 0.5, k.g, -0.5*k.g/(1-k.b), -0.5*k.g/(1-k.r), k.b, 0.5, -0.5*k.b/(1-k.r)) * rgb;
	return ypbpr;
}

vec3 ycbcr2xyz(vec3 ycbcr) {
	// See https://en.wikipedia.org/wiki/YCbCr#ITU-R_BT.601_conversion
	vec3 ypbpr = (ycbcr - vec3(16.0/255.0, 128.0/255.0, 128.0/255.0)) / vec3(219.0/255.0, 224.0/255.0, 224.0/255.0);
	return ypbpr2xyz(ypbpr);
}

vec3 xyz2ycbcr(vec3 xyz) {
	// See https://en.wikipedia.org/wiki/YCbCr#ITU-R_BT.601_conversion
	vec3 ypbpr = xyz2ypbpr(xyz);
	return vec3(16.0/255.0, 128.0/255.0, 128.0/255.0) + vec3(219.0/255.0, 224.0/255.0, 224.0/255.0) * ypbpr;
}

void main(void) {
	vec3 inp = texture2D(adsk_results_pass1, gl_FragCoord.xy / res).rgb;

	// Repeat keying and grading step
	vec3 col = inp;
	float matte = 0.0;
	for(int i = 0; i < repeats; i++) {
		// Pull key
		float k = 0;
		if(keysource == 0) {
			// Key from channel 1 only
			k = col.r;
		} else if(keysource == 1) {
			// Key from channel 2 only
			k = col.g;
		} else if(keysource == 2) {
			// Key from channel 3 only
			k = col.b;
		} else if(keysource == 3) {
			// Key from average
			k = (col.r + col.g + col.b) / 3.0;
		} else if(keysource == 4) {
			// Key from luma
			k = dot(col, vec3(0.2126, 0.7152, 0.0722));
		} else if(keysource == 5) {
			// Key from max
			k = max(col.r, max(col.g, col.b));
		} else if(keysource == 6) {
			// Key from min
			k = min(col.r, min(col.g, col.b));
		}
		k = (k - keymin) / (keymax - keymin);
		k = clamp(k, 0.0, 1.0);
		k = smoothishstep(k, keysmooth);

		// Grade col with it
		if(grade1) col.r = mix(col.r, col.r * gain, k);
		if(grade2) col.g = mix(col.g, col.g * gain, k);
		if(grade3) col.b = mix(col.b, col.b * gain, k);

		// Save matte for output
		if(i == 0) matte = k;
	}

	// Replace chroma from blurred original
	vec3 blurred = texture2D(adsk_results_pass3, gl_FragCoord.xy / res).rgb;
	if(replace1) col.r = blurred.r;
	if(replace2) col.g = blurred.g;
	if(replace3) col.b = blurred.b;

	// Convert back to RGB
	vec3 xyz = vec3(0.0);
	if(space == 0) {
		xyz = rgb2xyz(col);
	} else if(space == 1) {
		xyz = col;
	} else if(space == 2) {
		xyz = xyy2xyz(col);
	} else if(space == 3) {
		xyz = lab2xyz(col);
	} else if(space == 4) {
		xyz = lab05cc2xyz(col);
	} else if(space == 5) {
		xyz = lchab2xyz(col);
	} else if(space == 6) {
		xyz = luv2xyz(col);
	} else if(space == 7) {
		xyz = luv05cc2xyz(col);
	} else if(space == 8) {
		xyz = lchuv2xyz(col);
	} else if(space == 9) {
		xyz = oklab2xyz(col);
	} else if(space == 10) {
		xyz = oklab05cc2xyz(col);
	} else if(space == 11) {
		xyz = hsv2xyz(col);
	} else if(space == 12) {
		xyz = hsl2xyz(col);
	} else if(space == 13) {
		xyz = ycbcr2xyz(col);
	} else if(space == 14) {
		xyz = ypbpr2xyz(col);
	}
	vec3 outp = xyz2rgb(xyz);

	gl_FragColor = vec4(outp, matte);
}
