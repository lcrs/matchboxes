// Poly
// Pass 17: jump flood out addresses of closest seeds, round 2, distance 2048
// We check if the surrounding pixels tell us about triangles that are closer than our own

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D adsk_results_pass16;
vec2 res = vec2(adsk_result_w, adsk_result_h);

vec2 address2coords(float a) {
  vec2 c;
  c.y = floor(a / (adsk_result_w+50.0));
  c.x = a - (c.y * (adsk_result_w+50.0));
  return (c + vec2(0.5)) / res;
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

  vec4 bestseeds = vec4(-999.0);
  float bestdist = 99999.0;

  for(float j = -1.0; j <= 1.0; j += 1.0) {
    for(float k = -1.0; k <= 1.0; k += 1.0) {
      vec4 seeds = texture2D(adsk_results_pass16, xy + vec2(j, k) * (vec2(2048.0)/res));
      if(seeds.r < 0.0) {
        // This point doesn't know about any seeds yet
        continue;
      }
      float dist = sdTriangle(address2coords(seeds.r), address2coords(seeds.g), address2coords(seeds.b), xy);
      if(dist < bestdist) {
        bestseeds.rgba = seeds.rgba;
        bestdist = dist;
      }
      if(seeds.a >= 0.0) {
        // This point knows about 4 seeds, so there's another tri to check
        dist = sdTriangle(address2coords(seeds.r), address2coords(seeds.b), address2coords(seeds.a), xy);
        if(dist < bestdist) {
          bestseeds.rgba = seeds.barg; // This tri is flooded out in RGB, the other in RBA
          bestdist = dist;
        }
      }
    }
  }

  gl_FragColor = bestseeds;
}
