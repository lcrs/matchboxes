// Poly
// Pass 27: render from various preceeding passes

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D front, adsk_results_pass1, adsk_results_pass13, adsk_results_pass26;
vec2 res = vec2(adsk_result_w, adsk_result_h);

vec2 address2coords(float a) {
  if(a == -999.0) return vec2(0.0);
  vec2 c;
  c.y = floor(a / adsk_result_w);
  c.x = a - (c.y * adsk_result_w);
  return (c + vec2(0.5)) / res;
}

float coords2address(vec2 c) {
  c *= res;
  c = floor(c); // Remove 0.5 offset from texel-centre sampling... just doing -=0.5 caused precision problems!
  return c.y * adsk_result_w + c.x;
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

// Signed distance to a triangle
float sdTriangle(vec2 p0, vec2 p1, vec2 p2, vec2 p) {
  // The MIT License
  // Copyright © 2014 Inigo Quilez
  // Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  vec2 e0 = p1 - p0;
  vec2 e1 = p2 - p1;
  vec2 e2 = p0 - p2;

  vec2 v0 = p - p0;
  vec2 v1 = p - p1;
  vec2 v2 = p - p2;

  vec2 pq0 = v0 - e0*clamp(dot(v0,e0)/dot(e0,e0), 0.0, 1.0);
  vec2 pq1 = v1 - e1*clamp(dot(v1,e1)/dot(e1,e1), 0.0, 1.0);
  vec2 pq2 = v2 - e2*clamp(dot(v2,e2)/dot(e2,e2), 0.0, 1.0);
  
  vec2 d = min(min(vec2(dot(pq0, pq0), v0.x*e0.y-v0.y*e0.x), vec2(dot(pq1, pq1), v1.x*e1.y-v1.y*e1.x)), vec2(dot(pq2, pq2), v2.x*e2.y-v2.y*e2.x));

  return -sqrt(d.x)*sign(d.y);
}

void main() {
  vec2 xy = gl_FragCoord.xy / res;
  vec4 tri = texture2D(adsk_results_pass26, xy);
  
  // Repeat work from pass 14 to find the borders between Voronoi cells by counting unique neighbours
  vec2 pixels[4];
  pixels[0] = texture2D(adsk_results_pass13, (gl_FragCoord.xy + vec2(0.0,  0.0)) / res).xy;
  pixels[1] = texture2D(adsk_results_pass13, (gl_FragCoord.xy + vec2(1.0,  0.0)) / res).xy;
  pixels[2] = texture2D(adsk_results_pass13, (gl_FragCoord.xy + vec2(1.0, -1.0)) / res).xy;
  pixels[3] = texture2D(adsk_results_pass13, (gl_FragCoord.xy + vec2(0.0, -1.0)) / res).xy;

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

  vec4 fron = texture2D(front, xy);
  vec4 seeds = texture2D(adsk_results_pass1, xy);
  vec4 voronoi_nearest = texture2D(adsk_results_pass13, xy);
  float voronoi_edges = uniquecount > 1 ? 1.0 : 0.0;
  float delaunay_sdf = -sdTriangle(address2coords(tri.r), address2coords(tri.g), address2coords(tri.b), xy);
  float delaunay_edges = 1.0 - smoothstep(0.0, 0.002, delaunay_sdf);
  float delaunay_known = smoothstep(-0.004, -0.002, delaunay_sdf);
  vec2 delaunay_centre = (address2coords(tri.r) + address2coords(tri.g) + address2coords(tri.b)) / vec2(3.0);
  float delaunay_area = -saTriangle(address2coords(tri.r), address2coords(tri.g), address2coords(tri.b));
  
  vec4 o;
  o.rgb = texture2D(front, delaunay_centre).rgb;
  o.rgb = mix(o.rgb, vec3(0.0), delaunay_edges / 2.0);
  o.rgb *= delaunay_known;

  gl_FragColor = o;
}

