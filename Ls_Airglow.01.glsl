// Airglow
// Pass 1: pack front RGB and glow source A together
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
