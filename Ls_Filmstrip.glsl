// Filmstrip
// Arranges input frames into a grid
// 
// TODO: support output resolution being different from input... I'm so bad at this
// 
// lewis@lewissaunders.com

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D front;
uniform sampler2D adsk_accum_texture;
uniform bool adsk_accum_no_prev_frame;
uniform float rows, cols;
uniform float zoom;
uniform float adsk_time;

void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 xy = gl_FragCoord.xy;
    
    vec4 a = texture2D(adsk_accum_texture, xy / res);
    
    if(zoom < 1.0) {
        float bordersizey = (1.0 - zoom) * adsk_result_h;
        float bordersizex = (1.0 - zoom) * adsk_result_w;
        float excessx = bordersizex - bordersizey;
    }
    
    float rowheight = adsk_result_h / rows;
    float colwidth = adsk_result_w / cols;

    float row = floor((res.y - xy.y) / rowheight);
    float col = floor(xy.x / colwidth);
    float frame = (row * cols) + col;
    
    if(frame + 1.0 == adsk_time) {
        vec2 uv;
        uv.y = 1.0 - ((res.y - xy.y) - (row * rowheight)) / rowheight;
        uv.x = (xy.x - (col * colwidth)) / colwidth;
        
        uv-=0.5;
        uv /= zoom;
        uv+=0.5;
        
        a.rgb = texture2D(front, uv).rgb;
        
        if(uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            a.rgb = vec3(0.0);
        }
        
        a.a = 1.0;
    } else {
        a.a = 0.0;
    }
    
    gl_FragColor = a;
}
