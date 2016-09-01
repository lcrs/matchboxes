// Poly
// Pass 9: jump flood round 8, distance 16

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D adsk_results_pass8;
vec2 res = vec2(adsk_result_w, adsk_result_h);

float alength(vec2 v) {
  v.y /= adsk_result_frameratio;
  return length(v);
}

void main() {
  vec2 xy = gl_FragCoord.xy / res;

  vec4 o = texture2D(adsk_results_pass8, xy);
  for(float j = -1.0; j <= 1.0; j += 1.0) {
    for(float k = -1.0; k <= 1.0; k += 1.0) {
      vec4 s = texture2D(adsk_results_pass8, xy + vec2(j, k) * (vec2(16.0)/res));
      if(s.x == -999.0) {
        // This sample has not been flooded yet
        continue;
      }
      if(alength(s.xy - xy) < alength(o.xy - xy)) {
        // This sample is the closest yet
        o = s;
      }
    }
  }

  gl_FragColor = o;
}
