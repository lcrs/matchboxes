// Flock pass 2: output positions only, otherwise black

uniform sampler2D adsk_results_pass1;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
float maxn = res.x * res.y;
uniform int count;

vec3 get(vec2 xy) {
  xy += vec2(0.5);
  xy /= res;
  return texture2D(adsk_results_pass1, xy).rgb;
}

void main() {
  vec2 xy = gl_FragCoord.xy - vec2(0.5);
  float n = xy.y * res.x + xy.x;

  bool isp = true;
  if(n > maxn / 2.0) {
    isp = false;
    xy.y = res.y - xy.y;
    n = xy.y * res.x + xy.x;
  }

  if(n > float(count)) {
    gl_FragColor = vec4(0.0);
    return;
  };

  if(isp) {
    gl_FragColor = vec4(get(xy), 1.0);
  } else {
    gl_FragColor = vec4(0.0);
  }
}
