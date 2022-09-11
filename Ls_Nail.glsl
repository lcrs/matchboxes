// Transforms the area inside the nail matte by the difference between two tracks
// Use to stick down floating CG, by nailing from a track on the CG to a track on the BG
// lewis@lewissaunders.com
// TODO:
//  o Anti-aliased overlay
//  o Rotate, scale, shear?
//  o Better filtering probably.  Not sure if EWA would work because no dFdx?

uniform sampler2D front, matte, nailmatte;
uniform float adsk_result_w, adsk_result_h;
uniform vec2 trackfrom, trackto, offset;
uniform float extra, amount, edgeswoop;
uniform bool manualtracks, matteistarget, overlay;
uniform vec3 areatint;

float distanceToSegment(vec2 p0, vec2 p1, vec2 p) {
	vec2 v = p1 - p0;
	vec2 w = p - p0;
	float c1 = dot(w, v);
	float c2 = dot(v, v);

	if(c1 <= 0.0)
		return length(p0 - p);
	if(c2 <= c1)
		return length(p1 - p);

	float b = c1 / c2;
	vec2 pb = p0 + b * v;
	return length(pb - p);
}

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 coords = gl_FragCoord.xy / res;

	vec2 diff = trackto - trackfrom + offset;
	diff *= extra;
	diff *= amount;

	if(!manualtracks) {
		diff /= res;
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

	if(overlay) {
		vec2 trackfromp = trackfrom;
		vec2 tracktop = trackto;
		vec2 offsetp = offset;
		vec2 coordsp = coords * res;

		if(manualtracks) {
			trackfromp *= res;
			tracktop *= res;
			offsetp *= res;
		}

		if(length(coordsp - trackfromp) < 5.0)
			o = vec3(0.8, 0.2, 0.2);

		if(length(coordsp - tracktop) < 5.0)
			o = vec3(0.2, 0.8, 0.2);

		if(length(offsetp) > 0.0) {
			if(length(coordsp - (tracktop + offsetp)) < 5.0) {
				o = vec3(0.2, 0.2, 0.8);
			}
		}

		if(distanceToSegment(trackfromp, tracktop + offsetp, coordsp) < 1.0) {
			if(mod(length(trackfromp - coordsp), 8.0) < 4.0) {
				o = vec3(0.4, 0.4, 0.8);
			}
		}
		o += coeff * areatint;
	}

	gl_FragColor = vec4(o, m);
}
