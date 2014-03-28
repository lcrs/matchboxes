// Sinc4 resampling
// lewis@lewissaunders.com

uniform sampler2D front;
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
	for(float x = ceil((xy.x-ksize)/scale); x <= floor((xy.x+ksize)/scale); x++) {
		for(float y = ceil((xy.y-ksize)/scale); y <= floor((xy.y+ksize)/scale); y++) {
			// Distance measured in output pixels
			float dist = length(vec2(x,y) * scale - xy) * sc;

			// Sinc weights
			float weight = sin(pi * dist) / (pi * dist);
			if(dist < 0.0001) {
				weight = 1.0;
			}

			// Sample!
			o += texture2D(front, vec2(x,y)/(res/scale)).rgb * weight;
			energy += weight;
		}
	}
	o.rgb /= energy;

	gl_FragColor = vec4(o, 0.0);
}
