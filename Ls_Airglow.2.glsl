// Inverse square law glow
// Pass 2: 8 vertical gaussian blurs, each from corresponding horizontal buffer
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass1_1;
uniform sampler2D adsk_results_pass1_2;
uniform sampler2D adsk_results_pass1_3;
uniform sampler2D adsk_results_pass1_4;
uniform sampler2D adsk_results_pass1_5;
uniform sampler2D adsk_results_pass1_6;
uniform sampler2D adsk_results_pass1_7;
uniform sampler2D adsk_results_pass1_8;
uniform float adsk_result_w, adsk_result_h;
uniform float size;
const float pi = 3.141592653589793238462643383279502884197969;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	int support = int(size * 3.0);

	// Incremental coefficient calculation setup as per GPU Gems 3
	// We maintain 8 sets of the coefficients, to do 8 different
	// sized blurs at once.  Everything we'd normally do once,
	// we do 8 times except, crucially, the texture calls, which
	// are not dependent on the blur size providing the support
	// is big enough for the largest blur
	float sigma[8];
	float energy[8];
	vec4 a[8];
	vec3 g[8];
	for(int i = 0; i < 8; i++) {
		sigma[i] = size / pow(float(i), 2.0);
		if(size == 0.0) sigma[i] = 0.0;
		energy[i] = 0.0;
		a[i] = vec4(0.0);
		g[i] = vec3(0.0);
		g[i].x = 1.0 / (sqrt(2.0 * pi) * sigma[i]);
		g[i].y = exp(-0.5 / pow(sigma[i], 2.0));
		g[i].z = g[i].y * g[i].y;
		if(sigma[i] == 0.0) g[i].x = 1.0;
	}

	// Centre sample
	vec4 sampl[8];
	sampl[0] = texture2D(adsk_results_pass1_1, xy * px);
	sampl[1] = texture2D(adsk_results_pass1_2, xy * px);
	sampl[2] = texture2D(adsk_results_pass1_3, xy * px);
	sampl[3] = texture2D(adsk_results_pass1_4, xy * px);
	sampl[4] = texture2D(adsk_results_pass1_5, xy * px);
	sampl[5] = texture2D(adsk_results_pass1_6, xy * px);
	sampl[6] = texture2D(adsk_results_pass1_7, xy * px);
	sampl[7] = texture2D(adsk_results_pass1_8, xy * px);
	for(int i = 0; i < 8; i++) {
		a[i] += g[i].x * sampl[i];
		energy[i] += g[i].x;
		g[i].xy *= g[i].yz;
	}
/*
	// The rest
	for(int x = 1; x <= support; x++) {
		vec4 sampl1[8], sampl2[8];
		sampl1[0] = texture2D(adsk_results_pass1_1, (xy - vec2(float(x), 0.0)) * px);
		sampl2[0] = texture2D(adsk_results_pass1_1, (xy + vec2(float(x), 0.0)) * px);
		sampl1[1] = texture2D(adsk_results_pass1_2, (xy - vec2(float(x), 0.0)) * px);
		sampl2[1] = texture2D(adsk_results_pass1_2, (xy + vec2(float(x), 0.0)) * px);
		sampl1[2] = texture2D(adsk_results_pass1_3, (xy - vec2(float(x), 0.0)) * px);
		sampl2[2] = texture2D(adsk_results_pass1_3, (xy + vec2(float(x), 0.0)) * px);
		sampl1[3] = texture2D(adsk_results_pass1_4, (xy - vec2(float(x), 0.0)) * px);
		sampl2[3] = texture2D(adsk_results_pass1_4, (xy + vec2(float(x), 0.0)) * px);
		sampl1[4] = texture2D(adsk_results_pass1_5, (xy - vec2(float(x), 0.0)) * px);
		sampl2[4] = texture2D(adsk_results_pass1_5, (xy + vec2(float(x), 0.0)) * px);
		sampl1[5] = texture2D(adsk_results_pass1_6, (xy - vec2(float(x), 0.0)) * px);
		sampl2[5] = texture2D(adsk_results_pass1_6, (xy + vec2(float(x), 0.0)) * px);
		sampl1[6] = texture2D(adsk_results_pass1_7, (xy - vec2(float(x), 0.0)) * px);
		sampl2[6] = texture2D(adsk_results_pass1_7, (xy + vec2(float(x), 0.0)) * px);
		sampl1[7] = texture2D(adsk_results_pass1_8, (xy - vec2(float(x), 0.0)) * px);
		sampl2[7] = texture2D(adsk_results_pass1_8, (xy + vec2(float(x), 0.0)) * px);
		for(int i = 0; i < 8; i++) {
			a[i] += g[i].x * sampl1[i];
			a[i] += g[i].x * sampl2[i];
			energy[i] += 2.0 * g[i].x;
			g[i].xy *= g[i].yz;
		}
	}
*/
	// Add em all up
	vec4 ultimately = vec4(0.0);
	for(int i = 0; i < 8; i++) {
		ultimately += a[i] / energy[i];
	}

	gl_FragColor = ultimately;
}
