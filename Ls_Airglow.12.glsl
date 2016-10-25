// Airglow pass 12: accelerated Gaussian blur, size / 32.000000, direction vec2(1.0, 0.0)
// lewis@lewissaunders.com

#extension GL_ARB_shader_texture_lod : enable

uniform sampler2D strength, adsk_results_pass1;
uniform float size, quality;
uniform float adsk_result_w, adsk_result_h;

// Return a 1D Gaussian blur from texture tex, sampling from mipmap level lod
// xy: centre of blur in pixels
// res: pixel size of mipmap level selected by lod param
// sizes: sigma of blurs, in pixels
// dir: direction of blur, usually vec2(1.0, 0.0) for horizontal followed by
//      another pass for vertical
vec4 gaussianblur(sampler2D tex, float lod, vec2 xy, vec2 res, float sizered, float sizegreen, float sizeblue, float sizealpha, vec2 dir) {
  vec4 sigmas = vec4(sizered, sizegreen, sizeblue, sizealpha);

  // Set up state for incremental coefficient calculation, see GPU Gems
  // We use vec4s to store four copies of the state, for different size
  // red/green/blue/alpha blurs.  We don't actually use that here because
  // doing both small and large blurs in one pass ruins the mipmap acceleration
  // trick - it means we always have to size the mipmap for the smallest blurs
  // which makes the large ones really slow
  vec4 gx = vec4(0.0);
  vec4 gy = vec4(0.0);
  vec4 gz = vec4(0.0);
  gx = 1.0 / (sqrt(2.0 * 3.141592653589793238) * sigmas);
  gy = exp(-0.5 / (sigmas * sigmas));
  gz = gy * gy;
  vec4 a = vec4(0.0);
  vec4 centre = vec4(0.0);
  vec4 sample1 = vec4(0.0);
  vec4 sample2 = vec4(0.0);

  // First take the centre sample
  sample1 = texture2DLod(tex, xy / res, lod);
  a += gx * sample1;
  vec4 energy = gx;
  gx *= gy;
  gy *= gz;

  // Now the other samples
  float support = max(max(max(sigmas.r, sigmas.g), sigmas.b), sigmas.a) * 3.0;
  for(float i = 1.0; i <= support; i++) {
    sample1 = texture2DLod(tex, (xy - i * dir) / res, lod);
    sample2 = texture2DLod(tex, (xy + i * dir) / res, lod);
    a += gx * sample1;
    a += gx * sample2;
    energy += 2.0 * gx;
    gx *= gy;
    gy *= gz;
  }

  return a / energy;
}

void main() {
  vec2 res = vec2(adsk_result_w, adsk_result_h);
  float strength = texture2D(strength, gl_FragCoord.xy / res).b;

  // We do the blur in two stages: a box filter downres followed by a proper
  // Gaussian blur on that low res image.  We get the downres for free
  // from the mipmaps of the texture, fetching from that mip level inside a normal
  // Gaussian convolution loop.
  // We balance the amount of downres against the amount of true convolution with
  // the quality parameter, which is the approximate size of the second stage blur
  // in pixels;  it's not exact because the downres is limited to powers of two
  float s = max(size * strength / 32.000000, 0.0001);
  float downfactor = min(quality / s, 1.0);
  float downlod = floor(log2(1.0/downfactor));
  downfactor = 1.0 / pow(2.0, downlod);
  float  downs = downfactor * s;
  vec2 downres = downfactor * res;
  vec2  downxy = downfactor * gl_FragCoord.xy;

  gl_FragColor = gaussianblur(adsk_results_pass1, downlod, downxy, downres, downs, downs, downs, downs, vec2(1.0, 0.0));
}
