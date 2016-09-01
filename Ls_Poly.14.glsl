// Poly
// Pass 14: output addresses of seeds at voronoi cell junctions only

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D adsk_results_pass13;
vec2 res = vec2(adsk_result_w, adsk_result_h);

float alength(vec2 v) {
  v.y /= adsk_result_frameratio;
  return length(v);
}

float coords2address(vec2 c) {
  c *= res;
  return c.y * adsk_result_w + c.x;
}

vec2 address2coords(float a) {
  vec2 c;
  c.y = floor(a / adsk_result_w);
  c.x = a - (c.y * adsk_result_w);
  return c;
}

void main() {
  vec2 xy = gl_FragCoord.xy / res;
  vec4 here = texture2D(adsk_results_pass13, xy);
  vec4 right = texture2D(adsk_results_pass13, (gl_FragCoord.xy + vec2(1.0, 0.0)) / res);
  vec4 down = texture2D(adsk_results_pass13, (gl_FragCoord.xy + vec2(0.0, -1.0)) / res);
  vec4 diag = texture2D(adsk_results_pass13, (gl_FragCoord.xy + vec2(1.0, -1.0)) / res);

  int uniques = 1;
  if(right != here) uniques++;
  if(down != here && down != right) uniques++;
  if(diag != here && diag != down && diag != right) uniques++;

  vec4 o;
  if(uniques > 2) {
    // We are at a junction, output the addresses of the surrounding seeds
    
  } else {
    // We're not somewhere interesting, output -999.0 to indicate this pixel isn't flooded yet
    o = vec4(-999.0);
  }

  gl_FragColor = o;
}
