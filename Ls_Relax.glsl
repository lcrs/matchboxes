// Relaxxxx
// This actually is mostly just mixing incoming pixels with
// the target colours, which is equivalent to a pivoted contrast
// sort of operator.  I really miss ContrastRGB from Shake, basically
// lewis@lewissaunders.com

uniform float adsk_result_w, adsk_result_h;
uniform vec3 mastercolour, shadowcolour, midtonecolour, highlightcolour;
uniform float mastercontrast, shadowtweak, midtonetweak, highlighttweak;
uniform float shadowrestore, highlightrestore;
uniform float midtonesat, mixx;
uniform bool showranges;
uniform sampler2D front, matte;

float adsk_getLuminance(vec3 rgb);
float adsk_highlights(float lum, float mid);
float adsk_shadows(float lum, float mid);

void main() {
  vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
  vec3 f = texture2D(front, uv).rgb;
  float m = texture2D(matte, uv).b;

  vec3 mastermisted = mix(f, mastercolour, 1.0 - mastercontrast);

  float fluma = adsk_getLuminance(f);
  float shadowness = adsk_shadows(fluma, mix(midtonesat, 0.0, 0.5));
  float highlightness = adsk_highlights(fluma, mix(midtonesat, 1.0, 0.5));
  float midtoneness = 1.0 - (shadowness + highlightness);

  vec3 shadowrestored = mix(mastermisted, f, shadowrestore * shadowness);
  vec3 restored = mix(shadowrestored, f, highlightrestore * highlightness);

  vec3 shadowtweaked = mix(restored, shadowcolour, shadowtweak);
  vec3 midtonetweaked = mix(restored, midtonecolour, midtonetweak);
  vec3 highlighttweaked = mix(restored, highlightcolour, highlighttweak);

  vec3 alltonestweaked = shadowness * shadowtweaked + midtoneness * midtonetweaked + highlightness * highlighttweaked;

  vec3 matted = mix(f, alltonestweaked, m * mixx);

  if(showranges) {
    matted = vec3(shadowness, midtoneness, highlightness);
  }

  gl_FragColor = vec4(matted, m);
}
