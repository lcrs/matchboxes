// Poly
// Pass 14: at junctions between voronoi cells, output the coords of the 3 or (rarely) 4 nearest seeds

// Instead of using seed texel coords, we now switch to addresses, because we need to pack
// four seed coords into each fragment color
// The address is simply the texel index, i.e. row*width + col
// These addresses are then flooded out from the junction points in the next passes
// This means each pixel in the image can determine which 3 seed points form the best
// triangle around it

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

  // Create an array of unique addresses from this quad of pixels
  float addresses[4];
  int uniques = 0;
  addresses[uniques] = here.x;
  uniques++;
  if(right != here) {
    addresses[uniques] = right.x;
    uniques++;
  }
  if(diag != here && diag != right) {
    addresses[uniques] = down.x;
    uniques++;
  }
  if(down != here && down != diag && down != right) {
    addresses[uniques] = diag.x;
    uniques++;
  }
  // Fill rest of array with -999 to indicate unused
  for(int i = uniques; i < 4; i++) {
    addresses[i] = -999.0;
  }

  vec4 o;
  if(uniques > 2) {
    // We are at a junction, output the addresses of the surrounding seeds
    o = vec4(addresses[0], addresses[1], addresses[2], addresses[3]);
  } else {
    // We're not somewhere interesting, output -999 to indicate this pixel isn't flooded yet
    o = vec4(-999.0);
    if(uniques == 2) o = vec4(0.2);
  }

  gl_FragColor = o;
}
