// Colour matrix shader for Matchbox
// I apologise for the incredibly stupid variable names but it's 3am yo
// lewis@lewissaunders.com

uniform sampler2D input1, strength;
uniform float adsk_result_w, adsk_result_h;
uniform float r2r, r2g, r2b, g2r, g2g, g2b, b2r, b2g, b2b;
uniform vec3 or, og, ob, ir, ig, ib;
uniform float effect, gain, mixx;

void main() {
	vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
	float mixx_here = mixx * texture2D(strength, coords).r;
	vec3 i = texture2D(input1, coords).rgb;
	vec3 ii = vec3(r2r*i.r + g2r*i.g + b2r*i.b, r2g*i.r + g2g*i.g + b2g*i.b, r2b*i.r + g2b*i.g + b2b*i.b);
	vec3 iii = ii * mat3(or, og, ob);
	vec3 iv = mat3(ir, ig, ib) * iii;
	vec3 v = effect*iv + (1.0-effect)*i;
	vec3 vi = gain * v;
	vec3 vii = mixx_here*vi + (1.0-mixx_here)*i;
	gl_FragColor = vec4(vii, 1.0);
}
