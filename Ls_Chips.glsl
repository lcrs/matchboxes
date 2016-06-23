// Chips: show colour chips with names
// lewis@lewissaunders.com
// TODO:
//  o extract kerning pair metrics from the Source Sans font and try to use them?

#version 120
#extension GL_ARB_shader_texture_lod : enable

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D front, adsk_texture_grid;
uniform vec2 chip1pos, chip2pos, chip3pos;
uniform vec3 chip1col, chip2col, chip3col;
uniform bool chip1nearest, chip2nearest, chip3nearest;
uniform float blockup;
uniform bool showblocky;
uniform bool voronoi;

vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 xy = gl_FragCoord.xy / res;

// Widths for each ASCII character, generated by /obj/font/charwidths in Ls_Chips.hip Houdini scene
const float charwidths[] = float[](0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.000000, 0.013000, 0.005811, 0.013125, 0.028232, 0.024609, 0.049561, 0.035957, 0.003486, 0.010869, 0.010869, 0.017432, 0.028096, 0.007998, 0.015039, 0.005811, 0.023447, 0.026113, 0.022832, 0.026934, 0.027207, 0.029531, 0.027686, 0.026250, 0.026865, 0.027139, 0.026182, 0.005811, 0.007998, 0.028096, 0.028096, 0.028096, 0.021533, 0.048603, 0.034863, 0.029805, 0.032266, 0.030898, 0.025361, 0.024541, 0.032676, 0.030420, 0.003145, 0.022285, 0.030830, 0.023926, 0.035000, 0.030215, 0.037119, 0.027686, 0.037256, 0.028574, 0.029668, 0.031855, 0.030352, 0.033018, 0.048672, 0.030625, 0.030146, 0.030078, 0.010938, 0.023516, 0.010938, 0.023721, 0.032539, 0.011484, 0.024199, 0.027344, 0.025362, 0.027344, 0.026865, 0.017431, 0.028985, 0.024268, 0.005469, 0.012920, 0.024609, 0.006221, 0.043477, 0.024268, 0.029463, 0.027344, 0.027344, 0.015654, 0.023105, 0.018662, 0.024063, 0.028027, 0.043545, 0.025908, 0.028164, 0.023994, 0.015244, 0.002461, 0.015244, 0.027207, 0.000000);

// Retrieves a colour from index i
vec3 getcol(int i) {
  vec2 uv;
  uv.y = float(i);
  uv.x = 0.0;
  uv += 0.5;
  uv /= 1024.0;
  vec3 texel = texture2D(adsk_texture_grid, uv).gba;
  return texel;
}

// Retrieves i'th character code from string at index s
int getch(int s, int i) {
  vec2 uv;
  uv.y = float(s);
  uv.x = float(i + 1);
  uv += 0.5;
  uv /= 1024.0;
  float texel = texture2D(adsk_texture_grid, uv).g;
  return int(texel);
}

// Returns contribution of string from index s at position where
float print(int s, vec2 where) {
  if(s == -1) {
    return 0.0;
  }

  float tracking = 0.011;
  vec2 stringuv = (xy - where) * 4.5;
  if(stringuv.x < 0.0 || stringuv.y > 0.1 || stringuv.y < 0.0) return 0.0;

  // Which character are we in?  Sum widths of characters in string left to right
  // until we overtake current position
  int thischaridx = -1;
  int thischar = -1;
  float prevcharswidth = 0.0;
  for(int i = 0; i < 40; i++) {
    thischar = getch(s, i);
    if(thischar == 0) break; // End of string, they're null terminated in the texture
    float thischarwidth = (charwidths[thischar] + tracking) / adsk_result_frameratio;
    prevcharswidth += thischarwidth;
    if(prevcharswidth > stringuv.x) {
      thischaridx = i;
      prevcharswidth -= thischarwidth;
      break;
    }
  }

  // Give up if we're off the end of the string
  if(thischaridx == -1) return 0.0;

  // Where are we in the character?
  vec2 charuv = stringuv - vec2(prevcharswidth, 0.0);
  charuv.x *= adsk_result_frameratio;

  // Where is that in the font texture?
  int nth = thischar - 32;
  int row = nth / 10;
  int col = nth - (row * 10);
  vec2 charorigin = vec2(col, row) / 10.0;
  charorigin.x += 0.021;
  vec2 fontuv = charorigin + charuv;

  // Look up the SDF and step to it for antialiasing
  float sdf = texture2D(adsk_texture_grid, fontuv).r;
  float aa = 1.0 - smoothstep(0.0, 4.0, sdf);

  return aa;
}

