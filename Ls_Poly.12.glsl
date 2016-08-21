// Poly
// Pass 12: jump flood round 11, distance 1/2048

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass11;

vec2 res = vec2(adsk_result_w, adsk_result_h);

void main() {
  vec2 xy = gl_FragCoord.xy / res;

  vec4 o = texture2D(adsk_results_pass11, xy);
  /*for(float j = -1.0; j <= 1.0; j += 1.0) {
    for(float k = -1.0; k <= 1.0; k += 1.0) {
      vec4 s = texture2D(adsk_results_pass11, xy + (vec2(j, k) / 2048.0));
      if(s.x == -999.0) {
        // This sample has not been flooded yet
        continue;
      }
      if(length(s.xy - xy) < length(o.xy - xy)) {
        // This sample is the closest yet
        o = s;
      }
    }
  }
*/
  gl_FragColor = o;
}