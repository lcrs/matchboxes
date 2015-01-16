// Lumps blur vertical pass and split/scale/combine
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass1, adsk_results_pass2, adsk_results_pass3, adsk_results_pass4, adsk_results_pass6, adsk_results_pass7;
uniform float adsk_result_w, adsk_result_h;
uniform float lumpsize;
uniform bool outputcolour, outputlumps, outputdetail;
uniform float scolour, slumps, sdetail;
uniform bool recombine, islin;
const float pi = 3.141592653589793238462643383279502884197969;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	if(recombine) {
		vec4 colour = texture2D(adsk_results_pass2, xy * px);
		vec4 lumps = texture2D(adsk_results_pass3, xy * px);
		vec4 detail = texture2D(adsk_results_pass4, xy * px);
		if(islin) {
			lumps -= vec4(0.18);
			detail -= vec4(0.18);
		} else {
			lumps -= vec4(0.5);
			detail -= vec4(0.5);
		}
		colour /= scolour;
		lumps /= slumps;
		detail /= sdetail;
		gl_FragColor = colour + lumps + detail;
		return;
	}

	float sigma = lumpsize;
	int support = int(sigma * 3.0);

	// Incremental coefficient calculation setup as per GPU Gems 3
	vec3 g;
	g.x = 1.0 / (sqrt(2.0 * pi) * sigma);
	g.y = exp(-0.5 / (sigma * sigma));
	g.z = g.y * g.y;

	if(sigma == 0.0) {
		g.x = 1.0;
	}

	// Centre sample
	vec4 a = g.x * texture2D(adsk_results_pass7, xy * px);
	float energy = g.x;
	g.xy *= g.yz;

	// The rest
	for(int i = 1; i <= support; i++) {
		a += g.x * texture2D(adsk_results_pass7, (xy - vec2(0.0, float(i))) * px);
		a += g.x * texture2D(adsk_results_pass7, (xy + vec2(0.0, float(i))) * px);
		energy += 2.0 * g.x;
		g.xy *= g.yz;
	}
	a /= energy;

	vec4 front = texture2D(adsk_results_pass1, xy * px);
	vec4 colour = texture2D(adsk_results_pass6, xy * px);
	vec4 lumps = a - colour;
	vec4 detail = front - a;

	colour *= scolour;
	lumps *= slumps;
	detail *= sdetail;

	vec4 o = vec4(0.5);
	if(islin) o = vec4(0.18);

	if(outputcolour) o = colour;
	if(outputlumps) o += lumps;
	if(outputdetail) o += detail;

	gl_FragColor = o;
}