// Return the index of the colour closest to col
int bestcol(vec3 col) {
  int best = -1;
  float lowest = 999.0;
  for(int i = 0; i < 213; i++) {
    float dist = length(col - getcol(i));
    if(dist < lowest) {
      lowest = dist;
      best = i;
    }
  }
  return best;
}

// Transform into UV coords in a chip rectangle
vec2 rectuv(vec2 origin, vec2 size) {
  return (xy - origin) / size;
}

// Return signed distance to rectangle
float rectsdf(vec2 origin, vec2 size) {
  vec2 d = max(origin - xy, xy - origin - size);
  d.x *= adsk_result_frameratio;
  return length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y));
}

// Return contribution of a ring
float ring(vec2 origin, float size, float thick) {
  vec2 to = xy - origin;
  to.x *= adsk_result_frameratio;
  float len = length(to);
  return smoothstep(size-thick, size+thick, len) * (1.0 - smoothstep(size-thick, size+thick, len));
}

void main() {
  vec3 bg = texture2D(front, xy).rgb;
  if(showblocky) {
    bg = texture2DLod(front, xy, blockup + 0.4).rgb;
  }

  vec4 chips = vec4(0.0);
  vec2 voronoi_pos[3];
  vec3 voronoi_col[3];

  for(int i = 0; i < 3; i++) {
    vec2 pos = chip1pos;
    vec3 col = chip1col;
    bool nearest = chip1nearest;
    if(i == 1) {
      pos = chip2pos;
      col = chip2col;
      nearest = chip2nearest;
    }
    if(i == 2) {
      pos = chip3pos;
      col = chip3col;
      nearest = chip3nearest;
    }

    vec3 pickcol = texture2DLod(front, pos, blockup + 0.4).rgb;
    int bestcolidx;
    vec3 bestcol;
    if(nearest) {
      bestcolidx = bestcol(pickcol);
      bestcol = getcol(bestcolidx);
    } else {
      bestcolidx = -1;
      bestcol = pickcol;
    }

    if(voronoi) {
      voronoi_pos[i] = pos;
      voronoi_col[i] = bestcol;
    }

    vec2 chipsize = vec2(0.07, 0.07 * adsk_result_frameratio);
    vec2 origin = pos + vec2(0.018, -chipsize.y + 0.014);
    float tagmatte = 1.0 - smoothstep(0.2, 0.201, rectuv(origin, chipsize).y);
    vec3 tagcol = vec3(0.9);
    vec3 fill = mix(bestcol, tagcol, tagmatte);

    float name = print(bestcolidx, origin + vec2(0.00, 0.00));
    fill = mix(fill, vec3(0.0), name);

    float rectmatte = 1.0 - smoothstep(0.003, 0.004, rectsdf(origin, chipsize));
    float bridgematte = 1.0 - smoothstep(0.0, 0.001, rectsdf(origin + vec2(-0.014, chipsize.y - 0.015), vec2(0.016, 0.0025)));
    float matte = rectmatte + bridgematte - (bridgematte * rectmatte);
    float ringmatte = clamp(0.0, 1.0, 16.0 * ring(origin + vec2(-0.018, chipsize.y - 0.014), 0.008, 0.002));
    matte = matte + ringmatte - (ringmatte * matte);

    //float shadow = smoothstep(0.0, 0.4, roundedrect(origin + vec2(0.007, 0.0), chipsize * vec2(0.9, 1.1)));
    //float sdf = rectsdf(origin + vec2(0.0, 0.0), chipsize * vec2(1.0, 1.0));
    //float shadow = smoothstep(0.0, 0.1, sdf);
    //shadow = 1.0 - shadow;
    //if(voronoi) shadow = 0.0;

    fill *= matte;
    chips = chips * (1.0 - matte) + vec4(fill, matte);
  }

  if(voronoi) {
    vec3 accum = vec3(0.0);
    float samples = 0.0;
    for(float sx = -0.5; sx <= 0.5; sx += 0.3333) {
      for(float sy = -0.5; sy <= 0.5; sy += 0.3333) {
        vec2 ixy = xy + (vec2(sx, sy) / res);
        float closest = 999.0;
        vec3 col = vec3(0.0);
        for(int i = 0; i < 3; i++) {
          float dist = length(ixy - voronoi_pos[i]);
          if(dist < closest) {
            closest = dist;
            col = voronoi_col[i];
          }
        }
        accum += col;
        samples++;
      }
    }
    bg = accum / samples;
  }

  vec3 comped = bg * (1.0 - chips.a) + chips.rgb;

  gl_FragColor = vec4(comped, chips.a);
}
