const float threshold = 0.8;
const float gain = 70.0;
const float size = 50.0;
const float rays = 6.0;
const float spin = 49.0;
const float falloff = 0.5;
const float twirl = 0.0;
const float barrel = 0.2;
const float barrelbend = 0.0;
const float saturation = 0.5;
const vec3 tint = vec3(0.9, 0.95, 1.0);
const float diffraction = 0.0;
const float diffractionhue = 0.0;
const float aspect = 1.0;
const float randlen = 0.0;
const float randspin = 0.0;
const float randgain = 0.0;
const float randseed = 0.1;
const float aa = 1.5;
#define samples (size*aa)
#define tau (2.0*3.1415926535)

vec3 yuv(vec3 rgb) {
    return mat3(0.2215, -0.1145, 0.5016, 0.7154, -0.3855, -0.4556, 0.0721, 0.5, -0.0459) * rgb;
}

vec3 rgb(vec3 yuv) {
    return mat3(1.0, 1.0, 1.0, 0.0, -0.1870, 1.8556, 1.5701, -0.4664, 0.0) * yuv;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec3 front = texture2D(iChannel0, uv).rgb;
    vec3 sample, glint = vec3(0.0);
    vec2 offset;
    float angle;

    for(float ray = 0.0; ray < rays; ray++) {
        float rand = fract(sin(ray * 3214.5 + randseed) * 45378.42) - 0.5;
        angle = ray * tau/rays;
        angle -= spin/360.0 * tau;
        angle -= rand * randspin/360.0 * tau;
        for(float i = size/samples; i < size; i += size/samples) {
            angle -= (twirl/samples * i/size)/360.0 * tau;
            offset = i/iResolution.xy * vec2(cos(angle), sin(angle));
            offset.x *= aspect;
            offset *= abs(1.0 + randlen * rand);
            offset -= pow((i/size), barrelbend) * barrel * (-uv+vec2(0.5, 0.5));
            sample = texture2D(iChannel0, uv + offset).rgb;
            sample *= smoothstep(threshold, 1.0, sample);
            sample *= abs(1.0 + randgain * rand);
            sample *= smoothstep(1.001, 1.0-falloff, i/size);
            vec3 sampley = yuv(sample);
            sampley.gb *= saturation;
            float hue = tau*i/size;
            hue -= diffractionhue/360.0 * tau;
            vec2 rainbow = vec2(cos(hue), sin(hue)) * sampley.r;
            sampley.gb = mix(sampley.gb, rainbow, diffraction*i/size);
            sample = rgb(sampley);
            glint += sample;
        }
    }
    glint /= rays * samples;
    glint *= gain;
    glint = yuv(glint);
    vec3 tinty = yuv(tint);
    tinty.gb *= glint.r;
    glint.gb = mix(glint.gb, tinty.gb, 3.0*length(tinty.gb));
    glint = rgb(glint);
    
    //vec3 result = front + glint;
    vec3 result = 1.0 - ((1.0-front) * (1.0-glint));

    gl_FragColor = vec4(result, 1.0);
}
