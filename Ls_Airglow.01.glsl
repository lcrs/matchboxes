// Airglow
// Pass 1: pack front RGB and strength A together
// lewis@lewissaunders.com

uniform sampler2D front, strength;
uniform float adsk_result_w, adsk_result_h;

void main() {
  vec2 res = vec2(adsk_result_w, adsk_result_h);
  vec2 xy = gl_FragColor.xy / res;
  vec3 f = texture2D(front, xy).rgb;
  float m = texture2D(strength, xy).b;

  gl_FragColor = vec4(f, m);
}
