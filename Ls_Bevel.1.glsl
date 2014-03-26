// Bevel
// Pass 1: Dummy pass for front passthrough
// lewis@lewissaunders.com

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	gl_FragColor = texture2D(front, xy * px);
}
