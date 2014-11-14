// Glint
// Directly from the floor of Studio 54 in 1979
// lewis@lewissaunders.com

uniform sampler2D front, matte;
uniform float adsk_result_w, adsk_result_h;
uniform float threshold, gain, size, rays, spin, falloff, twirl, barrel, barrelbend, saturation, extrasize;
uniform vec3 tint;
uniform bool screen, usematte, useblendmatte, outputglints;
uniform float dispersion, dispersionoffset, dispersioncycles;
uniform float aspect, aa;
#define realsize (size*extrasize)
#define samples (size*extrasize*aa)
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
    vec3 mattepix = texture2D(matte, uv).rgb;
    vec3 sample, glint = vec3(0.0);
    vec2 offset;
    float angle;

    // If matte is being used to blend with, we can take a massive shortcut where it's black
    if(useblendmatte && (length(mattepix) < 0.0001)) {
        gl_FragColor = vec4(frontpix, 0.0);
        if(outputglints) {
            gl_FragColor = vec4(0.0);
        }
        return;
    }

    // Iterate around rays
    for(float ray = 0.0; ray < rays; ray++) {
        // Figure out what angle this ray is at
        angle = ray * tau/rays;
        
        // Spin rotates entire glint
        angle -= spin/360.0 * tau;
        
        // Iterate along arm of ray
        for(float i = realsize/samples; i < realsize; i += realsize/samples) {
            // Twirl ray around further as we move out
            angle -= (twirl/samples * i/realsize)/360.0 * tau;
            
            // Offset along ray direction
            offset = i/vec2(adsk_result_w, adsk_result_h) * vec2(cos(angle), sin(angle));
            
            // Horizontal stretch/squash for anamorphic glints
            offset.x *= aspect;

            // Barrel pushes ends of rays away towards edge of frame
            offset -= pow((i/realsize), barrelbend) * 0.1 * barrel * (-uv+vec2(0.5, 0.5));
            
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
                sample *= max(0.0, mix(1.0, -falloff+2.0, i/realsize));
            } else {
                sample *= max(0.0, mix(falloff, 1.0, i/realsize));
            }
            
            // Do saturation in YUV
            vec3 sampley = yuv(sample);
            sampley.gb *= saturation;
            
            // Hue varies along length of ray
            float hue = dispersioncycles * tau *-i/realsize;
            hue -= dispersionoffset/360.0 * tau;
            
            // I'm adventurously using YUV to do a rainbow tint here
            // The discontinuities in the usual HSV method bug me
            // and are probably slower than this, which just requires
            // matrix mults and a bit of trig
            // Hue is the angle around centre of UV plane
            vec2 rainbow = vec2(cos(hue), sin(hue)) * sampley.r;
            sampley.gb = mix(sampley.gb, rainbow, dispersion * i/realsize);
            sample = rgb(sampley);
            
            // Accumulate
            glint += sample;
        }
    }
    // Normalise all our accumulated samples
    glint /= rays * samples;
    
    // Master brightness
    glint *= gain;
    
    // Tint in YUV space
    vec3 glinty = yuv(glint);
    vec3 tinty = yuv(tint);
    tinty.gb *= glinty.r; // If U/V aren't 0 when Y is black, bad things happen...
    glinty.gb = mix(glinty.gb, tinty.gb, 4.0*length(tinty.gb));
    glint = rgb(glinty);
    
    // Blend with front input
    vec3 result;
    if(useblendmatte) {
        glint *= mattepix;
        glinty *= mattepix; // Luma is used for matte output below
    }
    if(screen) {
        result = max(max(frontpix, glint), glint+frontpix-(glint*frontpix));
    } else {
        result = frontpix + glint;
    }
    if(outputglints) {
        result = glint;
    }

    // Matte output is luma of glint only
    gl_FragColor = vec4(result, glinty.r);
}
