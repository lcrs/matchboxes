// Sinc4 resampling
// lewis@lewissaunders.com

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
uniform float support;
uniform float scale;

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);

	vec3 o = vec3(0.0);
	float energy = 0.0;
	for(float i = -support; i <= support; i++) {
		for(float j = -support; j <= support; j++) {
			vec2 here = (gl_FragCoord.xy + scale * (vec2(i, j) / support)) / res;
			float dist = length(vec2(i, j));
			float weight = sin(dist) / dist;
			if(dist == 0.0) {
				weight = 1.0;
			}
			o += texture2D(front, here).rgb * weight;
			energy += weight;
		}
	}
	o /= energy;

	gl_FragColor = vec4(o, 1.0);
}
