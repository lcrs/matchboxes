/*  Poly
    lewis@lewissaunders.com

    Create Voronoi diagrams and Deluanay triangulations from seed points in image by
    jump flooding, as per "Jump Flooding in GPU" paper
    http://www.comp.nus.edu.sg/~tants/jfa.html

    This was inspired by Tom Dobrowolski's shader, reading which was very instructive: 
    https://www.shadertoy.com/view/ldV3Wc

    TODO:
    o There are still occasional glitches and black triangles
    o Use 1+JFA instead of standard JFA?
    o Seed generation clusters a lot, could be more sophisticated
    o Does sdTriangle take into account anamorphicity of 0-1 texel coord space?
    o Trimming long thin triangles might help more than trimming small ones
    o Fake anchor points at image corners/edges?
    o Output dual of seeds, i.e. points at junctions of Voronoi diagram
    o Figure out if/why our distance transform output is inferior to OpenCV
    o Remove 4096.0 flood steps, since running at 8k uses impossible amount of VRAM?
    o Strength inputs which module scale/rotation of sprites/dots/edges/magnify modes

    Pass 1: create seed points from input video
*/

#extension GL_ARB_shader_texture_lod : enable

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D front, thresholdi;
uniform float seedthres;
uniform bool inputisseeds;
vec2 res = vec2(adsk_result_w, adsk_result_h);

void main() {
  vec2 xy = gl_FragCoord.xy / res;

  vec3 frontrgb = texture2D(front, xy).rgb;
  float frontluma = dot(frontrgb, vec3(0.2126, 0.7152, 0.0722));
  
  vec3 miprgb = texture2DLod(front, xy, 3.0).rgb;
  float mipluma = dot(miprgb, vec3(0.2126, 0.7152, 0.0722));
  
  float seedness = abs(frontluma - mipluma);

  if(inputisseeds) {
    seedness = frontluma;
  }

  vec4 o;
  float modulated_threshold = pow(seedthres, 3.0);
  modulated_threshold *= texture2D(thresholdi, xy).g;
  if(seedness > modulated_threshold) {
    // This is a seed pixel, output current coords
    o = vec4(xy, 0.0, 0.0);
  } else {
    // This is not a seed, we don't know the closest seed, output -999
    o = vec4(-999.0);
  }
  gl_FragColor = o;
}
