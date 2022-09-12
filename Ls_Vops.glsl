// Vector operations
// Normalize, scale, rotate, translate, compute lengths of and combine vector passes
// lewis@lewissaunders.com
// TODO:
//  o Gamma?
//  o NaN killing after length/normalisation

uniform sampler2D A, B, C, D, E, F;
uniform float adsk_result_w, adsk_result_h;

uniform bool Anorm, Bnorm, Cnorm, Dnorm, Enorm, Fnorm, Onorm;
uniform vec3 Amult, Bmult, Cmult, Dmult, Emult, Fmult, Omult;
uniform vec3 Amult2, Bmult2, Cmult2, Dmult2, Emult2, Fmult2, Omult2;
uniform float Amult3, Bmult3, Cmult3, Dmult3, Emult3, Fmult3, Omult3;
uniform vec3 Arot, Brot, Crot, Drot, Erot, Frot, Orot;
uniform vec3 Aadd, Badd, Cadd, Dadd, Eadd, Fadd, Oadd;
uniform vec3 Aadd2, Badd2, Cadd2, Dadd2, Eadd2, Fadd2, Oadd2;
uniform bool Alen, Blen, Clen, Dlen, Elen, Flen, Olen;

uniform int blendmode, vectormode;
uniform float mixa;

uniform vec3 picker;

#define pi 3.1415926535897932384624433832795

vec4 adsk_getBlendedValue(int blendType, vec4 srcColor, vec4 dstColor);

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
	if(Enorm) e = normalize(e);
	if(Fnorm) f = normalize(f);

	a = rotate(a * Amult * Amult2 * Amult3, Arot) + Aadd + Aadd2;
	b = rotate(b * Bmult * Bmult2 * Bmult3, Brot) + Badd + Badd2;
	c = rotate(c * Cmult * Cmult2 * Cmult3, Crot) + Cadd + Cadd2;
	d = rotate(d * Dmult * Dmult2 * Dmult3, Drot) + Dadd + Dadd2;
	e = rotate(e * Emult * Emult2 * Emult3, Erot) + Eadd + Eadd2;
	f = rotate(f * Fmult * Fmult2 * Fmult3, Frot) + Fadd + Fadd2;

	if(Alen) a = vec3(length(a));
	if(Blen) b = vec3(length(b));
	if(Clen) c = vec3(length(c));
	if(Dlen) d = vec3(length(d));
	if(Elen) e = vec3(length(e));
	if(Flen) f = vec3(length(f));

	// Blend all 6 in reverse order
	vec4 be = adsk_getBlendedValue(blendmode, vec4(f, 1.0), vec4(e, 1.0));
	vec4 bd = adsk_getBlendedValue(blendmode, be, vec4(d, 1.0));
	vec4 bc = adsk_getBlendedValue(blendmode, bd, vec4(c, 1.0));
	vec4 bb = adsk_getBlendedValue(blendmode, bc, vec4(b, 1.0));
	vec4 ba = adsk_getBlendedValue(blendmode, bb, vec4(a, 1.0));
	vec3 o = ba.rgb;

	// Custom outside blend mode
	vec3 one = vec3(1.0);
	if(blendmode == 99) o = a * (one - b) * (one - c) * (one - d) * (one - e) * (one - f);

	// Combine just A and B if vector mode is enabled
	if(vectormode == 1) o = vec3(dot(a, b));
	if(vectormode == 2) o = cross(a, b);

	// Mix with original A input
	o = mixa * o + (1.0 - mixa) * texture2D(A, xy).rgb;

	// Process output
	if(Onorm) o = normalize(o);
	o = rotate(o * Omult * Omult2 * Omult3, Orot) + Oadd + Oadd2;
	if(Olen) o = vec3(length(o));

	// Bonus matte output!  It's kind of a measure of how similar the result is to the A input
	float m = dot(o, a);

	gl_FragColor = vec4(o, m);
}
