// Poly
// Pass 1: create seed points from input video

/*
TODO:
o Arbitrary image sizes - hard code jump distances, probably, some jumps will read off the edge?
o Seed generation sucks - use max of 3x3 area? Mipmaps?
o Random colours seeded from coords
o Outlines? Outline-only mode?
o Shade cells radially, random angled gradients?
o AA - don't bother, FXAA looks ok?
o use 1+JFA instead of standard JFA?
o Delaunay... to draw the triangles, we need to know the seed coords of all surrounding cells...
  so we need to flood the seed coords from junction pixels
  only need to store the triangle we're inside
  so closest seed coord + 3 triangle coords
  on first step: output coords of right/down/diag pixels
  other steps: check if flooding triangles are closer than current
*/

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D front;
uniform float seedthres;

vec2 res = vec2(adsk_result_w, adsk_result_h);

void main() {
  vec2 xy = gl_FragCoord.xy / res;
  vec3 frontrgb = texture2D(front, xy).rgb;
  float frontluma = dot(frontrgb, vec3(0.2126, 0.7152, 0.0722));
  float localslope = length(vec2(dFdy(frontluma), dFdx(frontluma)));
  vec4 o;
  if(localslope > seedthres) {
    // This is a seed pixel, output current coords
    o = vec4(xy, 0.0, 0.0);
  } else {
    // This is not a seed, we don't know the closest seed, output -999
    o = vec4(-999.0);
  }
  gl_FragColor = o;
}
