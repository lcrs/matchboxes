// Sweat, pass 2: read drop simulation state from pixel colours, do the
// metaball maths, render height map of drops
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform float blobfactor, trim, shoulder, curvetop, irreg;
uniform int drops;

float snoise(vec4 v);

float noiz(float a, float b, float c, float d) {
  return snoise(vec4(a, b, c, d)) + 0.5;
}

void main() {
  vec2 res = vec2(adsk_result_w, adsk_result_h);
  vec2 xy = gl_FragCoord.xy;

  // Warp space a bit before we do this to get more interesting shapes
  vec2 n = xy / 70.0;
  xy.x += irreg * (noiz(n.x, n.y, 11.0, 12.0) - 0.5);
  xy.y += irreg * (noiz(n.x, n.y, 11.0, 13.0) - 0.5);
  n = xy / 30.0;
  xy.x += irreg * 0.2 * (noiz(n.x, n.y, 14.0, 12.0) - 0.5);
  xy.y += irreg * 0.2 * (noiz(n.x, n.y, 14.0, 13.0) - 0.5);

  // We loop over all drops, evaluating and accumulating a Gaussian function
  // centred on each, in a pretty classic "metaball" way
  // We keep results based on both distance to edge of drop and
  // distance to centre of drop, which is softer
  float metaballedges = 0.0;
  float metaballcentres = 0.0;
  for(float i = 0.5; i < float(drops); i+=1.0) {
    // Get this drop's info from the accumulation texture
    vec4 drop = texture2D(adsk_results_pass1, vec2(i, 0.5)/res);
    vec2 droppos = drop.rg;
    float dropsize = drop.b;
    
    // Compute the distance to this drop, and the value of its metaball
    // falloff at this pixel
    vec2 here2drop = (xy/res) - droppos;
    here2drop.x *= adsk_result_frameratio;
    
    float distance2drop = length(here2drop);
    float metaballfunc = pow(2.718281828, (-1000.0/blobfactor) * pow(distance2drop, 2.0));
    metaballcentres += metaballfunc;
        
    float distance2edge = max(distance2drop - dropsize, 0.0);
    metaballfunc = pow(2.718281828, (-2000.0/blobfactor) * pow(distance2edge, 2.0));
    metaballedges += metaballfunc;
  }
 
  // Carve out a range from the complete metaball field and shape it
  metaballedges -= trim;
  metaballedges /= shoulder;
  metaballedges = clamp(metaballedges, 0.0, 1.0);
  metaballedges = sqrt(1.0 - pow(1.0 - metaballedges, 2.0)); // Quarter-circle curve LUT
  
  // Combine with the softer drop-centres field
  metaballcentres = clamp(metaballcentres, 0.0, 100.0);
  metaballcentres *= clamp(metaballedges * 3.0, 0.0, 1.0);
  float h = mix(metaballedges, metaballcentres, curvetop);
  
  // Spatters texture, held out by drops
  float s = texture2D(adsk_results_pass1, xy/res).a;
  s *= 1.0 - clamp(metaballedges * 3.0, 0.0, 1.0);
  h += s;
  
  gl_FragColor = vec4(h, h, h, s);
}













// ==============================================================================
// ==================== Begin ashima's noise ====================================
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
// ==================== ...end ashima's noise ===================================
// ==============================================================================
