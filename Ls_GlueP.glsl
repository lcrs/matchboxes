// Project on a Position pass
// lewis@lewissaunders.com
// TODO:
//  o Filtering?  Or rely on outputting UVs into UVewa
//  o Soft shoulders on the depth clip and front/back face clip? You can pull keys from P or N instead
//  o Clip space isn't traditional, couldn't figure out proper [near,far] > [-1,1]
/*  o Seam fixing when AOVs are antialiased? An idea, which should probably go in Ls_UVewa:
		i) edge detect uv output, just dFdx() is probably ok
		ii) blur result a little
		iii) use dFdx() of blurred edges to get edge tangent vector
		iv) walk along tangent for at least 2px, then continue until no longer on an edge
		v) same in opposite direction
		vi) these two positions along the tangent become our fg/bg sample points
		vii) fetch texture for fg/bg points
		viii) blend fg over bg according to... something... distance from edge?
*/

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D front, matte, pos, norm;
uniform float adsk_front_pixelratio;
uniform vec3 projector_position, projector_rotation;
uniform vec3 worldcam_position, worldcam_rotation;
uniform float projector_fov, znear, zfar;
uniform bool zclip, outputviewspace, outputclipspace, outputndc, outputuv, frontface, backface;
uniform bool convert, convertp, convertn, outputp, outputn;
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

// Un-rotates in ZXY order
vec3 unrotate(vec3 p, vec3 angles) {
	float x = deg2rad(angles.x);
	float y = deg2rad(angles.y);
	float z = deg2rad(angles.z);
	mat3 rx = mat3(1.0, 0.0, 0.0, 0.0, cos(x), sin(x), 0.0, -sin(x), cos(x));
	mat3 ry = mat3(cos(y), 0.0, -sin(y), 0.0, 1.0, 0.0, sin(y), 0.0, cos(y));
	mat3 rz = mat3(cos(z), sin(z), 0.0, -sin(z), cos(z), 0.0, 0.0, 0.0, 1.0);
	mat3 r = ry * rx * rz;
	return(r * p);
}

void main() {
	vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
	vec4 p = texture2D(pos, coords);
	vec3 n = normalize(texture2D(norm, coords).xyz);

	// Optional space conversion
	if(convert) {
		if(convertp) {
			p.z *= -1.0;
			p.xyz = unrotate(p.xyz, -worldcam_rotation);
			p.xyz += worldcam_position;
		}
		if(convertn) {
			n.z *= -1.0;
			n = unrotate(n, -worldcam_rotation);
		}
	}
	if(outputp) {
		gl_FragColor = p;
		return;
	}
	if(outputn) {
		gl_FragColor = vec4(n, 1.0);
		return;
	}
	vec3 worldp = p.xyz;

	// World space to view space
	p.xyz -= projector_position;
	p.xyz = rotate(p.xyz, -projector_rotation);
	if(outputviewspace) {
		p.z *= -1.0;
		gl_FragColor = p;
		return;
	}

	// Optional clipping
	if(zclip) {
		if(abs(p.z) < znear || abs(p.z) > zfar) {
			gl_FragColor = vec4(0.0);
			return;
		}
	}

	// Clip behind projector
	if(p.z > 0.0) {
			gl_FragColor = vec4(0.0);
			return;
	}

	// Facing
	vec3 v = normalize(projector_position - worldp);
	float facingratio = dot(n, v);
	if(facingratio > 0.0) {
		if(!frontface) {
			gl_FragColor = vec4(0.0);
			return;
		}
	} else {
		if(!backface) {
			gl_FragColor = vec4(0.0);
			return;
		}
	}

	// View space to clip space
	float aspect = adsk_result_w / adsk_result_h;
	float fovy = deg2rad(projector_fov);
	mat4 projection_matrix = mat4(vec4(1.0/(aspect*tan(fovy/2.0)), 0.0, 0.0, 0.0),
								  vec4(0.0, 1.0/tan(fovy/2.0), 0.0, 0.0),
								  vec4(0.0, 0.0, 1.0, 1.0),
								  vec4(0.0, 0.0, 1.0, 0.0));
	p = projection_matrix * p;
	if(outputclipspace) {
		gl_FragColor = p;
		return;
	}

	// Clip space to NDC
	p /= p.w;
	if(outputndc) {
		gl_FragColor = p;
		return;
	}

	// NDC to window
	p.xy /= -2.0;
	p.x /= adsk_front_pixelratio;
	p.xy += 0.5;
	if(outputuv) {
		p.z *= 0.0;
		gl_FragColor = p;
		return;
	}
	if(p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0) {
			gl_FragColor = vec4(0.0);
			return;
	}

	// Sample
	vec3 frontpix = texture2D(front, p.xy).rgb;
	vec3 mattepix = texture2D(matte, p.xy).rgb;
	gl_FragColor = vec4(frontpix, mattepix.b);
}
