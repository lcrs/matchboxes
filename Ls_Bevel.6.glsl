// Bevel
// Pass 6: Multiply the bevel pass output by the back, and comp
// over the back using the matte
// graphistesmoke@gmail.com  (Sébastien DELECOUR / Sebquismoke)

uniform sampler2D adsk_results_pass4, adsk_results_pass5, back, matte;
uniform float adsk_result_w, adsk_result_h;
uniform bool normals;


void main() {
	vec2 xy = gl_FragCoord.xy;
	vec2 px = vec2(1.0) / vec2(adsk_result_w, adsk_result_h);
	vec3 matte = texture2D(matte, xy * px).rgb;
	vec3 back = texture2D(back, xy * px).rgb;
	vec3 bevel = texture2D(adsk_results_pass4, xy * px).rgb;
	vec3 bevelnormals = texture2D(adsk_results_pass5, xy * px).rgb;

	if(normals) {
		gl_FragColor = vec4(bevelnormals.rgb, matte.g);
		return;
	}

	vec3 o = mix(back, back*bevel, matte.g);

	gl_FragColor = vec4(o, matte.g);
}
