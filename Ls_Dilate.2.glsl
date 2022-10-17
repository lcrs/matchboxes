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
    vec3 best = texture2D(adsk_results_pass1, xy / res).rgb + vec3(1.0);

	// The rest
    for(int i = 1; i <= support; i++) {
        float weight = 0.0;
        float x = float(i) / sizexy.y;
        if(kernel == 0) {
            // Box
            weight = x < 1.0 ? 1.0 : 0.0;
        } else if(kernel == 1) {
            // Box AA
            if(x < 1.0) {
                weight = 1.0;
            } else if(x < 1.0 + (1.0 / sizexy.y)) {
                weight = 1.0 - ((x - 1.0) / (1.0 / sizexy.y));
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
        vec3 a = texture2D(adsk_results_pass1, (xy - vec2(0.0, float(i))) / res).rgb + vec3(weight);
        best = max(best, a);
        vec3 b = texture2D(adsk_results_pass1, (xy + vec2(0.0, float(i))) / res).rgb + vec3(weight);
        best = max(best, b);
    }

    best -= vec3(2.0);

    gl_FragColor = vec4(best.r, best.g, best.b, 0.0);
}
