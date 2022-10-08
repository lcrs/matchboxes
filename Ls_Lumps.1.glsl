/* The three bands are made like this:
		colour = colourblur
		lumps = lumpsblur - colourblur
		detail = front input - lumpsblur

  There are quite a few passes so here's a diagram of how they connect:

               front input
                    │
           ┌────────┴───────────┬─────────────────────┬──────────┐
           │                    │                     │          │
           ▼                    ▼                     │          │
    01 colourblur h      03 lumpsblur h               │          │
           │                    │                     │          │
           ▼                    ▼                     │          │
┌── 02 colourblur v      04 lumpsblur v ───┬─────┐    │          │
│          │                    │          │     │    │          │
│          ├──────────┬─────┐   │          │     │    │          │
│          │          │     │   │          │     │    │          │
│          ▼          │     ▼   ▼          │     ▼    ▼          │
│  05 colourfilter h  │  07 lumpsfilter h  │  09 detailfilter h  │
│          │          │         │          │          │          │
│          ▼          │         ▼          │───────┐  │          │
└► 06 colourfilter v  └► 08 lumpsfilter v ◄┘       │  │          │
           │                    │                  │  │          │
           │                    └───────────────┐  │  │  ┌───────┘
           │                                    ▼  ▼  ▼  ▼
           └────────────────────────────────► 10 detailfilter v,
                                                 combine and output

	Passes 05, 06, 07, 08, 09 and 10 can also use the colour/lumps/detail inputs
	directly when in "recombine" mode, instead of calculating them from the blurs

	Pass 02 can also use the front input's top MIP level to compute a whole image
	average, instead of blurring
*/

// Colour blur horizontal pass
// lewis@lewissaunders.com

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
uniform float coloursize;
uniform bool recombine, mipmapcolour;
const float pi = 3.141592653589793238462643383279502884197969;

void main() {
	if(recombine) discard;
	if(mipmapcolour) discard;

	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

	float sigma = coloursize;
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
	vec4 a = g.x * texture2D(front, xy * px);
	float energy = g.x;
	g.xy *= g.yz;

	// The rest
	for(int i = 1; i <= support; i++) {
		a += g.x * texture2D(front, (xy - vec2(float(i), 0.0)) * px);
		a += g.x * texture2D(front, (xy + vec2(float(i), 0.0)) * px);
		energy += 2.0 * g.x;
		g.xy *= g.yz;
	}
	a /= energy;

	gl_FragColor = a;
}
