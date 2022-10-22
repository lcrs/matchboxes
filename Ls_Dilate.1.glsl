#version 120

// Morphological dilate/erode using non-flat structuring elements
//  (see https://www.mathworks.com/help/images/structuring-elements.html)

uniform sampler2D front, strength, cleanscreen;
uniform float size, stretch;
uniform int kernel;
uniform bool usecolour, usecleanscreen;
uniform vec3 screencolour;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);

void main(void) {
	vec2 xy = gl_FragCoord.xy;
	vec2 sizexy = mix(vec2(2.0, 0.0), vec2(0.0, 2.0), stretch) * texture2D(strength, xy / res).b * size;
	vec3 screencol = usecleanscreen ? texture2D(cleanscreen, xy / res).rgb : screencolour;

	// Centre sample
	vec3 best = texture2D(front, xy / res).rgb + sign(sizexy.x) * vec3(1.0);
	if(usecolour) {
		// Ignore weighting if using colour
		best -= sign(sizexy.x) * vec3(1.0);
	}
	float bestdist = distance(best, screencol);

	// The rest
	int support = int(abs(sizexy.x) * 3.0);
	for(int i = 1; i <= support; i++) {
		float weight = 0.0;
		float x = float(i) / abs(sizexy.x);
		if(kernel == 0) {
			// Box
			weight = x < 1.0 ? 1.0 : 0.0;
		} else if(kernel == 1) {
			// Box AA
			if(x < 1.0) {
				weight = 1.0;
			} else if(x < 1.0 + (1.0 / abs(sizexy.x))) {
				weight = 1.0 - ((x - 1.0) / (1.0 / abs(sizexy.x)));
			} else {
				weight = 0.0;
			}
		} else if(kernel == 2) {
			// Triangle
			weight = 1.0 - clamp(x, 0.0, 1.0);
		} else if(kernel == 3) {
			// Ball
			weight = sqrt(1 - pow(clamp(x, 0.0, 1.0), 2));
		} else if(kernel == 4) {
			// Gaussian
			weight = exp(-0.5 * pow(x, 2));
		}
		// Add weights to pixel values before comparison
		vec3 a = texture2D(front, (xy - vec2(float(i), 0.0)) / res).rgb + sign(sizexy.x) * vec3(weight);
		vec3 b = texture2D(front, (xy + vec2(float(i), 0.0)) / res).rgb + sign(sizexy.x) * vec3(weight);
		if(usecolour) {
			// Ignore outer parts of support to match non-colour mode box kernel size
			if(x > 1.0) break;

			// Ignore weighting if using colour
			a -= sign(sizexy.x) * vec3(weight);
			b -= sign(sizexy.x) * vec3(weight);
			float adist = distance(a, screencol);
			float bdist = distance(b, screencol);
			if(sizexy.x > 0.0) {
				if(adist < bestdist) {
					best = a;
					bestdist = adist;
				}
				if(bdist < bestdist) {
					best = b;
					bestdist = bdist;
				}
			} else {
				if(adist > bestdist) {
					best = a;
					bestdist = adist;
				}
				if(bdist > bestdist) {
					best = b;
					bestdist = bdist;
				}
			}
		} else {
			if(sizexy.x > 0.0) {
				best = max(best, a);
				best = max(best, b);
			} else {
				best = min(best, a);
				best = min(best, b);
			}
		}
	}

	gl_FragColor = vec4(best.r, best.g, best.b, 0.0);
}
