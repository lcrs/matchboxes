precision mediump float;

uniform vec2 mouse;
uniform vec2 resolution;
vec2 start = vec2(900, 300);
vec2 end = vec2(1100, 700);
vec2 bend = mouse*resolution;

// Return barycentric coordinates for p in triangle v1,v2,v3
vec3 barycentrics(vec2 p, vec2 v1, vec2 v2, vec2 v3) {
	float det = (v2.y-v3.y)*(v1.x-v3.x)+(v3.x-v2.x)*(v1.y-v3.y);
	float b1 = ((v2.y-v3.y)*(p.x-v3.x)+(v3.x-v2.x)*(p.y-v3.y))/det;
	float b2 = ((v3.y-v1.y)*(p.x-v3.x)+(v1.x-v3.x)*(p.y-v3.y))/det;
	float b3 = 1.0 - b1 - b2;
	return vec3(b1, b2, b3);
}

// Return interpolated UVs for p in triangle v1,v2,v3 with vertex UVs u1,u2,u3
vec2 uvinterp(vec2 p, vec2 v1, vec2 v2, vec2 v3, vec2 u1, vec2 u2, vec2 u3) {
	vec3 b = barycentrics(p, v1, v2, v3);
	return b.x*u1 + b.y*u2 + b.z*u3;
}

// Return value at p of quadratic B-spline with control points v1,v2,v3
float quadbspline(vec2 p, vec2 v1, vec2 v2, vec2 v3) {
	vec2 u1 = vec2(0.0, 0.0);
	vec2 u2 = vec2(0.5, 0.0);
	vec2 u3 = vec2(1.0, 1.0);
	vec2 uv = uvinterp(p, v1, v2, v3, u1, u2, u3);
	return uv.x*uv.x - uv.y;
}

// Return signed distance to zero of quadratic B-spline with control points v1,v2,v3
float sdf(vec2 p, vec2 v1, vec2 v2, vec2 v3) {
	float f = quadbspline(p, v1, v2, v3);
	float dfdx = quadbspline(p-vec2(0.5, 0.0), v1, v2, v3) - quadbspline(p+vec2(0.5, 0.0), v1, v2, v3);
	float dfdy = quadbspline(p-vec2(0.0, 0.5), v1, v2, v3) - quadbspline(p+vec2(0.0, 0.5), v1, v2, v3);
	return f / sqrt(dfdx*dfdx + dfdy*dfdy);
}

void main(void) {
	vec2 coords = gl_FragCoord.xy;
	vec2 res = resolution;
	vec3 o = vec3(0.0);

	float f = sdf(coords, start, bend, end);
	if(abs(f) < 4.0) {
		if(abs(f) > -4.0) {
			o = vec3(1.0);
		}
	}

	if(length(coords - start) < 5.0)
		o = vec3(1.0, 0.0, 0.0);
	if(length(coords - end) < 5.0)
		o = vec3(0.0, 1.0, 0.0);
	if(length(coords - bend) < 5.0)
		o = vec3(0.0, 0.0, 1.0);
	
	gl_FragColor = vec4(o, 1.0);

}
