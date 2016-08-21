// Poly
// Pass 14: render image from seed coords

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass13, adsk_results_pass1, front;

vec2 res = vec2(adsk_result_w, adsk_result_h);

vec3 rand(vec2 s) {
  vec3 r;
  r.r = 2.0 * fract(sin(dot(s.xy, vec2(12.9898, 78.233))) * 43758.5453) - 1.0;
  r.g = 2.0 * fract(sin(dot(s.xy, vec2(2.9898, 78.233))) * 4358.5453) - 1.0;
  r.b = 2.0 * fract(sin(dot(s.xy, vec2(12.9898, 8.233))) * 4758.5453) - 1.0;
  return r;
}

void main() {
  vec2 xy = gl_FragCoord.xy / res;

  vec3 o;
  vec3 coords = texture2D(adsk_results_pass13, xy).rgb;
  vec3 col = texture2D(front, coords.xy).rgb;
  vec3 randomcol = mix(vec3(0.18), rand(coords.xy), 0.1);
  o = randomcol;

  vec3 seeds = texture2D(adsk_results_pass1, xy).rgb;
  if(seeds.x > 0.0) {
    o += 10.0;
  }

  gl_FragColor = vec4(o, 0.0);
}
