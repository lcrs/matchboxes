// Poly
// Pass 27: render from various preceeding passes

#extension GL_ARB_shader_texture_lod : enable

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D front, textur, adsk_results_pass14, adsk_results_pass28;
uniform float dotsize, voronoiadj, delaunayadj, delaunayedgewidth, delaunayedgeoffset, edgetrans;
uniform vec3 voronoiedgecol, delaunayedgecol;
uniform int voronoistyle, delaunaystyle;
uniform bool seeddots, voronoi, voronoiedges, delaunay, delaunayedges;
vec2 res = vec2(adsk_result_w, adsk_result_h);

// Aspect-correct distance
float alength(vec2 v) {
  v.y /= adsk_result_frameratio;
  return length(v);
}

// Return barycentric coordinates for p in triangle v1,v2,v3
vec3 barycentrics(vec2 p, vec2 v1, vec2 v2, vec2 v3) {
  float det = (v2.y-v3.y)*(v1.x-v3.x)+(v3.x-v2.x)*(v1.y-v3.y);
  float b1 = ((v2.y-v3.y)*(p.x-v3.x)+(v3.x-v2.x)*(p.y-v3.y))/det;
  float b2 = ((v3.y-v1.y)*(p.x-v3.x)+(v1.x-v3.x)*(p.y-v3.y))/det;
  float b3 = 1.0 - b1 - b2;
  return vec3(b1, b2, b3);
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Convert xy coords to the address used by the Delaunay flooding
float coords2address(vec2 c) {
  c *= res;
  c = floor(c); // Remove 0.5 offset from texel-centre sampling...
  return c.y * (adsk_result_w+50.0) + c.x;
}

// Convert address from the Delaunay passes back to xy coords
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
  
  // Repeat what we did in pass 15 to find the borders between Voronoi cells, by counting unique neighbours
  vec2 pixels[4];
  pixels[0] = texture2D(adsk_results_pass14, (gl_FragCoord.xy + vec2(0.0,  0.0)) / res).xy;
  pixels[1] = texture2D(adsk_results_pass14, (gl_FragCoord.xy + vec2(1.0,  0.0)) / res).xy;
  pixels[2] = texture2D(adsk_results_pass14, (gl_FragCoord.xy + vec2(1.0, -1.0)) / res).xy;
  pixels[3] = texture2D(adsk_results_pass14, (gl_FragCoord.xy + vec2(0.0, -1.0)) / res).xy;
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

  // Build Voronoi rendering options
  vec2 voronoi_nearest = texture2D(adsk_results_pass14, xy).xy;
  float voronoi_edges = uniquecount > 1 ? 1.0 : 0.0;
  vec3 voronoicells = vec3(0.0);

  if(voronoistyle == 0) { // Texture input
    vec2 uv = xy - voronoi_nearest;
    uv /= voronoiadj;
    uv += vec2(0.5);
    voronoicells = texture2D(textur, uv).rgb;
  } else if(voronoistyle == 1) { // Random grad
    vec3 c1 = vec3(rand(voronoi_nearest), rand(voronoi_nearest + vec2(0.1)), rand(voronoi_nearest + vec2(0.2)));
    vec3 c2 = vec3(rand(voronoi_nearest + vec2(0.4)), rand(voronoi_nearest + vec2(0.5)), rand(voronoi_nearest + vec2(0.6)));
    vec2 uv = xy - voronoi_nearest;
    float theta = rand(voronoi_nearest + vec2(0.7)) * 3.1415926535;
    uv = vec2(uv.x * cos(theta) - uv.y * sin(theta), uv.x * sin(theta) + uv.y * cos(theta));
    uv.x *= voronoiadj * 10.0;
    float f = smoothstep(0.0, 1.0, uv.x + 0.5);
    voronoicells = mix(c1, c2, f);
  } else if(voronoistyle == 2) { // Random solid
    voronoicells = vec3(rand(voronoi_nearest), rand(voronoi_nearest + vec2(0.1)), rand(voronoi_nearest + vec2(0.2)));
    voronoicells = mix(vec3(0.18), voronoicells, voronoiadj);
  } else if(voronoistyle == 3) { // Magnify
    voronoicells = texture2DLod(front, xy + (voronoiadj - 0.5) * (voronoi_nearest - xy), 0.0).rgb;
  } else if(voronoistyle == 4) { // Distance
    voronoicells = vec3(alength(voronoi_nearest - xy)) * voronoiadj;
  } else if(voronoistyle == 5) { // Seed offset
    voronoicells.xy = voronoi_nearest - xy;
    voronoicells = mix(vec3(0.0), voronoicells, voronoiadj);
  } else if(voronoistyle == 6) { // Seed UVs
    voronoicells.xy = voronoi_nearest;
    voronoicells = mix(vec3(xy, 0.0), voronoicells, voronoiadj);
  } else if(voronoistyle == 7) { // Seed colours
    voronoicells = texture2DLod(front, voronoi_nearest, voronoiadj).rgb;
  }

  // Build seed dots
  float seeddotty = 1.0 - smoothstep(dotsize/res.x, dotsize/res.x + 1.0/res.x, alength(voronoi_nearest - xy));

  // Build Delaunay rendering options
  vec4 tri = texture2D(adsk_results_pass28, xy);
  float delaunay_sdf = -sdTriangle(address2coords(tri.r), address2coords(tri.g), address2coords(tri.b), xy);
  float delaunay_edges = 1.0 - smoothstep((delaunayedgeoffset/100.0) - (delaunayedgewidth/res.x), (delaunayedgeoffset/100.0) + (delaunayedgewidth/res.x), delaunay_sdf);
  float delaunay_known = smoothstep(-2.0/res.x, -0.0/res.x, delaunay_sdf);
  vec2 delaunay_mid = (address2coords(tri.r) + address2coords(tri.g) + address2coords(tri.b)) / vec2(3.0);
  float delaunay_area = -saTriangle(address2coords(tri.r), address2coords(tri.g), address2coords(tri.b));
  vec3 delaunaytris = vec3(0.0);

  if(delaunaystyle == 0) { // Texture input
    vec2 uv = xy - delaunay_mid;
    uv /= delaunayadj;
    uv += vec2(0.5);
    delaunaytris = texture2D(textur, uv).rgb;
  } else if(delaunaystyle == 1) { // Random grad
    vec3 c1 = vec3(rand(delaunay_mid), rand(delaunay_mid + vec2(0.1)), rand(delaunay_mid + vec2(0.2)));
    vec3 c2 = vec3(rand(delaunay_mid + vec2(0.4)), rand(delaunay_mid + vec2(0.5)), rand(delaunay_mid + vec2(0.6)));
    vec2 uv = xy - delaunay_mid;
    float theta = rand(delaunay_mid + vec2(0.7)) * 3.1415926535;
    uv = vec2(uv.x * cos(theta) - uv.y * sin(theta), uv.x * sin(theta) + uv.y * cos(theta));
    uv.x *= delaunayadj * 10.0;
    float f = smoothstep(0.0, 1.0, uv.x + 0.5);
    delaunaytris = mix(c1, c2, f);
  } else if(delaunaystyle == 2) { // Random solid
    delaunaytris = vec3(rand(delaunay_mid), rand(delaunay_mid + vec2(0.1)), rand(delaunay_mid + vec2(0.2)));
    delaunaytris = mix(vec3(0.18), delaunaytris, delaunayadj);
  } else if(delaunaystyle == 3) { // Area
    delaunaytris = vec3(delaunay_area * delaunayadj * 10.0);
  } else if(delaunaystyle == 4) { // Magnify
    delaunaytris = texture2DLod(front, xy + (delaunayadj - 0.5) * (delaunay_mid - xy), 0.0).rgb;
  } else if(delaunaystyle == 5) { // Radial
    delaunaytris = vec3(alength(delaunay_mid - xy)) * delaunayadj;
  } else if(delaunaystyle == 6) { // Vertex Colours
    vec3 bary = barycentrics(xy, address2coords(tri.r), address2coords(tri.g), address2coords(tri.b));
    vec3 p0col = texture2DLod(front, address2coords(tri.r), delaunayadj).rgb;
    vec3 p1col = texture2DLod(front, address2coords(tri.g), delaunayadj).rgb;
    vec3 p2col = texture2DLod(front, address2coords(tri.b), delaunayadj).rgb;
    delaunaytris = bary.x * p0col + bary.y * p1col + bary.z * p2col;
  } else if(delaunaystyle == 7) { // Signed distance field
    delaunaytris = vec3(delaunay_sdf);
  } else if(delaunaystyle == 8) { // Barycentrics
    delaunaytris = delaunayadj * barycentrics(xy, address2coords(tri.r), address2coords(tri.g), address2coords(tri.b));
  } else if(delaunaystyle == 9) { // Mid offset
    delaunaytris.xy = delaunay_mid - xy;
    delaunaytris = mix(vec3(0.0), delaunaytris, delaunayadj);
  } else if(delaunaystyle == 10) { // Mid UVs
    delaunaytris.xy = delaunay_mid;
    delaunaytris = mix(vec3(xy, 0.0), delaunaytris, delaunayadj);
  } else if(delaunaystyle == 11) { // Mid colour
    delaunaytris = texture2DLod(front, delaunay_mid, delaunayadj).rgb;
  }
  delaunaytris *= delaunay_known;

  // Comp everything together
  vec4 o = vec4(0.0);
  if(voronoi) {
    o.rgb += voronoicells;
  }
  if(delaunay) {
    o.rgb += delaunaytris;
  }
  if(voronoi && delaunay) {
    o.rgb /= 2.0;
  }
  if(voronoiedges) {
    o.rgb = mix(o.rgb, voronoiedgecol, voronoi_edges * (1.0 - edgetrans/100.0));
  }
  if(delaunayedges) {
    o.rgb = mix(o.rgb, delaunayedgecol, delaunay_known * delaunay_edges * (1.0 - edgetrans/100.0));
  }
  if(seeddots) {
    o.rgb = mix(o.rgb, voronoiedgecol, seeddotty * (1.0 - edgetrans/100.0));
  }
  if(delaunay || delaunayedges) {
    o.a = delaunay_known;
  } else {
    o.a = seeddotty;
  }
  
  gl_FragColor = o;
}

