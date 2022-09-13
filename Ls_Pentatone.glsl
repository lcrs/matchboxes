// Pentatone
// Move colours towards 2, 3, 4 or 5 target colours
// lewis@lewissaunders.com

uniform sampler2D front, matte;
uniform float adsk_result_w, adsk_result_h;
uniform vec3 target1, target2, target3, target4, target5;
uniform float s, t;

vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 xy = gl_FragCoord.xy / res;

void main() {
	vec3 rgb = texture2D(front, xy).rgb;
	float matte = texture2D(matte, xy).b;

	vec3 force1 = t * (target1 - rgb) * (1.0 - smoothstep(0.0, s, length(target1 - rgb)));
	/*vec3 to2 = normalize(target2 - rgb) * s * length(target2 - rgb);
	vec3 to3 = normalize(target3 - rgb) * s * length(target3 - rgb);
	vec3 to4 = normalize(target4 - rgb) * s * length(target4 - rgb);
	vec3 to5 = normalize(target5 - rgb) * s * length(target5 - rgb);*/

	rgb += force1;

	gl_FragColor = vec4(rgb, 1.0);
}
