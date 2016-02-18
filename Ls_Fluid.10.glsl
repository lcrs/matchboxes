// Pass 10
// Create output image from accumulated vectors and image input
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass9, img;
uniform float adsk_result_w, adsk_result_h;
uniform int rgbout, matteout;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);
	vec3 rgb = vec3(0.0);
	float matte = 0.0;

	vec2 vecs = texture2D(adsk_results_pass9, xy * px).rg;
	vec2 uvs = texture2D(adsk_results_pass9, xy * px).ba;

	if(rgbout == 0) {
		rgb.rg = vecs;
	} else if(rgbout == 1) {
		rgb.rg = uvs;
	} else if(rgbout == 2) {
		rgb = texture2D(img, uvs).rgb;
	} else if(rgbout == 3) {
		rgb = vec3(length(vecs));
	}

	matte = length(vecs);

	gl_FragColor = vec4(rgb, matte);
}
