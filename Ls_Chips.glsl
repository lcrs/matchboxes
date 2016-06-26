/* Chips: show colour chips with names
   lewis@lewissaunders.com

   TODO:
    o extract kerning pair metrics from the Source Sans font and try to use them?

   This probably deserves some explanation.  We pick colours from the input, find which
   colour in our dictionary is closest, then draw colour chips including text.  The
   grid texture image holds the colours, their names stored as character codes in pixel
   colours, and a texture atlas containing signed distance field characters.
*/


#version 120
#extension GL_ARB_shader_texture_lod : enable

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio;
uniform sampler2D front, adsk_texture_grid;
uniform vec2 chip1pos, chip2pos, chip3pos;
uniform vec3 chip1col, chip2col, chip3col;
uniform bool chip1nearest, chip2nearest, chip3nearest;
uniform float blockup;
uniform bool showblocky, voronoi, palette;

vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 xy = gl_FragCoord.xy / res;

// Widths for each ASCII character, generated by /obj/font/charwidths in Ls_Chips.hip Houdini scene
const float charwidths[] = float[](0.013000, 0.005811, 0.013125, 0.028232, 0.024609, 0.049561, 0.035957, 0.003486, 0.010869, 0.010869, 0.017432, 0.028096, 0.007998, 0.015039, 0.005811, 0.023447, 0.026113, 0.022832, 0.026934, 0.027207, 0.029531, 0.027686, 0.026250, 0.026865, 0.027139, 0.026182, 0.005811, 0.007998, 0.028096, 0.028096, 0.028096, 0.021533, 0.048603, 0.034863, 0.029805, 0.032266, 0.030898, 0.025361, 0.024541, 0.032676, 0.030420, 0.003145, 0.022285, 0.030830, 0.023926, 0.035000, 0.030215, 0.037119, 0.027686, 0.037256, 0.028574, 0.029668, 0.031855, 0.030352, 0.033018, 0.048672, 0.030625, 0.030146, 0.030078, 0.010938, 0.023516, 0.010938, 0.023721, 0.032539, 0.011484, 0.024199, 0.027344, 0.025362, 0.027344, 0.026865, 0.017431, 0.028985, 0.024268, 0.005469, 0.012920, 0.024609, 0.006221, 0.043477, 0.024268, 0.029463, 0.027344, 0.027344, 0.015654, 0.023105, 0.018662, 0.024063, 0.028027, 0.043545, 0.025908, 0.028164, 0.023994, 0.015244, 0.002461, 0.015244, 0.027207, 0.000000);

// Global string buffer, used for all string operations
// This avoids using any other arrays, which... slow
int str[20];

// Fills global str with char codes from string at row, col in texture grid
void getstr(int row, int col) {
  if(row == -1) {
    str[0] = 0;
    return;
  }
  for(int i = 0; i < 20; i++) {
    vec2 uv;
    uv.y = float(row);
    // Columns are 25px wide, and skip the first pixel in each
    uv.x = float(col * 25 + i + 1);
    uv += 0.5; // Sample texel centres!
    uv /= 1024.0;
    float texel = texture2D(adsk_texture_grid, uv).g;
    str[i] = int(texel);
    if(texel == 0.0) break;
  }
}

// Return character codes for a number
int[3] float2char(float f) {
  int hundreds = int(floor(f / 100.0));
  int tens = int(floor((f - hundreds * 100.0) / 10.0));
  int units = int(mod(f,  10.0));
  hundreds += 48;
  tens += 48;
  units += 48;
  // We can use char code 127 as a zero-width nothing
  if(hundreds == 48) hundreds = 127;
  if(hundreds == 127 && tens == 48) tens = 127;
  return int[](hundreds, tens, units);
}

