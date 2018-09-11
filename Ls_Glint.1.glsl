// Glint pass 1: convolve with a dynamically generated star function
// lewis@lewissaunders.com

uniform sampler2D front, matte;
uniform float adsk_result_w, adsk_result_h;
uniform float threshold, thresholdclamp, gain, size, rays, spin, falloff, twirl, barrel, barrelbend, saturation, extrasize, extrarays;
uniform vec3 tint;
uniform bool dirton, useblendmatte, usematte;
uniform float dispersion, dispersionoffset, dispersioncycles, dirt, dirtfreq;
uniform float aspect, aa;
uniform int downsample;
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

// Noise
float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
}

void main(void) {
    vec2 uv = float(downsample+1) * gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec3 frontpix = texture2D(front, uv).rgb;
    vec3 mattepix = texture2D(matte, uv).rgb;
    vec3 sample, glint = vec3(0.0);
    vec2 offset;
    float angle;

    // If matte is being used to blend with, we can take a massive shortcut where it's black
    if(useblendmatte && (length(mattepix) < 0.0001)) {
        gl_FragColor = vec4(frontpix, 0.0);
        return;
    }

    // If we're downsampling and outside the image, skip this
    if(uv.x > 1.0 || uv.y > 1.0) {
        return;
    }

    // Iterate around rays
    for(float ray = 0.0; ray < floor(rays*extrarays); ray++) {
        // Figure out what angle this ray is at
        angle = ray * tau/floor(rays*extrarays);

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
            sample = min(sample, thresholdclamp);
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

            if(dirton) {
                // Multiply by a bit of noise texture
                float noiz = rand(vec2(42.1, 12.4) + 0.01 * vec2(dirtfreq/100.0)   * offset);
                noiz +=      rand(vec2(4.1, 1.4)   + 0.01 * vec2(dirtfreq/1000.0)  * offset);
                noiz +=      rand(vec2(2.1, 2.4)   + 0.01 * vec2(dirtfreq/10000.0) * offset);
                sample *= mix(1.0, clamp(10.0 * noiz, 0.0, 99.0), dirt);
            }

            // Accumulate
            glint += sample;
        }
    }
    // Normalise all our accumulated samples
    glint /= floor(rays*extrarays) * samples;

    // Master brightness
    glint *= gain;

    // Tint in YUV space
    vec3 glinty = yuv(glint);
    vec3 tinty = yuv(tint);
    tinty.gb *= glinty.r; // If U/V aren't 0 when Y is black, bad things happen...
    glinty.gb = mix(glinty.gb, tinty.gb, 4.0*length(tinty.gb));
    glint = rgb(glinty);

    gl_FragColor = vec4(glint, 0.0);
}
