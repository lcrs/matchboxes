// Poly
//
// Create Voronoi diagrams and Deluanay triangulations from seed points in image
// We can also output the distance transform if seed points form contiguous shapes
//
// Uses jump flooding as per "Jump Flooding in GPU" paper
// http://www.comp.nus.edu.sg/~tants/jfa.html

// Pass 1: create seed points from input video

/*
  TODO:
  o use 1+JFA instead of standard JFA?
  o Seed generation clusters a lot leading to many small polys
  o Does sdTriangle take into account anamorphicity of 0-1 texel coord space?

  o fake anchor points at image corners/edges?
  
  o How can we outline voronoi cells other than by edge detection?
  o Shade cells radially, random angled gradients?
  o use vector to seed to render sprite from another input centered on each seed?
  o Output dual of seeds, i.e. points at junctions of Voronoi diagram
*/

#extension GL_ARB_shader_texture_lod : enable

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D front;
uniform float seedthres;
vec2 res = vec2(adsk_result_w, adsk_result_h);

void main() {
  vec2 xy = gl_FragCoord.xy / res;
  vec3 frontrgb = texture2D(front, xy).rgb;
  float frontluma = dot(frontrgb, vec3(0.2126, 0.7152, 0.0722));
  vec3 miprgb = texture2DLod(front, xy, 2.0).rgb;
  float mipluma = dot(miprgb, vec3(0.2126, 0.7152, 0.0722));
  float seedness = frontluma - mipluma;

  vec4 o;
  if(seedness > seedthres) {
    // This is a seed pixel, output current coords
    o = vec4(xy, 0.0, 0.0);
  } else {
    // This is not a seed, we don't know the closest seed, output -999
    o = vec4(-999.0);
  }
  gl_FragColor = o;
}
