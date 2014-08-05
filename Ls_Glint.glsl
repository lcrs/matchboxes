// Glint
// Directly from the dancefloor of Studio 54 in 1979
// lewis@lewissaunders.com

uniform sampler2D front, matte;
uniform float adsk_result_w, adsk_result_h;
uniform float threshold, gain, size, rays, spin, falloff, twirl, barrel, barrelbend, saturation;
uniform vec3 tint;
uniform bool screen, usematte;
uniform float dispersion, dispersionoffset, dispersioncycles;
uniform float aspect, aa;
#define samples (size*aa)
#define tau (2.0*3.1415926535)

// RGB to Rec709 YPbPr
vec3 yuv(vec3 rgb) {
    return mat3(0.2215, -0.1145, 0.5016, 0.7154, -0.3855, -0.4556, 0.0721, 0.5, -0.0459) * rgb;
}

// Rec709 YPbPr to RGB
vec3 rgb(vec3 yuv) {
    return mat3(1.0, 1.0, 1.0, 0.0, -0.1870, 1.8556, 1.5701, -0.4664, 0.0) * yuv;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec3 frontpix = texture2D(front, uv).rgb;
    vec3 sample, glint = vec3(0.0);
    vec2 offset;
    float angle;

    // Iterate around rays
    for(float ray = 0.0; ray < rays; ray++) {
        // Figure out what angle this ray is at
        angle = ray * tau/rays;
        
        // Spin rotates entire glint
        angle -= spin/360.0 * tau;
        
        // Iterate along arm of ray
        for(float i = size/samples; i < size; i += size/samples) {
            // Twirl ray around further as we move out
            angle -= (twirl/samples * i/size)/360.0 * tau;
            
            // Offset along ray direction
            offset = i/vec2(adsk_result_w, adsk_result_h) * vec2(cos(angle), sin(angle));
            
            // Horizontal stretch/squash for anamorphic glints
            offset.x *= aspect;

            // Barrel pushes ends of rays away towards edge of frame
            offset -= pow((i/size), barrelbend) * 0.1 * barrel * (-uv+vec2(0.5, 0.5));
            
            // Read a pixel
            sample = texture2D(front, uv + offset).rgb;

            // Affect it by the matte
            if(usematte) {
                sample *= texture2D(matte, uv + offset).rgb;
            }
            
            // Only keep pixels over threshold
            sample *= max(sample - threshold, 0.0);

            // Falloff darkens the ray ends
            if(falloff > 1.0) {
                sample *= max(0.0, mix(1.0, -falloff+2.0, i/size));
            } else {
                sample *= max(0.0, mix(falloff, 1.0, i/size));
            }
            
            // Do saturation in YUV
            vec3 sampley = yuv(sample);
            sampley.gb *= saturation;
            
            // Hue varies along length of ray
            float hue = dispersioncycles * tau *-i/size;
            hue -= dispersionoffset/360.0 * tau;
            
            // Use hue as angle around centre of UV plane
            vec2 rainbow = vec2(cos(hue), sin(hue)) * sampley.r;
            sampley.gb = mix(sampley.gb, rainbow, dispersion * i/size);
            sample = rgb(sampley);
            
            // Accumulate
            glint += sample;
        }
    }
    // Normalise all our accumulated samples
    glint /= rays * samples;
    
    // Master brightness
    glint *= gain;
    
    // Tint
    glint = yuv(glint);
    vec3 tinty = yuv(tint);
    tinty.gb *= glint.r; // if uv > 0 when y = 0, bad things happen
    glint.gb = mix(glint.gb, tinty.gb, 3.0*length(tinty.gb));
    glint = rgb(glint);
    
    // Blend with front input
    vec3 result;
    if(screen) {
        result = max(max(frontpix, glint), glint+frontpix-(glint*frontpix));
    } else {
        result = frontpix + glint;
    }

    // Matte output is luma of glint only
    gl_FragColor = vec4(result, yuv(glint).r);
}
