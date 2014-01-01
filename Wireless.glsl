// Wireless - removes wires, and other straight-ish things
// lewis@lewissaunders.com
// TODO:
//  o restore detail along axis of wire by blurring along it, differencing and... something
//  o offset sample points along image gradients
//  o bendy wire
//  o soft edge

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
uniform vec2 starttrack, endtrack, startoffset, endoffset, bendoffset, t;
uniform float radius, restoresize, restoremix;
uniform bool overlay;

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
	return f / sqrt(dFdx(f)*dFdx(f) + dFdy(f)*dFdy(f));
}

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 coords = gl_FragCoord.xy;

	vec2 start = starttrack + (startoffset * res);
	vec2 end = endtrack + (endoffset * res);
	vec2 bend = bendoffset * res;

	// Grad of the scalar field f is tangent to the wire
	// We're taking the grad and tangent at the current pixel rather than at
	// the closest point on the wire, which isn't totally accurate
	float f = quadbspline(coords, start, bend, end);
	vec2 tangent = normalize(vec2(dFdx(f), dFdy(f)));
	vec2 grad = vec2(-tangent.y, tangent.x);
	vec2 closest = coords - sdf(coords, start, bend, end) * tangent;

	// Take samples from pixels on either side of the wire
	vec2 sample1 = closest + (tangent * radius);
	vec2 sample2 = closest - (tangent * radius);
	vec3 color1 = texture2D(front, sample1 / res).rgb;
	vec3 color2 = texture2D(front, sample2 / res).rgb;

	vec3 o;
	float m;
	if(abs(sdf(coords, start, bend, end)) > radius) {
		// Miles away from the wire, get outta here
		o = texture2D(front, coords / res).rgb;
		m = 0.0;
	} else {
		// Interpolate between the two samples
		float blend = length(coords - (closest + (tangent * radius)));
		blend /= radius * 2.0;
		o = mix(color1, color2, blend);

		// Blur along the line
		vec3 blurred = vec3(0.0);
		float energy = 0.0;
		for(float i = -restoresize; i < restoresize; i += 0.333333) {
			vec2 p = coords + i * grad;
			float weight = 1.0 - abs(i/restoresize); // Triangular kernel, bite me
			blurred += weight * texture2D(front, p / res).rgb;
			energy += weight;
		}
		if(energy == 0.0) {
			blurred = o;
		} else {
			blurred /= energy;
		}

		vec3 frontpix = texture2D(front, coords / res).rgb;
		o = mix(o, o + (frontpix - blurred), restoremix);
		m = 1.0;
	}

	if(overlay) {
		if(length(coords - start) < 3.0)
			o = vec3(0.8, 0.2, 0.2);

		if(length(coords - end) < 3.0)
			o = vec3(0.2, 0.8, 0.2);

		if(length(coords - bend) < 3.0)
			o = vec3(0.2, 0.2, 0.8);

		if(abs(sdf(coords, start, bend, end)) < 2.0) {
				float a = smoothstep(0.0, 1.0, 1.0 - abs(sdf(coords, start, bend, end)));
				o = mix(o, vec3(0.8, 0.4, 0.8), a);
		}
	}

	gl_FragColor = vec4(o, m);
}
