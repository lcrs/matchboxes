// Poly
// Pass 14: at junctions between voronoi cells, output the coords of the 3 or (rarely) 4 nearest seeds

// Instead of using seed texel coords, we now switch to addresses, because we need to pack
// four seed coords into each fragment color
// The address is simply the texel index, i.e. row*width + col
// These addresses are then flooded out from the junction points in the next passes
// This means each pixel in the image can determine which 3 seed points form the best
// triangle around it

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D adsk_results_pass13, adsk_results_pass1;
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

bool contains(float list[4], float t) {
  for(int i = 0; i < 4; i++) {
    if(list[i] == t) return true;
  }
  return false;
}

void main() {
  vec2 xy = gl_FragCoord.xy / res;

  vec2 pixels[4];
  pixels[0] = texture2D(adsk_results_pass13, xy).xy;
  pixels[1] = texture2D(adsk_results_pass13, (gl_FragCoord.xy + vec2(1.0, 0.0)) / res).xy;
  pixels[2] = texture2D(adsk_results_pass13, (gl_FragCoord.xy + vec2(0.0, -1.0)) / res).xy;
  pixels[3] = texture2D(adsk_results_pass13, (gl_FragCoord.xy + vec2(1.0, -1.0)) / res).xy;

  // Create an array of unique addresses from this quad of pixels
  float uniques[4];
  int uniquecount = 0;
  for(int i = 0; i < 4; i++) {
    float addr = coords2address(pixels[i]);
    if(!contains(uniques, addr)) {
      uniques[uniquecount] = addr;
      uniquecount++;
    }
  }

  // Fill rest of array with -999 to signal no value
  for(int i = uniquecount; i < 4; i++) {
    uniques[i] = -999.0;
  }

  vec4 o;
  if(uniquecount > 2) {
    // We are at a junction, output the addresses of the surrounding seeds
    o = vec4(uniques[0], uniques[1], uniques[2], uniques[3]);
  } else {
    // We're not somewhere interesting, signal that this pixel isn't flooded yet
    o = vec4(uniquecount - 1);
  }

  gl_FragColor = vec4(length(texture2D(adsk_results_pass13, xy).xy - xy)) + texture2D(adsk_results_pass1, xy);
}
