// Wireless - removes wires, and other straight-ish things
// lewis@lewissaunders.com
// TODO:
//  o work in pixels internally
//  o restore detail along axis of wire by blurringa along it, differencing and... something
//  o offset sample points along image gradients
//  o bendy wire
//  o generally everything

uniform sampler2D front;
uniform float adsk_result_w, adsk_result_h;
uniform vec2 start, end;
uniform float thickness;
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
	vec2 coords = gl_FragCoord.xy / res;

	vec2 grad, tangent;
	grad = end - start;
	grad /= length(grad);
	tangent = vec2(-grad.y, grad.x);

	vec2 closest;
	vec3 sample1, sample2;
	float thicknessn = thickness / res.x;
	closest = closestPointOnLine(start, end, coords);
	sample1 = texture2D(front, closest + (tangent * (thicknessn/2.0))).rgb;
	sample2 = texture2D(front, closest - (tangent * (thicknessn/2.0))).rgb;

	vec3 o;
	float blend;
	if(distanceToLine(start, end, coords) > thicknessn/2.0) {
		o = texture2D(front, coords).rgb;
	} else {
		blend = length(coords - (closest + (tangent * (thicknessn/2.0)))) / thicknessn;
		o = mix(sample1, sample2, blend);
	}

	if(overlay) {
		if(length(coords - start) < 5.0/res.x)
			o = vec3(0.8, 0.2, 0.2);

		if(length(coords - end) < 5.0/res.x)
			o = vec3(0.2, 0.8, 0.2);

		if(distanceToLine(start, end, coords) < thicknessn/2.0) {
			o = vec3(0.4, 0.4, 0.8);
		}
	}

	gl_FragColor = vec4(o, 1.0);
}
