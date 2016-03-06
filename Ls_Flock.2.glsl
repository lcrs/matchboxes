// Flock pass 2
// This pass simply trims off the top half of the simulation texture,
// which stores velocities that are not useful for Action rendering
//
// lewis@lewissaunders.com
//

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1;

void main() {
    vec2 xy = gl_FragCoord.xy;
    vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);

    gl_FragColor = texture2D(adsk_results_pass1, xy * px * vec2(1.0, 0.5));
}
