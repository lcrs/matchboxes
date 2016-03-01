// Flock pass 1
// This simulates flocking by storing positions and velocities
// in pixel colours.  On each frame the previous frame's p and v
// are read, modified and output again.  The ID of each point in
// the flock is kept as xy 2D coordinates, to avoid precision
// problems resolving that to a single integer

uniform sampler2D adsk_accum_texture;
uniform bool adsk_accum_no_prev_frame;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
float maxn = res.x * res.y;
uniform int count;

uniform float startv, startrand;
uniform vec3 startdir;
uniform float attractradius, attract;
uniform float repelradius, repel;
uniform float followradius, follow;
uniform float strayradius, stray;
uniform float speedlimit;

float rand(vec2 co) {
  return 2.0 * fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453) - 1.0;
}

// Begin ashima's noise...
// Description : Array and textureless GLSL 2D/3D/4D simplex
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License.
//               https://github.com/ashima/webgl-noise
/* Copyright (C) 2011 by Ashima Arts (Simplex noise)
   Copyright (C) 2011 by Stefan Gustavson (Classic noise)
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE. */

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0; }

float mod289(float x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0; }

vec4 permute(vec4 x) {
     return mod289(((x*34.0)+1.0)*x);
}

float permute(float x) {
     return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float taylorInvSqrt(float r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

vec4 grad4(float j, vec4 ip)
  {
  const vec4 ones = vec4(1.0, 1.0, 1.0, -1.0);
  vec4 p,s;

  p.xyz = floor( fract (vec3(j) * ip.xyz) * 7.0) * ip.z - 1.0;
  p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
  s = vec4(lessThan(p, vec4(0.0)));
  p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www;

  return p;
  }

// (sqrt(5) - 1)/4 = F4, used once below
#define F4 0.309016994374947451

float snoise(vec4 v)
  {
  const vec4  C = vec4( 0.138196601125011,  // (5 - sqrt(5))/20  G4
                        0.276393202250021,  // 2 * G4
                        0.414589803375032,  // 3 * G4
                       -0.447213595499958); // -1 + 4 * G4

// First corner
  vec4 i  = floor(v + dot(v, vec4(F4)) );
  vec4 x0 = v -   i + dot(i, C.xxxx);

// Other corners

// Rank sorting originally contributed by Bill Licea-Kane, AMD (formerly ATI)
  vec4 i0;
  vec3 isX = step( x0.yzw, x0.xxx );
  vec3 isYZ = step( x0.zww, x0.yyz );
//  i0.x = dot( isX, vec3( 1.0 ) );
  i0.x = isX.x + isX.y + isX.z;
  i0.yzw = 1.0 - isX;
//  i0.y += dot( isYZ.xy, vec2( 1.0 ) );
  i0.y += isYZ.x + isYZ.y;
  i0.zw += 1.0 - isYZ.xy;
  i0.z += isYZ.z;
  i0.w += 1.0 - isYZ.z;

  // i0 now contains the unique values 0,1,2,3 in each channel
  vec4 i3 = clamp( i0, 0.0, 1.0 );
  vec4 i2 = clamp( i0-1.0, 0.0, 1.0 );
  vec4 i1 = clamp( i0-2.0, 0.0, 1.0 );

  //  x0 = x0 - 0.0 + 0.0 * C.xxxx
  //  x1 = x0 - i1  + 1.0 * C.xxxx
  //  x2 = x0 - i2  + 2.0 * C.xxxx
  //  x3 = x0 - i3  + 3.0 * C.xxxx
  //  x4 = x0 - 1.0 + 4.0 * C.xxxx
  vec4 x1 = x0 - i1 + C.xxxx;
  vec4 x2 = x0 - i2 + C.yyyy;
  vec4 x3 = x0 - i3 + C.zzzz;
  vec4 x4 = x0 + C.wwww;

// Permutations
  i = mod289(i);
  float j0 = permute( permute( permute( permute(i.w) + i.z) + i.y) + i.x);
  vec4 j1 = permute( permute( permute( permute (
             i.w + vec4(i1.w, i2.w, i3.w, 1.0 ))
           + i.z + vec4(i1.z, i2.z, i3.z, 1.0 ))
           + i.y + vec4(i1.y, i2.y, i3.y, 1.0 ))
           + i.x + vec4(i1.x, i2.x, i3.x, 1.0 ));

// Gradients: 7x7x6 points over a cube, mapped onto a 4-cross polytope
// 7*7*6 = 294, which is close to the ring size 17*17 = 289.
  vec4 ip = vec4(1.0/294.0, 1.0/49.0, 1.0/7.0, 0.0) ;

  vec4 p0 = grad4(j0,   ip);
  vec4 p1 = grad4(j1.x, ip);
  vec4 p2 = grad4(j1.y, ip);
  vec4 p3 = grad4(j1.z, ip);
  vec4 p4 = grad4(j1.w, ip);

// Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  p4 *= taylorInvSqrt(dot(p4,p4));

// Mix contributions from the five corners
  vec3 m0 = max(0.6 - vec3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.0);
  vec2 m1 = max(0.6 - vec2(dot(x3,x3), dot(x4,x4)            ), 0.0);
  m0 = m0 * m0;
  m1 = m1 * m1;
  return 49.0 * ( dot(m0*m0, vec3( dot( p0, x0 ), dot( p1, x1 ), dot( p2, x2 )))
               + dot(m1*m1, vec2( dot( p3, x3 ), dot( p4, x4 ) ) ) ) ;

}
// ...end ashima's noise

vec3 get(vec2 xy) {
  xy += vec2(0.5);
  xy /= res;
  return texture2D(adsk_accum_texture, xy).rgb;
}

vec3 p(vec2 xy) {
  return get(xy);
}

vec3 v(vec2 xy) {
  xy.y = res.y - xy.y;
  return get(xy);
}

void main() {
  vec2 xy = gl_FragCoord.xy - vec2(0.5);
  float n = xy.y * res.x + xy.x;

  bool isp = true;
  if(n > maxn / 2.0) {
    isp = false;
    xy.y = res.y - xy.y;
    n = xy.y * res.x + xy.x;
  }

  if(n > float(count)) discard;

  if(adsk_accum_no_prev_frame) {
    if(isp) {
      gl_FragColor.x = 400.0 * snoise(vec4(xy*1.234567, 1.0, 1.0));
      gl_FragColor.y = 400.0 * snoise(vec4(xy*7.654321, 2.0, 1.0));
      gl_FragColor.z = 0.0;
    } else {
      vec3 v = startrand * vec3(rand(xy/res * 2.1), rand(xy/res * 11.5), rand(xy/res * 4.2));
      v += startdir * startv;
      gl_FragColor.xyz = v;
    }
    return;
  }

  vec3 oldp = p(xy);
  vec3 oldv = v(xy);
  vec3 newp = oldp;
  vec3 newv = oldv;
  for(vec2 i = vec2(0.0); i.y * res.x + i.x < float(count); i.x += 1.0) {
    vec3 thisp = p(i);
    vec3 thisv = v(i);
    vec3 to = thisp - oldp;
    float l = length(to);
    float weight;

    weight = 1.0 - smoothstep(0.0, attractradius, l);
    newv += to * weight * attract/1000.0;

    weight = 1.0 - smoothstep(0.0, repelradius, l);
    newv += -to * weight * repel/1000.0;

    weight = 1.0 - smoothstep(0.0, followradius, l);
    newv += thisv * weight * follow/1000.0;

    if(i.x >= res.x) {
      i.x = 0.0;
      i.y += 1.0;
    }
  }

  if(length(newv) > speedlimit) {
    newv = normalize(newv) * speedlimit;
  }

  float strayed = max(0.0, length(oldp) - strayradius);
  strayed = smoothstep(0.0, 100.0, strayed);
  newv += strayed * -normalize(oldp) * stray;

  newp = oldp + newv;

  if(isp) {
    gl_FragColor = vec4(newp, 1.0);
  } else {
    gl_FragColor = vec4(newv, 1.0);
  }
}
