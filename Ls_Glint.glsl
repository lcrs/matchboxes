const float threshold = 0.8;
const float gain = 40.0;
const float size = 90.0;
const float rays = 6.0;
const float spin = 49.0;
const float falloff = 0.5;
const float twirl = 0.0;
const float barrel = 0.2;
const float barrelbend = 0.0;
const float saturation = 0.5;
const vec3 tint = vec3(0.9, 0.95, 1.0);
const bool screen = true;
const float diffraction = 1.0;
const float diffractionoffset = -45.0;
const float diffractioncycles = 1.5;
const float aspect = 1.0;
const float randlen = 0.0;
const float randspin = 0.0;
const float randgain = 0.0;
const float randseed = 0.1;
const float aa = 1.5;
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
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec3 front = texture2D(iChannel0, uv).rgb;
    vec3 sample, glint = vec3(0.0);
    vec2 offset;
    float angle;

    // Iterate around rays
    for(float ray = 0.0; ray < rays; ray++) {
        // Random-ish value for this ray
        float rand = fract(sin(ray * 3214.5 + randseed) * 45378.42) - 0.5;
        
        // Figure out what angle this ray is at
        angle = ray * tau/rays;
        
        // Spin rotates entire glint
        angle -= spin/360.0 * tau;
        
        // Random rotation for this ray
        angle -= rand * randspin/360.0 * tau;
        
        // Iterate along arm of ray
        for(float i = size/samples; i < size; i += size/samples) {
            // Twirl ray around further as we move out
            angle -= (twirl/samples * i/size)/360.0 * tau;
            
            // Offset along ray direction
            offset = i/iResolution.xy * vec2(cos(angle), sin(angle));
            
            // Horizontal stretch/squash for anamorphic glints
            offset.x *= aspect;
            
            // Random length variation for this ray
            offset *= abs(1.0 + randlen * rand);
            
            // Barrel pushes ends of rays away towards edge of frame
            offset -= pow((i/size), barrelbend) * barrel * (-uv+vec2(0.5, 0.5));
            
            // Read a pixel
            sample = texture2D(iChannel0, uv + offset).rgb;
            
            // Only keep pixels over threshold
            sample *= smoothstep(threshold, 1.0, sample);
            
            // Random brightness variation for this ray
            sample *= abs(1.0 + randgain * rand);
            
            // Falloff darkens the ray ends
            sample *= smoothstep(1.001, 1.0-falloff, i/size);
            
            // Do saturation in YUV
            vec3 sampley = yuv(sample);
            sampley.gb *= saturation;
            
            // Hue varies along length of ray
            float hue = diffractioncycles * tau *-i/size;
            hue -= diffractionoffset/360.0 * tau;
            
            // Use hue as angle around centre of UV plane
            vec2 rainbow = vec2(cos(hue), sin(hue)) * sampley.r;
            sampley.gb = mix(sampley.gb, rainbow, diffraction * i/size);
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
        result = 1.0 - ((1.0-front) * (1.0-glint));
    } else {
        result = front + glint;
    }

    gl_FragColor = vec4(glint, length(glint));
}