// Build a string of decimal RGB values for color c
void rgbstr(vec3 c) {
  str[0] = 115; // 'sRGB: '
  str[1] = 82;
  str[2] = 71;
  str[3] = 66;
  str[4] = 58;
  str[5] = 32;
  int red[3] = float2char(c.r * 255.0);
  int green[3] = float2char(c.g * 255.0);
  int blue[3] = float2char(c.b * 255.0);
  str[6] = red[0];
  str[7] = red[1];
  str[8] = red[2];
  str[9] = 32;
  str[10] = green[0];
  str[11] = green[1];
  str[12] = green[2];
  str[13] = 32;
  str[14] = blue[0];
  str[15] = blue[1];
  str[16] = blue[2];
  str[17] = 0;
}

// Return character code for the hexadecimal digit
// corresponding to decimal number d
int dec2hex(float d) {
  int r;
  if(d > 9.0) {
    r = int(d) + 55;
  } else {
    r = int(d) + 48;
  }
  if(r == 64) r = 57; // Compensate for mod() problems
  return r;
}

// Build a hex string for color c
void hexstr(vec3 c) {
  c *= 255.0;
  str[0] = 35; // '#'
  str[1] = dec2hex(floor(c.r / 16.0));
  str[2] = dec2hex(mod(c.r, 16.0));
  str[3] = dec2hex(floor(c.g / 16.0));
  str[4] = dec2hex(mod(c.g, 16.0));
  str[5] = dec2hex(floor(c.b / 16.0));
  str[6] = dec2hex(mod(c.b, 16.0));
  str[7] = 0;
}

// Build a single character string for a decimal
void decstr(int i) {
  str[0] = i + 48;
  str[1] = 0;
}

