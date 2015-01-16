// Lumps passthrough for later
// lewis@lewissaunders.com

uniform sampler2D lumpst;
uniform float adsk_result_w, adsk_result_h;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);
	gl_FragColor = texture2D(lumpst, xy * px);
}
