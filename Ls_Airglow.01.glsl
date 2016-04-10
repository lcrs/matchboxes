// Airglow
// This has a lot of passes.  I used a little Python script to generate
// most of them, because they're just a lot of Gaussian blurring
// See Ls_Airglow_builder.py
//
// Pass 1: multiply front RGB and glow source A together
// lewis@lewissaunders.com

uniform sampler2D front, source;
uniform float adsk_result_w, adsk_result_h;

void main() {
  vec2 res = vec2(adsk_result_w, adsk_result_h);
  vec2 xy = gl_FragCoord.xy / res;
  float m = texture2D(source, xy).b;
  vec3 f = texture2D(front, xy).rgb * m;

  gl_FragColor = vec4(f, m);
}
