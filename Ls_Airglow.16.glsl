#extension GL_ARB_shader_texture_lod : enable

uniform sampler2D adsk_results_pass15;
uniform sampler2D front, adsk_results_pass2, adsk_results_pass4, adsk_results_pass6, adsk_results_pass8, adsk_results_pass10, adsk_results_pass12, adsk_results_pass14;
uniform float size, quality;
uniform float adsk_result_w, adsk_result_h;
uniform vec3 tint;
uniform float mixx;
const float pi = 3.141592653589793238;

vec3 adsk_hsv2rgb(vec3 hsv);

vec4 gaussianblur(sampler2D tex, float lod, vec2 xy, vec2 res, float sizered, float sizegreen, float sizeblue, float sizealpha, vec2 dir) {
  vec4 sigmas = vec4(sizered, sizegreen, sizeblue, sizealpha);
  float support = max(max(max(sigmas.r, sigmas.g), sigmas.b), sigmas.a) * 3.0;

  // Set up state for incremental coefficient calculation, see GPU Gems
  // We use vec4s to store four copies of the state, for different size
  // red/green/blue/alpha blurs
  vec4 gx, gy, gz;
  gx = 1.0 / (sqrt(2.0 * pi) * sigmas);
  gy = exp(-0.5 / (sigmas * sigmas));
  gz = gy * gy;

  // First take the centre sample
  vec4 a = gx * texture2DLod(tex, xy / res, lod);
  vec4 energy = gx;
  gx *= gy;
  gy *= gz;

  // Now the other samples
  for(float i = 1.0; i <= support; i++) {
    a += gx * texture2DLod(tex, (xy - i * dir) / res, lod);
    a += gx * texture2DLod(tex, (xy + i * dir) / res, lod);
    energy += 2.0 * gx;
    gx *= gy;
    gy *= gz;
  }

  return a / energy;
}

void main() {
  vec2 res = vec2(adsk_result_w, adsk_result_h);

  // We do the blur on a low res texture taken from its mipmaps
  // We choose how big the downres is by looking at the quality parameter. The bigger it
  // is, the less severe the downres.  It is approximately the size of the second-stage
  // Gaussian blur - not exactly so, because the downres factors we can get from the mipmaps
  // are limited to powers of two

  float s = max(size / 128.0, 0.0001);
  float downfactor = min(quality / s, 1.0);
  float downlod = floor(log2(1.0/downfactor));
  downfactor = 1.0 / pow(2.0, downlod);
  float downs = downfactor * s;
  vec2 downres = downfactor * res;
  vec2 downxy = downfactor * gl_FragCoord.xy;

  vec4 gb16 = gaussianblur(adsk_results_pass15, downlod, downxy, downres, downs, downs, downs, downs, vec2(0.0, 1.0));

  // Blend and comp 'em all
  vec3 tintc = tint;
  tintc.x /= 360.0;
  tintc.yz /= 100.0;
  vec4 tintrgb = vec4(adsk_hsv2rgb(tintc), 1.0);

  vec3 f = texture2D(front, gl_FragCoord.xy / res).rgb;
  
  vec4 a;
  a = vec4(f, 1.0);
  a += gb16 * tintrgb;
  a += texture2D(adsk_results_pass14, gl_FragCoord.xy / res) * tintrgb;
  a += texture2D(adsk_results_pass12, gl_FragCoord.xy / res) * tintrgb;
  a += texture2D(adsk_results_pass10, gl_FragCoord.xy / res) * tintrgb;
  a += texture2D(adsk_results_pass8, gl_FragCoord.xy / res) * tintrgb;
  a += texture2D(adsk_results_pass6, gl_FragCoord.xy / res) * tintrgb;
  a += texture2D(adsk_results_pass4, gl_FragCoord.xy / res) * tintrgb;
  a += texture2D(adsk_results_pass2, gl_FragCoord.xy / res) * tintrgb;
  a /= 9.0;

  a.rgb = mix(f.rgb, a.rgb, mixx);

  gl_FragColor = a;
}
