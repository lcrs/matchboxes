// Vector operations
// Normalize, scale, rotate, translate, compute lengths of and combine vector passes
// lewis@lewissaunders.com
// TODO:
//  o Gamma?
//  o NaN killing after length/normalisation

uniform sampler2D A, B, C, D, E, F;
uniform float adsk_result_w, adsk_result_h;

uniform bool Anorm, Bnorm, Cnorm, Dnorm, Onorm;
uniform vec3 Amult, Bmult, Cmult, Dmult, Omult;
uniform vec3 Amult2, Bmult2, Cmult2, Dmult2, Omult2;
uniform float Amult3, Bmult3, Cmult3, Dmult3, Omult3;
uniform vec3 Arot, Brot, Crot, Drot, Orot;
uniform vec3 Aadd, Badd, Cadd, Dadd, Oadd;
uniform vec3 Aadd2, Badd2, Cadd2, Dadd2, Oadd2;
uniform bool Alen, Blen, Clen, Dlen, Olen;

uniform bool add, subtract, screen, outside, adotb, acrossb;
uniform float mixa;

uniform vec3 picker;

#define pi 3.1415926535897932384624433832795

// Degrees to radians
float deg2rad(float angle) {
	return(angle/(180.0/pi));
}

// Rotates in ZXY order
vec3 rotate(vec3 p, vec3 angles) {
	float x = deg2rad(angles.x);
	float y = deg2rad(angles.y);
	float z = deg2rad(angles.z);
	mat3 rx = mat3(1.0, 0.0, 0.0, 0.0, cos(x), sin(x), 0.0, -sin(x), cos(x));
	mat3 ry = mat3(cos(y), 0.0, -sin(y), 0.0, 1.0, 0.0, sin(y), 0.0, cos(y));
	mat3 rz = mat3(cos(z), sin(z), 0.0, -sin(z), cos(z), 0.0, 0.0, 0.0, 1.0);
	mat3 r = ry * rx * rz;
	return(p * r);
}

// Go!
void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 xy = gl_FragCoord.xy / res;

	vec3 a = texture2D(A, xy).rgb;
	vec3 b = texture2D(B, xy).rgb;
	vec3 c = texture2D(C, xy).rgb;
	vec3 d = texture2D(D, xy).rgb;
	vec3 e = texture2D(E, xy).rgb;
	vec3 f = texture2D(F, xy).rgb;

	if(Anorm) a = normalize(a);
	if(Bnorm) b = normalize(b);
	if(Cnorm) c = normalize(c);
	if(Dnorm) d = normalize(d);

	a = rotate(a * Amult * Amult2 * Amult3, Arot) + Aadd + Aadd2;
	b = rotate(b * Bmult * Bmult2 * Bmult3, Brot) + Badd + Badd2;
	c = rotate(c * Cmult * Cmult2 * Cmult3, Crot) + Cadd + Cadd2;
	d = rotate(d * Dmult * Dmult2 * Dmult3, Drot) + Dadd + Dadd2;

	if(Alen) a = vec3(length(a));
	if(Blen) b = vec3(length(b));
	if(Clen) c = vec3(length(c));
	if(Dlen) d = vec3(length(d));

	vec3 o = vec3(0.0);
	if(add) o = a + b + c + d + e + f;
	if(subtract) o = a - b - c - d - e - f;
	vec3 one = vec3(1.0);
	if(screen) o = one - (one - a) * (one - b) * (one - c) * (one - d) * (one - e) * (one - f);
	if(outside) o = a * (one - b) * (one - c) * (one - d) * (one - e) * (one - f);
	if(adotb) o = vec3(dot(a, b));
	if(acrossb) o = cross(a, b);
	o = mixa * o + (1.0 - mixa) * texture2D(A, xy).rgb;

	if(Onorm) o = normalize(o);
	o = rotate(o * Omult * Omult2 * Omult3, Orot) + Oadd + Oadd2;
	if(Olen) o = vec3(length(o));

	// Bonus matte output!  It's kind of a measure of how similar the result is to the A input
	float m = dot(o, a);

	gl_FragColor = vec4(o, m);
}
