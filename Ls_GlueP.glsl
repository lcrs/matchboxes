// Project on a Position pass
// lewis@lewissaunders.com
// TODO:
//  o Optional near/far clipping
//  o Optional camera-to-world transform using another linked camera
//  o Filtering?
//  o UV output
//  o Front/back facing using rest normals and camera pos?

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D front, matte, pos;
uniform vec3 projector_position, projector_rotation;
uniform float projector_fov, projector_near, projector_far;
#define pi 3.1415926535897932384624433832795

// Degrees to radians
float deg2rad(float angle) {
	return(angle/(180.0/pi));
}

// Rotates in ZXY order
vec3 rotate(vec3 p, vec3 angles) {
	float x = deg2rad(angles.x);
	float y = deg2rad(angles.y);
	float z = deg2rad(angles.z);
	mat3 rx = mat3(1.0, 0.0, 0.0, 0.0, cos(x), sin(x), 0.0, -sin(x), cos(x));
	mat3 ry = mat3(cos(y), 0.0, -sin(y), 0.0, 1.0, 0.0, sin(y), 0.0, cos(y));
	mat3 rz = mat3(cos(z), sin(z), 0.0, -sin(z), cos(z), 0.0, 0.0, 0.0, 1.0);
	mat3 r = ry * rx * rz;
	return(p * r);
}

void main() {
	vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);	
	vec4 p = texture2D(pos, coords);

	// World space to view space
	p.xyz -= projector_position;
	p.xyz = rotate(p.xyz, -projector_rotation);

	// View space to clip space
	float aspect = adsk_result_w / adsk_result_h;
	float fovy = deg2rad(projector_fov);
	float znear = projector_near;
	float zfar = projector_far;
	mat4 projection_matrix = mat4(vec4(1.0/(aspect*tan(fovy/2.0)), 0.0, 0.0, 0.0),
								  vec4(0.0, 1.0/tan(fovy/2.0), 0.0, 0.0),
								  vec4(0.0, 0.0, (zfar+znear)/(zfar-znear), 1.0),
								  vec4(0.0, 0.0, -2.0*zfar*znear/(zfar-znear), 0.0));
	p = projection_matrix * p;

	// Optional clipping

	// Clip space to NDC
	p /= p.w;

	// NDC to window
	p.xy /= -2.0;
	p.xy += 0.5;

	// Sample
	vec3 frontpix = texture2D(front, p.xy).rgb;
	vec3 mattepix = texture2D(matte, p.xy).rgb;
	gl_FragColor = vec4(frontpix, mattepix.b);
}
