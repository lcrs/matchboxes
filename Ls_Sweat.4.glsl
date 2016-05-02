// Sweat, pass 4: read UVs and distort the image
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass3, front;
uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform float distomult;
uniform int isamples;

void main() {
  vec2 res = vec2(adsk_result_w, adsk_result_h);
  vec2 xy = gl_FragCoord.xy;
  float h = texture2D(adsk_results_pass3, xy/res).b;

  // Multisampled UV mapping - read from the texture a bunch
  // of times and average to reduce noise.  This seems more effective
  // than EWA filtering a lot of the time and is much faster
  vec3 rgb;
  float samps = float(isamples);
  float spacing = 1.0 / (samps + 1.0);
  for(float i = 1.0; i <= samps; i++) {
    for(float j = 1.0; j <= samps; j++) {
      vec2 sample_xy = floor(gl_FragCoord.xy);
      sample_xy += vec2(i, j) * vec2(spacing);
      vec2 sample_uv = texture2D(adsk_results_pass3, sample_xy/res).rg;
      sample_uv *= distomult;
      sample_uv += xy/res;
      rgb += texture2D(front, sample_uv).rgb;
    }
  }
  rgb /= samps * samps;
  
  // Comp the distorted front over the clean one with a cropped in matte
  // This removes some horrible edges
  vec3 bg = texture2D(front, xy/res).rgb;
  float matte = clamp(pow((h * 2.0), 3.0), 0.0, 1.0);
  vec3 o = mix(bg, rgb, matte);
  
  gl_FragColor = vec4(o, h);
}
