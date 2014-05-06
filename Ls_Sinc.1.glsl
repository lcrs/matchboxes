// Sinc4 resampling
// Pass 1, fake front
// lewis@lewissaunders.com

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

#define pi 3.1415926535897932384626

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 xy = gl_FragCoord.xy;

	gl_FragColor = texture2D(front, xy/res);
}
