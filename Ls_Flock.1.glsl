uniform sampler2D adsk_accum_texture;
uniform bool adsk_accum_no_prev_frame;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
float maxn = res.x * res.y;
const int count = 7000;

float rand(vec2 co) {
  return 2.0 * fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453) - 1.0;
}

vec3 get(vec2 xy) {
  xy /= res;
  return texture2D(adsk_accum_texture, xy).rgb;
}

vec3 p(vec2 xy) {
  return get(xy);
}

vec3 v(vec2 xy) {
  xy.y = res.y - xy.y;
  return get(xy);
}

void main() {
  vec2 xy = gl_FragCoord.xy;
  float n = xy.y * res.x + xy.x;

  bool isp = true;
  if(n > maxn / 2.0) {
    isp = false;
    xy.y = res.y - xy.y;
    n = xy.y * res.x + xy.x;
  }

  if(n > float(count)) discard;

  if(adsk_accum_no_prev_frame) {
    if(isp) {
      gl_FragColor.xyz = 400.0 * vec3(rand(xy/res * 1.0), rand(xy/res * 3.5), rand(xy/res * 9.2));
    } else {
      gl_FragColor.xyz = 1.0 * vec3(rand(xy/res * 2.1), rand(xy/res * 11.5), rand(xy/res * 4.2));
    }
    return;
  }

  vec3 oldp = p(xy);
  vec3 oldv = v(xy);
  vec3 newp = oldp;
  vec3 newv = oldv;
  for(vec2 i = vec2(0.0); i.y * res.x + i.x < float(count); i.x += 1.0) {
    vec3 thisp = p(i);
    vec3 thisv = v(i);
    if(length(oldp - thisp) < 200.0) {
      newp = mix(oldp, thisp, 0.1);
    }
    newp += oldv;

    if(i.x >= res.x) {
      i.x = 0.0;
      i.y += 1.0;
    }
  }

  if(isp) {
    gl_FragColor = vec4(newp, 1.0);
  } else {
    gl_FragColor = vec4(newv, 1.0);
  }
}
