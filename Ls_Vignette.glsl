// Vignette
// lewis@lewissaunders.com

uniform float adsk_result_w, adsk_result_h;
uniform float adsk_result_frameratio;
uniform vec3 edgetint, midtint;
uniform vec2 centre;
uniform float radius, mix, abruptness, aspect;
uniform sampler2D front;
uniform bool clampblack, applyoffset;

void main() {
  vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
  vec3 f = texture2D(front, uv).rgb;
  
  vec2 tocent = uv - centre;
  tocent.x *= adsk_result_frameratio;
  tocent.x *= aspect;
  float rad = length(tocent);
  rad /= radius;
  float v = pow(cos(clamp(0.0, 3.1415926535/2.0, rad)), 4.0);
  // Do a kinda sigmoid thing for abruptness

  vec3 o;
  if(applyoffset) {
    o = f - 0.3333 * (1.0 - v);
    o = mix(o, o + (edgetint - vec3(0.5)), 1.0 - v);
    o = mix(o, o + (midtint - vec3(0.5)), v);
  } else {
    o = f * v;
    o = mix(o, o * (edgetint + vec3(0.5)), 1.0 - v);
    o = mix(o, o * (midtint + vec3(0.5)), v);
  }

  o = mix(f, o, mix);

  if(clampblack) {
    o = clamp(o, 0.0, 999999.0);
  }
  
  float m = v;
  m = mix(1.0, m, mix);

  gl_FragColor = vec4(o, m);
}
