// Poly
// Pass 14: render image from seed coords

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass13, adsk_results_pass1, front;

vec2 res = vec2(adsk_result_w, adsk_result_h);

void main() {
  vec2 xy = gl_FragCoord.xy / res;

  vec3 o;
  vec3 coords = texture2D(adsk_results_pass13, xy).rgb;
  vec3 col = texture2D(front, coords.xy).rgb;
  o = coords;

  vec3 seeds = texture2D(adsk_results_pass1, xy).rgb;
  if(seeds.x > 0.0) {
    o += 10.0;
  }

  gl_FragColor = vec4(o, 0.0);
}
