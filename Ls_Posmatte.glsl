// Pick an ellipsoidal area matte from an XYZ position pass
// lewis@lewissaunders.com
// TODO:
//  o Rotation
//  o Skew
//  o Cube-shaped matte - with rounded corners?

uniform float adsk_result_w, adsk_result_h;
uniform vec3 pick, overlaycol;
uniform float tolerance, softness, falloffswoop, offsetx, offsety, offsetz, scalex, scaley, scalez;
uniform bool overlay, hatch;
uniform sampler2D front, matte, pos;

void main() {
	vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
	vec3 o, frontpix, pospix, mattepix, centered, diff = vec3(0.0);
	float m = 0.0;

	frontpix = texture2D(front, coords).rgb;
	mattepix = texture2D(matte, coords).rgb;
	pospix = texture2D(pos, coords).rgb;

	// Center coordinate space about the picked colour so we can scale easily
	centered = pospix - pick - vec3(offsetx, offsety, offsetz);
	diff = centered / vec3(scalex, scaley, scalez);

	m = length(diff);
	if(m < tolerance) {
		m = 0.0;
	} else {
		m = (m - tolerance) / softness;
	}
	m = clamp(1.0 - m, 0.0, 1.0);
	m = mix(m, smoothstep(0.0, 1.0, m), falloffswoop);
	m *= mattepix.b;

	o = frontpix;
	if(overlay) {
		o += m * overlaycol;
		if(hatch) {
			// Cheap-ass diagonal lines
			float h = mod(gl_FragCoord.x - gl_FragCoord.y, 20.0);
			h = h > 10.0 ? 0.0 : 1.0;
			o = mix(o, frontpix, h);
		}
	}

	gl_FragColor = vec4(o, m);
}
