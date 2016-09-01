// Poly
// Pass 1: create seed points from input video

/*
TODO:
o Seed generation clusters a lot leading to many small polys
o Need to account for aspect ratio in all distance calcs :(
o Outlines? Outline-only mode?
o Shade cells radially, random angled gradients?
o use 1+JFA instead of standard JFA?
o Delaunay... to draw the triangles, we need to know the seed coords of all surrounding cells...
  so we need to flood the seed coords from junction pixels
  only need to store the triangle we're inside
  so closest seed coord + 3 triangle coords
  on first step: output coords of right/down/diag pixels
  other steps: check if flooding triangles are closer than current
  idea: instead of passing around triangle corner coords, just pass
  the coords of the corner in the voronoi diagram that's the centre of the tri?
  the pixels around that coord will then give the three triangle corners?
*/

#extension GL_ARB_shader_texture_lod : enable

uniform float adsk_result_w, adsk_result_h;
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
