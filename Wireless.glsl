// Wireless - removes wires, and other straight-ish things
// lewis@lewissaunders.com
// TODO:
//  o restore detail along axis of wire by blurring along it, differencing and... something
//  o offset sample points along image gradients
//  o bendy wire
//  o soft edge

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
uniform vec2 starttrack, endtrack, startoffset, endoffset;
uniform float radius, restoreSize, restoreMix;
uniform bool overlay;

vec2 closestPointOnLine(vec2 p0, vec2 p1, vec2 p) {
	vec2 v = p1 - p0;
	vec2 w = p - p0;
	float c1 = dot(w, v);
	float c2 = dot(v, v);

	if(c1 <= 0.0)
		return p0;
	if(c2 <= c1)
		return p1;

	float b = c1 / c2;
	vec2 pb = p0 + b * v;
	return pb;
}

float distanceToLine(vec2 p0, vec2 p1, vec2 p) {
	return length(closestPointOnLine(p0, p1, p) - p);
}

void main() {
	vec2 res = vec2(adsk_result_w, adsk_result_h);
	vec2 coords = gl_FragCoord.xy;

	vec2 start = starttrack + (startoffset * res);
	vec2 end = endtrack + (endoffset * res);

	vec2 grad = (end - start) / length(end - start);
	vec2 tangent = vec2(-grad.y, grad.x);

	vec2 closest = closestPointOnLine(start, end, coords);
	vec2 sample1 = closest + (tangent * radius);
	vec2 sample2 = closest - (tangent * radius);
	vec3 color1 = texture2D(front, sample1 / res).rgb;
	vec3 color2 = texture2D(front, sample2 / res).rgb;

	vec3 o;
	float m;
	if(distanceToLine(start, end, coords) > radius) {
		o = texture2D(front, coords / res).rgb;
		m = 0.0;
	} else {
		// Interpolate between the two points
		float blend = length(coords - (closest + (tangent * radius)));
		blend /= radius * 2.0;
		o = mix(color1, color2, blend);

		// Blur along the line
		vec3 blurred = vec3(0.0);
		float samples = 0.0;
		for(float i = -restoreSize; i < restoreSize; i += 0.333333) {
			vec2 p = coords + i * grad;
			blurred += texture2D(front, p / res).rgb;
			samples++;
		}
		blurred /= samples;

		vec3 front = texture2D(front, coords / res).rgb;
		o += restoreMix * (front - blurred);
		m = 1.0;
	}

	if(overlay) {
		if(length(coords - start) < 3.0)
			o = vec3(0.8, 0.2, 0.2);

		if(length(coords - end) < 3.0)
			o = vec3(0.2, 0.8, 0.2);

		if(distanceToLine(start, end, coords) < 1.0) {
			if(mod(length(start - coords), 8.0) < 4.0)
				o = vec3(0.4, 0.4, 0.8);
		}
	}

	gl_FragColor = vec4(o, m);
}
