#version 120

uniform sampler2D front, strength, cleanscreen;
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
	int support = int(sizexy.x * 3.0);

	// Centre sample
    float best = texture2D(front, xy / res).g + 1.0;

	// The rest
	for(int i = 1; i <= support; i++) {
        float weight = 1.0 - (float(i)/support);
		float a = texture2D(front, (xy - vec2(float(i), 0.0)) / res).g + weight;
        if(a > best) {
            best = a;
        }
		float b = texture2D(front, (xy + vec2(float(i), 0.0)) / res).g + weight;
        if(b > best) {
            best = b;
        }
	}

    gl_FragColor = vec4(best, best, best, 0.0);
}
