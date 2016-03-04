// Inverse square law glow
// Pass 2: 8 vertical gaussian blurs, each from corresponding horizontal buffer
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass1;
uniform sampler2D adsk_results_pass1_1;
uniform sampler2D adsk_results_pass1_2;
uniform sampler2D adsk_results_pass1_3;
uniform sampler2D adsk_results_pass1_4;
uniform sampler2D adsk_results_pass1_5;
uniform sampler2D adsk_results_pass1_6;
uniform sampler2D adsk_results_pass1_7;
uniform float adsk_result_w, adsk_result_h;
uniform float size;
const float pi = 3.141592653589793238462643383279502884197969;

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);


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
		sigma[i] = size * pow(2.0, float(i));
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
	sampl[0] = texture2D(adsk_results_pass1, xy * px);
	sampl[1] = texture2D(adsk_results_pass1_1, xy * px);
	sampl[2] = texture2D(adsk_results_pass1_2, xy * px);
	sampl[3] = texture2D(adsk_results_pass1_3, xy * px);
	for(int i = 0; i < 8; i++) {
		a[i] += g[i].x * sampl[i];
		energy[i] += g[i].x;
		g[i].xy *= g[i].yz;
	}

	// The rest

	int support = int(sigma[7]) * 3;
	for(int x = 1; x <= support; x++) {
		vec4 sampl10 = texture2D(adsk_results_pass1, (xy - vec2(0.0, float(x))) * px);
		vec4 sampl20 = texture2D(adsk_results_pass1, (xy + vec2(0.0, float(x))) * px);
		vec4 sampl11 = texture2D(adsk_results_pass1_1, (xy - vec2(0.0, float(x))) * px);
		vec4 sampl21 = texture2D(adsk_results_pass1_1, (xy + vec2(0.0, float(x))) * px);
		vec4 sampl12 = texture2D(adsk_results_pass1_2, (xy - vec2(0.0, float(x))) * px);
		vec4 sampl22 = texture2D(adsk_results_pass1_2, (xy + vec2(0.0, float(x))) * px);
		vec4 sampl13 = texture2D(adsk_results_pass1_3, (xy - vec2(0.0, float(x))) * px);
		vec4 sampl23 = texture2D(adsk_results_pass1_3, (xy + vec2(0.0, float(x))) * px);
		vec4 sampl14 = texture2D(adsk_results_pass1_4, (xy - vec2(0.0, float(x))) * px);
		vec4 sampl24 = texture2D(adsk_results_pass1_4, (xy + vec2(0.0, float(x))) * px);
		vec4 sampl15 = texture2D(adsk_results_pass1_5, (xy - vec2(0.0, float(x))) * px);
		vec4 sampl25 = texture2D(adsk_results_pass1_5, (xy + vec2(0.0, float(x))) * px);
		vec4 sampl16 = texture2D(adsk_results_pass1_6, (xy - vec2(0.0, float(x))) * px);
		vec4 sampl26 = texture2D(adsk_results_pass1_6, (xy + vec2(0.0, float(x))) * px);
		vec4 sampl17 = texture2D(adsk_results_pass1_7, (xy - vec2(0.0, float(x))) * px);
		vec4 sampl27 = texture2D(adsk_results_pass1_7, (xy + vec2(0.0, float(x))) * px);

		a[0] += g[0].x * sampl10;
		a[0] += g[0].x * sampl20;
		energy[0] += 2.0 * g[0].x;
		g[0].xy *= g[0].yz;

		a[1] += g[1].x * sampl11;
		a[1] += g[1].x * sampl21;
		energy[1] += 2.0 * g[1].x;
		g[1].xy *= g[1].yz;

		a[2] += g[2].x * sampl12;
		a[2] += g[2].x * sampl22;
		energy[2] += 2.0 * g[2].x;
		g[2].xy *= g[2].yz;

		a[3] += g[3].x * sampl13;
		a[3] += g[3].x * sampl23;
		energy[3] += 2.0 * g[3].x;
		g[3].xy *= g[3].yz;

		a[4] += g[4].x * sampl14;
		a[4] += g[4].x * sampl24;
		energy[4] += 2.0 * g[4].x;
		g[4].xy *= g[4].yz;

		a[5] += g[5].x * sampl15;
		a[5] += g[5].x * sampl25;
		energy[5] += 2.0 * g[5].x;
		g[5].xy *= g[5].yz;

		a[6] += g[6].x * sampl16;
		a[6] += g[6].x * sampl26;
		energy[6] += 2.0 * g[6].x;
		g[6].xy *= g[6].yz;

		a[7] += g[7].x * sampl17;
		a[7] += g[7].x * sampl27;
		energy[7] += 2.0 * g[7].x;
		g[7].xy *= g[7].yz;
	}


	// Add em all up
	vec4 ultimately = vec4(0.0);
	for(int i = 0; i < 8; i++) {
		a[i] /= energy[i];
		ultimately += a[i];
	}

	gl_FragData[0] = ultimately;
}
