// Transforms the area inside the nail matte by the difference between two tracks
// Use to stick down floating CG, by nailing from a track on the CG to a track on the BG
// lewis@lewissaunders.com
// TODO:
//  o Overlay to show track positions and matte area
//  o Rotate, scale, shear?
//  o Better filtering probably.  Not sure if EWA would work because no dFdx?

uniform sampler2D front, matte, nailmatte;
uniform float adsk_result_w, adsk_result_h;
uniform vec2 trackfrom, trackto, offset;
uniform float extra, amount, edgeswoop;
uniform bool tracksarepixels, matteistarget, ewa;

void main() {
	vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);

	vec2 diff = trackto - trackfrom + offset;
	diff *= extra;
	diff *= amount;

	if(tracksarepixels) {
		diff /= vec2(adsk_result_w, adsk_result_h);
	}

	float coeff = 0.0;
	if(matteistarget) {
		coeff = texture2D(nailmatte, coords).b;
	} else {
		coeff = texture2D(nailmatte, coords - diff).b;
	}
	coeff = mix(coeff, smoothstep(0.0, 1.0, coeff), edgeswoop);
	diff *= coeff;

	vec2 q = coords - diff;

	vec3 o = texture2D(front, q).rgb;
	float m = texture2D(matte, q).b;

	gl_FragColor = vec4(o, m);
}