// Returns contribution of global string buffer printed at position 'where'
float print(vec2 where, float size) {
  if(str[0] == 0) {
    return 0.0;
  }

  float tracking = 0.011;
  vec2 stringuv = (xy - where) * (5.5 - size) * (1.77777 / adsk_result_frameratio);
  if(stringuv.x < 0.0 || stringuv.y > 0.1 || stringuv.y < 0.0) return 0.0;

  // Which character are we in?  Sum widths of characters in string left to right
  // until we overtake current position
  int thischaridx = -1;
  int thischar = -1;
  float prevcharswidth = 0.0;
  for(int i = 0; i < 20; i++) {
    thischar = str[i];
    if(thischar == 0) break; // End of string, they're null terminated in the texture
    float thischarwidth = (charwidths[thischar - 32] + tracking) / adsk_result_frameratio;
    if(thischar == 127) thischarwidth = 0.0; // Zero-width dummy character
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
  float aa = 1.0 - smoothstep(0.5, 4.5, sdf);

  return aa;
}

// Retrieves a colour from the texture grid
vec3 getcol(int row, int col) {
  vec2 uv;
  uv.y = float(row);
  uv.x = float(col * 25.0); // Columns 25px wide
  uv += 0.5; // Sample texel centres
  uv /= 1024.0;
  vec3 texel = texture2D(adsk_texture_grid, uv).gba;
  return texel;
}

// Return the row and col of the dictionary colour closest to c
ivec2 bestcol(vec3 c) {
  int best = -1;
  float lowest = 999.0;
  // In the grid texture, the colours are binned into 40
  // columns by green value.  There's overlap between
  // what's in adjacent columns, so we only need to search in
  // one of them
  int col = int(c.g * 39.0);
  for(int i = 0; i < 101; i++) {
    float dist = length(c - getcol(i, col));
    if(dist < lowest) {
      lowest = dist;
      best = i;
    }
  }
  return ivec2(best, col);
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

// Return colour from palette at uv
vec3 getpalette(vec2 uv) {
  int row = int(floor(uv.y * 27.0));
  int col = int(floor(uv.x * 38.0));
  int i = row * 38 + col;
  vec2 st = vec2((i + 0.5) / 1024.0, 1.0);
  return texture2D(adsk_texture_grid, st).gba;
}

void main() {
  vec3 bg;
  if(palette) {
    bg = getpalette(xy);
  } else {
    float lod = 0.0;
    if(showblocky) lod = blockup + 0.4;
    bg = texture2DLod(front, xy, lod).rgb;
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

    if(pos != clamp(pos, -0.05, 1.05)) {
      // Way off screen, make sure this chip isn't used for voronoi
      voronoi_pos[i] = vec2(10.0);
      voronoi_col[i] = vec3(0.0);
      continue;
    }

    vec3 pickcol;
    if(palette) {
      pickcol = getpalette(pos);
    } else {
      pickcol = texture2DLod(front, pos, blockup + 0.4).rgb;
    }
    // Use override colour pot if it's not negative
    if(min(col.r, min(col.g, col.b)) > -0.01) pickcol = col;

    ivec2 bestcolidx = bestcol(pickcol);
    vec3 bestcol = getcol(bestcolidx.x, bestcolidx.y);
    if(!nearest) {
      if(bestcol != pickcol) bestcolidx = ivec2(-1, -1);
      bestcol = pickcol;
    }

    vec2 chipsize = vec2(0.08, 0.09 * adsk_result_frameratio);
    vec2 origin = pos + vec2(0.003, -chipsize.y-0.005);
    origin = max(origin, vec2(0.01, 0.01 * adsk_result_frameratio));
    origin = min(origin, vec2(0.99 - chipsize.x, 1.0 - 0.01 * adsk_result_frameratio - chipsize.y));
    vec2 chiptopleft = origin - vec2(0.003, -chipsize.y-0.005);

    if(voronoi) {
      voronoi_pos[i] = pos + vec2(chipsize.x, -chipsize.y)/2.0;
      voronoi_col[i] = bestcol;
    }

    vec3 fill = vec3(0.0);
    vec2 chipuv = rectuv(origin, chipsize);
    if(clamp(chipuv, -0.2, 1.2) == chipuv) {
      // We're inside the chip
      float tagmatte = 1.0 - smoothstep(0.3333, 0.33334, chipuv.y);
      vec3 tagcol = vec3(0.9);
      fill = mix(bestcol, tagcol, tagmatte);

      if(bestcolidx.x != -1) {
        getstr(bestcolidx.x, bestcolidx.y);
      } else {
        hexstr(bestcol);
      }
      float p = print(origin + vec2(0.00, 0.025), 1.0);
      fill = mix(fill, vec3(0.0), p);
      rgbstr(bestcol);
      p = print(origin + vec2(0.00, 0.01), -1.0);
      fill = mix(fill, vec3(0.4), p);
      decstr(i+1);
      p = print(origin + vec2(0.077, -0.002), -1.0);
      fill = mix(fill, vec3(0.4), p);
    }

    float rectmatte = 1.0 - smoothstep(0.005, 0.006, rectsdf(origin, chipsize));
    float cornermatte = 1.0 - smoothstep(0.0, 0.001, rectsdf(chiptopleft + vec2(0.0003, -0.02), vec2(0.02)));
    float matte = rectmatte + cornermatte - (cornermatte * rectmatte);

    float shadow = 1.0 - smoothstep(0.0, 0.1, rectsdf(origin, chipsize));
    shadow = pow(shadow, 4.0) * 0.75;
    float radial = smoothstep(0.0, 0.4, length((xy - chiptopleft) * vec2(adsk_result_frameratio, 1.0)));
    if(voronoi) {
      shadow = pow(shadow, 4.0) * 0.66;
    } else {
      shadow *= radial;
    }

    fill *= matte;
    matte = matte + shadow - (matte * shadow);
    chips = chips * (1.0 - matte) + vec4(fill, matte);
  }

  // Supersampled voronoi diagram of the three colours/positions
  if(voronoi) {
    vec3 accum = vec3(0.0);
    float samples = 0.0;
    for(float sx = -0.5; sx <= 0.5; sx += 0.25) {
      for(float sy = -0.5; sy <= 0.5; sy += 0.25) {
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
