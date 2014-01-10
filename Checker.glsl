uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
uniform float w, h, rows, cols, rot;
uniform bool grid, dots, lines, tileable;
uniform vec3 c0, c1, c2, c3, cgrid, cdots, clines;

void main(void) {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 p = gl_FragCoord.xy;
	vec2 coords = p / res;

	float x;
	x = mod(p.x, adsk_result_w/w);
	x = 1.0 - smoothstep(0.0, 1.0, x);

	float y;
	y = mod(p.y, adsk_result_h/h);
	y = 1.0 - smoothstep(0.0, 1.0, y);

	vec4 o = vec4(max(x, y));

	gl_FragColor = o;
}