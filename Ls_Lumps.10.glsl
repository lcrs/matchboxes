// Detail filter vertical pass and split/scale/combine
// lewis@lewissaunders.com

uniform sampler2D front, adsk_results_pass4, adsk_results_pass6, adsk_results_pass8, adsk_results_pass9;
uniform sampler2D colourt, lumpst, detailt;
uniform float adsk_result_w, adsk_result_h;
uniform float detailfiltersize, detailsharpenamnt;
uniform bool outputcolour, outputlumps, outputdetail;
uniform float colourgamma, colourcontrast;
uniform float lumpsgamma, lumpscontrast;
uniform float detailgamma, detailcontrast;
uniform float scolour, slumps, sdetail;
uniform bool recombine, islin;
const float pi = 3.141592653589793238462643383279502884197969;

vec4 getdetail(vec2 xy) {
    if(recombine) {
        // Use node's detail input
		if(islin) {
			return texture2D(detailt, xy) - vec4(0.18);
		} else {
			return texture2D(detailt, xy) - vec4(0.5);
		}
    } else {
        // Use our calculated detail band
        return texture2D(front, xy) - texture2D(adsk_results_pass4, xy);
    }
}

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	float sigma = abs(detailfiltersize);
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
	vec4 a = g.x * texture2D(adsk_results_pass9, xy * px);
	float energy = g.x;
	g.xy *= g.yz;

	// The rest
	for(int i = 1; i <= support; i++) {
		a += g.x * texture2D(adsk_results_pass9, (xy - vec2(0.0, float(i))) * px);
		a += g.x * texture2D(adsk_results_pass9, (xy + vec2(0.0, float(i))) * px);
		energy += 2.0 * g.x;
		g.xy *= g.yz;
	}
	a /= energy;

	vec4 filtered = a;
	vec4 detailunfilt = getdetail(xy * px);
	if(detailfiltersize < 0.0) {
		// Sharpen rather than blur
		filtered = detailunfilt + detailsharpenamnt * (detailunfilt - filtered);
	}

	vec4 colour = texture2D(adsk_results_pass6, xy * px);
	vec4 lumps = texture2D(adsk_results_pass8, xy * px);
	vec4 detail = filtered;

	// Grade each band
	colour *= colourcontrast;
	colour = sign(colour) * pow(abs(colour), vec4(1.0/colourgamma));
	lumps *= lumpscontrast;
	lumps = sign(lumps) * pow(abs(lumps), vec4(1.0/lumpsgamma));
	detail *= detailcontrast;
	detail = sign(detail) * pow(abs(detail), vec4(1.0/detailgamma));
	colour *= scolour;
	lumps *= slumps;
	detail *= sdetail;

	vec4 o = vec4(islin ? 0.18 : 0.5);
	if(outputcolour) o = colour;
	if(outputlumps) o += lumps;
	if(outputdetail) o += detail;
	gl_FragColor = o;

}
