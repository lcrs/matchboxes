// Sinc4 resampling
// Pass 2, vertical
// lewis@lewissaunders.com

uniform sampler2D adsk_result_pass1;
uniform float adsk_result_w, adsk_result_h, support, inputwidth, sc;

#define pi 3.1415926535897932384626

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 xy = gl_FragCoord.xy;

	vec3 o = vec3(0.0);
	float energy = 0.0;

	float ksize = support;
	float scale = res.x / inputwidth;

	// Kernel must grow if we're magnifying
	if(scale > 1.0) ksize *= scale;

	// We loop over the input image pixels under our
	// kernel, which covers -ksize to +ksize in output pixels
	for(float y = ceil((xy.y-ksize)/scale); y <= floor((xy.y+ksize)/scale); y++) {
		// Distance measured in output pixels
		float dist = (y * scale - xy.y) * sc;

		// Sinc weights
		float weight = sin(pi * dist) / (pi * dist);
		if(dist == 0.0) {
			weight = 1.0;
		}

		// Sample!
		o += texture2D(adsk_result_pass1, vec2(xy.x,y)/vec2(res.x, res.y/scale)).rgb * weight;
		energy += weight;
	}
	o.rgb /= energy;

	gl_FragColor = vec4(o, 0.0);
}
