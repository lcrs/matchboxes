// Stereographic projection of a 360x180 latlong panorama, tiny planets style
// lewis@lewissaunders.com

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D front;
uniform float yo, xo, long0, lat1, r;
uniform float latm, longm, lato, longo;

// Defaults set in XML:
// xo = 0.5
// yo = 0.5
// long0, lat1, r = adjusted to taste
// latm = 1.0 / PI
// longm = 1.0 / (2.0 * PI)
// lato = -PI / 2.0
// longo = -PI

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 coords = gl_FragCoord.xy / res;
	coords.x -= 0.5;
	coords.x *= (res.x / res.y);
	coords.x += 0.5;

	float p = sqrt((coords.x-xo)*(coords.x-xo)+(coords.y-yo)*(coords.y-yo));
	float c = 2.0 * atan(p, 2.0 * r);
	float longg = (long0 + atan((coords.x-xo)*sin(c), p*cos(lat1)*cos(c) - (coords.y-yo)*sin(lat1)*sin(c)));
	float lat = asin(cos(c)*sin(lat1) + (((coords.y-yo)*sin(c)*cos(lat1)) / p));
	vec2 uv;
	uv.x = (longg - longo) * longm;
	uv.y = (lat - lato) * latm;

	vec3 o = texture2D(front, uv).rgb;

	gl_FragColor = vec4(o, 1.00);
}
