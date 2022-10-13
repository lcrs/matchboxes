#version 120

uniform sampler2D adsk_results_pass1, strength, cleanscreen;
uniform float size, ratio;
uniform int kernel;
uniform bool usecolour, usecleanscreen;
uniform vec3 screencolour;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
const float pi = 3.141592653589793238462643383279502884197969;

void main(void) {
    vec2 xy = gl_FragCoord.xy;
    vec2 sizexy = vec2(ratio, 1.0/ratio) * texture2D(strength, xy).b * size;
	int support = int(sizexy.y * 3.0);

	// Centre sample
    float best = texture2D(adsk_results_pass1, xy / res).g + 1.0;

	// The rest
	for(int i = 1; i <= support; i++) {
        float weight = 1.0 - (float(i)/support);
		float a = texture2D(adsk_results_pass1, (xy - vec2(0.0, float(i))) / res).g + weight;
        if(a > best) {
            best = a;
        }
		float b = texture2D(adsk_results_pass1, (xy + vec2(0.0, float(i))) / res).g + weight;
        if(b > best) {
            best = b;
        }
	}

    best -= 2.0;

    gl_FragColor = vec4(best, best, best, 0.0);
}
