// Recursively warp an image by motion vectors to stick it to something
// lewis@lewissaunders.com
// Pass 1: recursively distort image or UV map by the motion vectors

uniform sampler2D front, matte, vectors, adsk_accum_texture;
uniform float adsk_result_w, adsk_result_h;
uniform bool adsk_accum_no_prev_frame;
uniform bool accumulateUVs;

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 uv = gl_FragCoord.xy / res;
	vec2 v = texture2D(vectors, uv).rg / res;
	vec4 o;

	if(adsk_accum_no_prev_frame) {
		// We're at the first frame, about to start accumulating
		if(accumulateUVs) {
			// Start out with an identity UV map
			o.rg = uv;
			o.ba = vec2(0.0);
		} else {
			// Start out with the first frame of the front/matte
			o.rgb = texture2D(front, uv).rgb;
			o.a = texture2D(matte, uv).b;
		}
	} else {
		// We are mid-accumulation
		// Take the previous output frame, offseting each sample
		// by the vectors for this frame
		o = texture2D(adsk_accum_texture, uv + v);
	}

	gl_FragColor = o;
}
