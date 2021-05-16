// Vignette
// lewis@lewissaunders.com

uniform float adsk_result_w, adsk_result_h;
uniform float adsk_result_frameratio;
uniform vec3 edgetint, midtint;
uniform vec2 centre;
uniform float radius, mixamt, abruptness, aspect;
uniform sampler2D front;
uniform bool clampblack, applyoffset;

// S-shaped function with variable steepness s
// Maps 0..1 to 0..1
float smoothishstep(float x, float s) {
  if(x < 0.5) {
    return 0.5*((s*2.0*x - 2.0*x)/(2.0*s*2.0*x - s - 1.0));
  } else {
    float z = x - 0.5;
    float t = -s;
    return 0.5*((t*2.0*z - 2.0*z)/(2.0*t*2.0*z - t - 1.0)) + 0.5;
  }
}

void main() {
  vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
  vec3 f = texture2D(front, uv).rgb;
  
  vec2 tocent = uv - centre;
  tocent.x *= adsk_result_frameratio;
  tocent.x *= aspect;
  float rad = length(tocent);
  rad /= radius;
  float v = pow(cos(clamp(rad, 0.0, 3.1415926535/2.0)), 4.0);
  v = smoothishstep(v, abruptness);

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

  o = mix(f, o, mixamt);

  if(clampblack) {
    o = clamp(o, 0.0, 999999.0);
  }
  
  float m = v;
  m = mix(1.0, m, mixamt);

  gl_FragColor = vec4(o, m);
}
