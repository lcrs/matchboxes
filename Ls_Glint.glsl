uniform vec3      iResolution;
uniform float     iGlobalTime;
uniform float     iChannelTime[4];
uniform vec4      iMouse;
uniform vec4      iDate;
uniform vec3      iChannelResolution[4];
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
const float threshold = 0.55;
const float gain = 63.0;
const float size = 30.0;
const float rays = 6.0;
const float spin = 44.0;
const float saturation = 0.4;
const float falloff = 0.0;
const float aspect = 1.1;
const float randlen = 0.9;
const float randspin = 9.0;
const float randgain = 0.5;
const float randseed = 0.1;
const vec3 tint = vec3(1.0, 1.0, 1.0);
const float aa = 1.0;
#define samples size*aa
#define tau 2.0*3.1415926535

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
            offset = i/iResolution.xy * vec2(cos(angle), sin(angle));
            offset.x *= aspect;
            offset *= abs(1.0 + randlen * rand);
            sample = texture2D(iChannel0, uv + offset).rgb;
            sample *= smoothstep(threshold, 1.0, sample) * gain;
            sample *= abs(1.0 + randgain * rand);
            sample *= smoothstep(1.001, 1.0-falloff, i/size);
            glint += sample;
        }
    }
    glint /= rays * samples;
    
    float luma = 0.2126*glint.r + 0.7152*glint.g + 0.0722*glint.b;
    glint = mix(vec3(luma), glint, saturation);
    
    glint = mix(luma * normalize(tint), glint, tint); //FIXX
    
    vec3 result = front + glint;
	gl_FragColor = vec4(result, 1.0);
}