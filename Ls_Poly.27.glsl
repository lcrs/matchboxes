// Poly
// Pass 27: debug tings

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D front, adsk_results_pass1, adsk_results_pass13, adsk_results_pass14, adsk_results_pass26;
vec2 res = vec2(adsk_result_w, adsk_result_h);

float coords2address(vec2 c) {
  c *= res;
  c -= vec2(0.5);
  return c.y * adsk_result_w + c.x;
}

vec2 address2coords(float a) {
  if(a == -999.0) return vec2(0.0);
  vec2 c;
  c.y = floor(a / adsk_result_w);
  c.x = a - (c.y * adsk_result_w);
  return (c + vec2(0.5)) / res;
}

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
  vec4 f = texture2D(front, xy);
  vec4 p1 = texture2D(adsk_results_pass1, xy);
  vec4 p13 = texture2D(adsk_results_pass13, xy);
  vec4 p14 = texture2D(adsk_results_pass14, xy);
  vec4 p26 = texture2D(adsk_results_pass26, xy);
  
  //gl_FragColor = p14;
  //gl_FragColor = vec4(address2coords(408320.0), 0.0, 0.0);
  //gl_FragColor = vec4(address2coords(p14.r), 0.0, 0.0);
  
  float t1 = abs(sdTriangle(address2coords(p26.r), address2coords(p26.g), address2coords(p26.b), xy));
  t1 *= 400.0;
  gl_FragColor = vec4(t1, t1, t1, 0.0);
}
