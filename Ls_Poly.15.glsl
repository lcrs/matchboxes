// Poly
// Pass 15: at junctions between voronoi cells, output the addresses of the 3 or (rarely) 4 nearest seeds
// Each junction lies inside one Delaunay triangle, and we want to flood out the coords of its corners
// Instead of using seed texel coords, we now switch to addresses, because we need to pack four seed coords
// into each fragment color
// The address is simply the texel index, i.e. (row * width) + col
// These addresses are then flooded out from the junction points in the next passes
// This means each pixel in the image can determine which 3 seed points form the best triangle around it

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D adsk_results_pass14;
uniform float trimsmall;
vec2 res = vec2(adsk_result_w, adsk_result_h);

float coords2address(vec2 c) {
  c *= res;
  c = floor(c); // Remove 0.5 offset from texel-centre sampling...
  return c.y * (adsk_result_w+50.0) + c.x;
}

vec2 address2coords(float a) {
  if(a == -999.0) return vec2(0.0);
  vec2 c;
  c.y = floor(a / (adsk_result_w+50.0));
  c.x = a - (c.y * (adsk_result_w+50.0));
  return (c + vec2(0.5)) / res;
}

// Returns true if the value t is present anywhere in list
bool contains(float list[4], float t) {
  for(int i = 0; i < 4; i++) {
    if(list[i] == t) return true;
  }
  return false;
}

// Signed area of a triangle
float saTriangle(vec2 p1, vec2 p2, vec2 p3) {
  return 0.5 * (p1.x*p2.y + p2.x*p3.y + p3.x*p1.y - p2.x*p1.y - p3.x*p2.y - p1.x*p3.y);
}

void main() {
  vec2 xy = gl_FragCoord.xy / res;

  vec2 pixels[4];
  pixels[0] = texture2D(adsk_results_pass14, (gl_FragCoord.xy + vec2(0.0,  0.0)) / res).xy;
  pixels[1] = texture2D(adsk_results_pass14, (gl_FragCoord.xy + vec2(1.0,  0.0)) / res).xy;
  pixels[2] = texture2D(adsk_results_pass14, (gl_FragCoord.xy + vec2(1.0, -1.0)) / res).xy;
  pixels[3] = texture2D(adsk_results_pass14, (gl_FragCoord.xy + vec2(0.0, -1.0)) / res).xy;

  // Create an array of unique addresses from this quad of pixels
  float uniques[4];
  uniques[0] = uniques[1] = uniques[2] = uniques[3] = -999.0;
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

    // Only output triangles which are bigger than our trimsmall area
    bool keepfirst = true;
    bool keepsecond = false;
    if(abs(saTriangle(address2coords(o.r), address2coords(o.g), address2coords(o.b))) * 1000.0 < pow(trimsmall, 3.0)) {
      keepfirst = false;
    }
    if(uniquecount > 3) {
      keepsecond = true;
      if(abs(saTriangle(address2coords(o.r), address2coords(o.b), address2coords(o.a))) * 1000.0 < pow(trimsmall, 3.0)) {
        keepsecond = false;
      }
    }
    if(keepfirst && !keepsecond) o.a = -999.0;
    if(!keepfirst && !keepsecond) o = vec4(-999.0);
    if(!keepfirst && keepsecond) {
      o.rgb = o.rba;
      o.a = -999.0;
    }
  } else {
    // We're not somewhere interesting, signal that this pixel isn't flooded yet
    o = vec4(-999.0);
  }

  gl_FragColor = o;
}
