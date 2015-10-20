// Recursively warp an image by motion vectors to stick it to something
// TODO:
//  o Matte passthrough doesn't work :( :(
// lewis@lewissaunders.com

uniform sampler2D front, vectors, matte, adsk_accum_texture;
uniform float adsk_result_w, adsk_result_h;
uniform bool adsk_accum_no_prev_frame;
uniform bool outputuvs;

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 uv = gl_FragCoord.xy / res;
	vec2 v = texture2D(vectors, uv).rg / res;
	vec4 o;

	if(adsk_accum_no_prev_frame) {
		if(outputuvs) {
			o.rg = uv;
			o.ba = vec2(0.0);
		} else {
			o = texture2D(front, uv);
			o.a = texture2D(matte, uv).b;
		}
	} else {
		o = texture2D(adsk_accum_texture, uv + v);
	}

	gl_FragColor = o;
}
