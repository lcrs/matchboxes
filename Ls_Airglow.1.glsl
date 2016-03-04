// Inverse square law glow
// Pass 1: 8 horizontal gaussian blurs into 8 MRT buffers
// lewis@lewissaunders.com

uniform sampler2D front;
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
	vec4 sampl = texture2D(front, xy * px);
	for(int i = 0; i < 8; i++) {
		a[i] += g[i].x * sampl;
		energy[i] += g[i].x;
		g[i].xy *= g[i].yz;
	}

	// The rest
	for(int x = 1; x <= support; x++) {
		vec4 sampl1 = texture2D(front, (xy - vec2(float(x), 0.0)) * px);
		vec4 sampl2 = texture2D(front, (xy + vec2(float(x), 0.0)) * px);
		for(int i = 0; i < 8; i++) {
			a[i] += g[i].x * sampl1;
			a[i] += g[i].x * sampl2;
			energy[i] += 2.0 * g[i].x;
			g[i].xy *= g[i].yz;
		}
	}

	for(int i = 0; i < 8; i++) {
		a[i] /= energy[i];
		gl_FragData[i] = a[i];
	}
}
