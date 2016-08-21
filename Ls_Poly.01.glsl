// Poly
// Pass 1: create seed points from input video

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
