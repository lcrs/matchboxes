// Filmstrip
// Arranges input frames into a grid
// 
// lewis@lewissaunders.com

uniform float adsk_result_w, adsk_result_h, adsk_result_frameratio, adsk_result_pixelratio;
uniform float adsk_front_w, adsk_front_h, adsk_front_frameratio, adsk_front_pixelratio;
uniform sampler2D front;
uniform sampler2D adsk_accum_texture;
uniform bool adsk_accum_no_prev_frame;
uniform float adsk_time;
uniform float rows, cols;
uniform float xborder;
uniform bool preview;

void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 xy = gl_FragCoord.xy / res;
        
    xy.y = 1.0 - xy.y;
    
    vec2 border = vec2((xborder/1000.0), (xborder/1000.0) * adsk_result_frameratio);
    
    vec2 noframe = xy;
    noframe *= vec2(1.0) + 2.0 * border;
    noframe -= border;
    
    vec2 cellsize = vec2(1.0) / vec2(rows, cols);
    
    vec2 loc = floor(noframe / cellsize);
    float frame = loc.y * cols + loc.x;
    
    vec2 cell = noframe / cellsize;
    cell = mod(cell, 1.0);
    
    vec2 noborder = cell;
    noborder *= vec2(1.0) + 2.0 * (border / cellsize);
    noborder -= border / cellsize;
    
    vec4 a = texture2D(adsk_accum_texture, vec2(xy.x, 1.0 - xy.y));
    if(preview || adsk_time == frame + 1.0) {
        a = texture2D(front, vec2(noborder.x, 1.0 - noborder.y));
    }
    
    bool isborder = false;
    if(noborder.x < 0.0 || noborder.x > 1.0 || noborder.y < 0.0 || noborder.y > 1.0) {
        isborder = true;
    }
    if(loc.x >= cols || loc.x < 0.0 || loc.y >= rows || loc.y < 0.0) {
        isborder = true;
    }
    if(isborder) {
        a = vec4(0.0);
    }    
    
    gl_FragColor = a;
}
