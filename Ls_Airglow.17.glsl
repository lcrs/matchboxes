// Airglow pass 17: accelerated Gaussian blur, size / 128.000000, direction vec2(0.0, 1.0)
// lewis@lewissaunders.com

#extension GL_ARB_shader_texture_lod : enable

uniform sampler2D strength, adsk_results_pass16;
uniform float size, quality;
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D front, adsk_results_pass1, adsk_results_pass3, adsk_results_pass5, adsk_results_pass7, adsk_results_pass9, adsk_results_pass11, adsk_results_pass13, adsk_results_pass15;
uniform vec3 tint;
uniform float mixx;
uniform bool glowonly, maintain;
uniform ivec4 weights;
uniform int colourspace;
vec3 adsk_hsv2rgb(vec3 hsv);
vec4 adskEvalDynCurves(ivec4 curve, vec4 x);
vec3 adsk_log2scene(vec3 log);
vec3 adsk_scene2log(vec3 lin);

// These two functions need to be in sync with pass 1!
// Convert from linear to video a simple, invertible way, but with smooth highlight rolloff
vec3 tonemap(vec3 x) {
  x = max(x, 0.0);
  x = adsk_scene2log(x);
  x -= 95.0 / 1023.0;
  x *= 3.14159265;
  x = cos(x);
  x = 1.0 - x;
  x /= 2.0;
  x = max(x, 0.0);
  return x;
}

// Convert from video to linear, the inverse of above - unrolls highlights to above 1.0
vec3 untonemap(vec3 x) {
  x = max(x, 0.0);
  x *= 2.0;
  x = 1.0 - x;
  x = acos(x);
  x /= 3.14159265;
  x += 95.0 / 1023.0;
  x = max(x, 0.0);
  x = adsk_log2scene(x);
  x = max(x, 0.0);
  return x;
}

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
  float s = max(size * strength / 128.000000, 0.0001);
  float downfactor = min(quality / s, 1.0);
  float downlod = floor(log2(1.0/downfactor));
  downfactor = 1.0 / pow(2.0, downlod);
  float  downs = downfactor * s;
  vec2 downres = downfactor * res;
  vec2  downxy = downfactor * gl_FragCoord.xy;

  vec4 gb17 = gaussianblur(adsk_results_pass16, downlod, downxy, downres, downs, downs, downs, downs, vec2(0.0, 1.0));

  // Blend 'em all
  vec3 tintc = tint;
  tintc.x /= 360.0;
  tintc.yz /= 100.0;
  vec4 tintrgb = vec4(adsk_hsv2rgb(tintc), 1.0);

  vec3 f = texture2D(front, gl_FragCoord.xy / res).rgb;
  // Convert front pixel to linear so we can add it to the glow
  if(colourspace == 0) {
   // Log
   f = adsk_log2scene(f);
  } else if(colourspace == 1) {
   // Video - inverse tonemapping to get some highlights back
   f = untonemap(f);
  } else if(colourspace == 2) {
   // Video (gamma only)
   f = max(f, 0.0);
   f.r = pow(f.r, 2.4);
   f.g = pow(f.g, 2.4);
   f.b = pow(f.b, 2.4);
  } else if(colourspace == 3) {
   // Linear
   f = f;
  }

  // Per-blur weights from curve in UI - alpha curve is used as master
  vec4 w1, w2, w3, w4, w5, w6, w7, w8;
  w1 = max(adskEvalDynCurves(weights, vec4(0.0/7.0)), 0.0);
  w1.rgb *= w1.a;
  w2 = max(adskEvalDynCurves(weights, vec4(1.0/7.0)), 0.0);
  w2.rgb *= w2.a;
  w3 = max(adskEvalDynCurves(weights, vec4(2.0/7.0)), 0.0);
  w3.rgb *= w3.a;
  w4 = max(adskEvalDynCurves(weights, vec4(3.0/7.0)), 0.0);
  w4.rgb *= w4.a;
  w5 = max(adskEvalDynCurves(weights, vec4(4.0/7.0)), 0.0);
  w5.rgb *= w5.a;
  w6 = max(adskEvalDynCurves(weights, vec4(5.0/7.0)), 0.0);
  w6.rgb *= w6.a;
  w7 = max(adskEvalDynCurves(weights, vec4(6.0/7.0)), 0.0);
  w7.rgb *= w7.a;
  w8 = max(adskEvalDynCurves(weights, vec4(7.0/7.0)), 0.0);
  w8.rgb *= w8.a;

  // Weight and add the blurs
  vec4 a = gb17                                              * w1;
  a += texture2D(adsk_results_pass15, gl_FragCoord.xy / res) * w2;
  a += texture2D(adsk_results_pass13, gl_FragCoord.xy / res) * w3;
  a += texture2D(adsk_results_pass11, gl_FragCoord.xy / res) * w4;
  a += texture2D(adsk_results_pass9,  gl_FragCoord.xy / res) * w5;
  a += texture2D(adsk_results_pass7,  gl_FragCoord.xy / res) * w6;
  a += texture2D(adsk_results_pass5,  gl_FragCoord.xy / res) * w7;
  a += texture2D(adsk_results_pass3,  gl_FragCoord.xy / res) * w8;
  a *= tintrgb;

  if(maintain) {
   a /= 9.0;
   if(!glowonly) a.rgb += f / 9.0;
  } else {
   a /= 8.0;
   if(!glowonly) a.rgb += f;
  }

  a.rgb = mix(f, a.rgb, mixx);

  // Convert from linear to whatever the input space was
  if(colourspace == 0) {
   // Log
   a.rgb = adsk_scene2log(a.rgb);
  } else if(colourspace == 1) {
   // Video - tonemap from linear
   a.rgb = tonemap(a.rgb);
  } else if(colourspace == 2) {
   // Video (gamma only)
   a = max(a, 0.0);
   a.r = pow(a.r, 1.0/2.4);
   a.g = pow(a.g, 1.0/2.4);
   a.b = pow(a.b, 1.0/2.4);
  } else if(colourspace == 3) {
   // Linear
   a = a;
  }

  gl_FragColor = a;

}
