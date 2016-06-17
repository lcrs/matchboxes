uniform float adsk_result_w, adsk_result_h;
uniform sampler2D front, adsk_texture_grid;

void main() {
  vec2 res = vec2(adsk_result_w, adsk_result_h);
  vec2 xy = gl_FragCoord.xy / res;


  gl_FragColor = vec4(0.5);
}
