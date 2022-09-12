// Poly
// Pass 13: jump flood out coords of closest seeds, round 12, distance 2

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio, normp;
uniform sampler2D adsk_results_pass12;
vec2 res = vec2(adsk_result_w, adsk_result_h);

float alength(vec2 v) {
  v.y /= adsk_result_frameratio;
  return pow(pow(abs(v.x), normp) + pow(abs(v.y), normp), 1.0/normp);
}

void main() {
  vec2 xy = gl_FragCoord.xy / res;

  vec4 bestseed = vec4(-999.0);
  float bestdist = 99999.0;
  for(float j = -1.0; j <= 1.0; j += 1.0) {
    for(float k = -1.0; k <= 1.0; k += 1.0) {
      vec4 s = texture2D(adsk_results_pass12, xy + vec2(j, k) * (vec2(2.0)/res));
      if(s.x == -999.0) {
        // This sample has not been flooded yet
        continue;
      }
      float dist = alength(s.xy - xy);
      if(dist < bestdist) {
        // This seed is the closest yet
        bestdist = dist;
        bestseed = s;
      }
    }
  }

  gl_FragColor = bestseed;
}
