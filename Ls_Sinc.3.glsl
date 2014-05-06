// Sinc4 resampling
// Pass 3, vertical
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass2;
uniform float adsk_result_w, adsk_result_h, support, outputwidth;

#define pi 3.1415926535897932384626

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 xy = gl_FragCoord.xy;

	vec3 o = vec3(0.0);
	float energy = 0.0;

	float ksize = support;
	float scale = outputwidth / res.x;
	xy -= (res - (scale * res)) / 2.0;

	// Kernel must grow if we're magnifying
	if(scale > 1.0) ksize *= scale;

	// Our kernel covers -ksize to +ksize in output pixels
	// We loop over input pixels that fall under it
	for(float y = ceil((xy.y-ksize)/scale); y <= (xy.y+ksize)/scale; y+=0.1) {
		// Distance measured in output pixels
		float dist = abs(y * scale - xy.y);

		// Sinc weights
		float weight = sin(pi * dist) / (pi * dist);
		if(dist == 0.0) {
			weight = 1.0;
		}
	
		// Sample!
		o += texture2D(adsk_results_pass2, vec2(xy.x, y)/res).rgb * weight;
		energy += weight;
	}
	o.rgb /= energy;

	gl_FragColor = vec4(o, 0.0);
}

