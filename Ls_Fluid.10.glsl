// Pass 10
// Create output image from accumulated vectors and image input
//
// Filtering code originally from http://www.pmavridis.com/ewa.html
// Hacked up extensively to work on old GPUs by lewis@lewissaunders.com
//
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass9, img;
uniform float adsk_result_w, adsk_result_h;
uniform int rgbout, matteout, texellimit, isamples;
vec2 res = vec2(adsk_result_w, adsk_result_h);

vec4 texture2DEWA(sampler2D tex0, vec2 p0) {
	const float filterwidth = 1.0;
	const float filtersharpness = 4.0;

	vec2 du = dFdx(p0);
	vec2 dv = dFdy(p0);
	float scale = adsk_result_w;

	p0 -=vec2(0.5,0.5)/scale;
	vec2 p = scale * p0;

	float ux = filterwidth * du.s * scale;
	float vx = filterwidth * du.t * scale;
	float uy = filterwidth * dv.s * scale;
	float vy = filterwidth * dv.t * scale;

	// compute ellipse coefficients
	// A*x*x + B*x*y + C*y*y = F.
	float A = vx*vx+vy*vy+1.0;
	float B = -2.0*(ux*vx+uy*vy);
	float C = ux*ux+uy*uy+1.0;
	float F = A*C-B*B/4.0;

	// Compute the ellipse's (u,v) bounding box in texture space
	float bbox_du = 2.0 / (-B*B+4.0*C*A) * sqrt((-B*B+4.0*C*A)*C*F);
	float bbox_dv = 2.0 / (-B*B+4.0*C*A) * sqrt(A*(-B*B+4.0*C*A)*F);

	// Clamp the ellipse so that the bbox includes at most TEXEL_LIMIT texels.
	// This is necessary in order to bound the run-time, since the ellipse can be arbitrarily large
	// Note that here we are actually clamping the bbox directly instead of the ellipse.
	if(bbox_du*bbox_dv>float(texellimit)) {
		float ll = sqrt(bbox_du*bbox_dv / float(texellimit));
		bbox_du/=ll;
		bbox_dv/ll;
	}

	// The ellipse bbox
	int u0 = int(floor(p.s - bbox_du));
	int u1 = int(ceil (p.s + bbox_du));
	int v0 = int(floor(p.t - bbox_dv));
	int v1 = int(ceil (p.t + bbox_dv));

	// Heckbert MS thesis, p. 59; scan over the bounding box of the ellipse
	// and incrementally update the value of Ax^2+Bxy*Cy^2; when this
	// value, q, is less than F, we're inside the ellipse so we filter
	// away...
	vec4 num= vec4(0.0, 0.0, 0.0, 1.0);
	float den = 0.0;
	float ddq = 2.0 * A;
	float U = float(u0) - p.s;

	for (int v = v0; v <= v1; ++v) {
		float V = float(v) - p.t;
		float dq = A*(2.0*U+1.0) + B*V;
		float q = (C*V + B*U)*V + A*U*U;
		for (int u = u0; u <= u1; ++u) {
			if (q < F) {
				float r2 = q / F;
				// Gaussian filter weights
				float weight = exp(-filtersharpness * r2);

				num += weight * texture2D(tex0, vec2(float(u)+0.5,float(v)+0.5)/scale);
				den += weight;
			}
			q += dq;
			dq += ddq;
		}
	}
	vec4 color = num*(1./den);
	return color;
}

void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);
	vec3 rgb = vec3(0.0);
	float matte = 0.0;

	vec2 vecs = texture2D(adsk_results_pass9, xy * px).rg;
	vec2 uvs = texture2D(adsk_results_pass9, xy * px).ba;

	if(rgbout == 0) {
		// Output vectors
		rgb.rg = vecs;
	} else if(rgbout == 1) {
		// Output UVs
		rgb.rg = uvs;
	} else if(rgbout == 2) {
		// Output distorted image
		if(isamples == 1) {
			rgb = texture2D(img, uvs).rgb;
		} else {
			float samps = float(isamples);
			for(float i = 0.0; i < samps; i++) {
				for(float j = 0.0; j < samps; j++) {
					vec2 sample_xy = gl_FragCoord.xy + vec2(i/(samps + 1.0), j/(samps + 1.0)) - vec2(0.5);
					vec2 sample_uv = texture2D(adsk_results_pass9, sample_xy * px).ba;
					rgb += texture2D(img, sample_uv).rgb;
				}
			}
			rgb /= samps * samps;
		}
	} else if(rgbout == 3) {
		// Output distorted image with EWA filtering
		if(isamples == 1) {
			rgb = texture2DEWA(img, uvs).rgb;
		} else {
			float samps = float(isamples);
			for(float i = 0.0; i < samps; i++) {
				for(float j = 0.0; j < samps; j++) {
					vec2 sample_xy = gl_FragCoord.xy + vec2(i/(samps + 1.0), j/(samps + 1.0)) - vec2(0.5);
					vec2 sample_uv = texture2D(adsk_results_pass9, sample_xy * px).ba;
					rgb += texture2DEWA(img, sample_uv).rgb;
				}
			}
			rgb /= samps * samps;
		}
	} else if(rgbout == 4) {
		// Output velocity
		rgb = vec3(length(vecs));
	} else if(rgbout == 5) {
		// Output position map
		rgb = vec3(xy - res/2.0, length(vecs) * 100.0);
	}

	// Matte output gets velocity
	matte = length(vecs);

	gl_FragColor = vec4(rgb, matte);
}

// Portions of the above were adapted from the demo source code published with the paper "High Quality Elliptical Texture Filtering on GPU"
// found at http://www.pmavridis.com/ewa.html
// MIT license text follows:
// Copyright (c) 2010-2011 Pavlos Mavridis
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
