// Airglow
// This has a lot of passes.  I used a little Python script to generate
// most of them, because they're just a lot of Gaussian blurring
// See Ls_Airglow_builder.py
//
// TODO:
//  o Clamp when in video de-tonemapping mode
//  o Negate image before/after for "black promist" effect
//
// Pass 1: multiply front RGB and glow source A together
// lewis@lewissaunders.com

uniform sampler2D front, source;
uniform float adsk_result_w, adsk_result_h;
uniform int colourspace;
vec3 adsk_log2scene(vec3 log);
vec3 adsk_scene2log(vec3 lin);

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

void main() {
  vec2 res = vec2(adsk_result_w, adsk_result_h);
  vec2 xy = gl_FragCoord.xy / res;
  float m = texture2D(source, xy).b;
  vec3 f = texture2D(front, xy).rgb;

  // Convert to linear
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

  f *= m;

  gl_FragColor = vec4(f, m);
}
