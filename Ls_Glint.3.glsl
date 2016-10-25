// Glint pass 3: Gaussian blur vertical and comp
// lewis@lewissaunders.com

uniform sampler2D adsk_results_pass2, front, matte;
uniform float blursize, blursizer, blursizeg, blursizeb;
uniform float adsk_result_w, adsk_result_h;
uniform bool screen, usematte, useblendmatte, outputglints;

// RGB to Rec709 YPbPr
vec3 yuv(vec3 rgb) {
    return mat3(0.2215, -0.1145, 0.5016, 0.7154, -0.3855, -0.4556, 0.0721, 0.5, -0.0459) * rgb;
}

// Return a 1D Gaussian blur from texture tex
// xy: centre of blur in pixels
// res: pixel size of mipmap level selected by lod param
// sizes: sigma of blurs, in pixels
// dir: direction of blur, usually vec2(1.0, 0.0) for horizontal followed by
//      another pass for vertical
vec4 gaussianblur(sampler2D tex, vec2 xy, vec2 res, float sizered, float sizegreen, float sizeblue, float sizealpha, vec2 dir) {
    vec4 sigmas = vec4(sizered, sizegreen, sizeblue, sizealpha);

    // Set up state for incremental coefficient calculation, see GPU Gems
    // We use vec4s to store four copies of the state, for different size
    // red/green/blue/alpha blurs
    vec4 gx, gy, gz;
    gx = 1.0 / (sqrt(2.0 * 3.141592653589793238) * sigmas);
    gy = exp(-0.5 / (sigmas * sigmas));
    gz = gy * gy;
    // vec4 a, centre, sample1, sample2 = vec4(0.0);
    vec4 a = vec4(0.0);
    vec4 centre = vec4(0.0);
    vec4 sample1 = vec4(0.0);
    vec4 sample2 = vec4(0.0);

    // First take the centre sample
    centre = texture2D(tex, xy / res);
    a += gx * centre;
    vec4 energy = gx;
    gx *= gy;
    gy *= gz;

    // Now the other samples
    float support = max(max(max(sigmas.r, sigmas.g), sigmas.b), sigmas.a) * 3.0;
    for(float i = 1.0; i <= support; i++) {
        sample1 = texture2D(tex, (xy - i * dir) / res);
        sample2 = texture2D(tex, (xy + i * dir) / res);
        a += gx * sample1;
        a += gx * sample2;
        energy += 2.0 * gx;
        gx *= gy;
        gy *= gz;
    }

    a /= energy;

    if(sizered < 0.1) a.r = centre.r;
    if(sizegreen < 0.1) a.g = centre.g;
    if(sizeblue < 0.1) a.b = centre.b;

    return a;
}

void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 xy = gl_FragCoord.xy;

    vec3 frontpix = texture2D(front, xy/res).rgb;
    vec3 mattepix = texture2D(matte, xy/res).rgb;

    vec3 blurred = gaussianblur(adsk_results_pass2, xy, res, blursize*blursizer, blursize*blursizeg, blursize*blursizeb, 0.0, vec2(0.0, 1.0)).rgb;

    // Blend with front input
    vec3 result;
    float blurredluma;
    if(useblendmatte) {
        blurred *= mattepix;
        blurredluma = yuv(blurred.rgb).r; // Luma is used for matte output below
    }
    if(screen) {
        result = max(max(frontpix, blurred), blurred+frontpix-(blurred*frontpix));
    } else {
        result = frontpix + blurred;
    }
    if(outputglints) {
        result = blurred;
    }

    // Matte output is luma of glint only
    gl_FragColor = vec4(result, blurredluma);
}
