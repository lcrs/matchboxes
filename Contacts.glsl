// Tiles the inputs into a grid for impressing clients
// lewis@lewissaunders.com
// TODO:
//  o Nonsquare pixels support... eek
//  o Variable width borders look gross, how can we get a nice even spacing?

uniform sampler2D in1, in2, in3, in4, in5, in6;
uniform int rows, cols, randomcount, seed;
uniform bool random, perframe, filltiles;
uniform float scale;
uniform float adsk_result_w, adsk_result_h, adsk_time;

// Mysterious dirty random number generator
float rand(vec2 co){
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main() {
	vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
	vec2 tilecoords = vec2(0.0, 0.0);
	vec4 o = vec4(0.0);
	float aspectdiff, tilew, tileh;
	int tilex, tiley, tileidx;

	// Figure out how big each tile will be, and which tile we're in
	tilew = adsk_result_w / float(cols);
	tileh = adsk_result_h / float(rows);
	tilex = int(gl_FragCoord.x / tilew);
	tiley = int((adsk_result_h - gl_FragCoord.y) / tileh);
	tileidx = tiley * cols + tilex;
	
	// Randomize the tile index
	if(random) {
		if(perframe) {
			tileidx = int(rand(vec2(float(tilex - seed), float(tiley) + 1234.0 * adsk_time)) * float(randomcount));
		} else {
			tileidx = int(rand(vec2(float(tilex - seed), float(tiley))) * float(randomcount));
		}
	}

	// Get current coordinates within this tile
	tilecoords.x = mod(gl_FragCoord.x, tilew) / tilew;
	tilecoords.y = mod(gl_FragCoord.y, tileh) / tileh;
	
	// Scale coordinates about the centre of each tile to maintain proportions and do fit/fill
	tilecoords -= vec2(0.5);
	tilecoords *= 100.0 / scale;
	aspectdiff = (tilew / tileh) / (adsk_result_w / adsk_result_h);
	if(aspectdiff > 1.0) {
		tilecoords.x *= aspectdiff;
		if(filltiles) {
			tilecoords /= aspectdiff;
		}
	} else {
		tilecoords.y /= aspectdiff;
		if(filltiles) {
			tilecoords *= aspectdiff;
		}
	}
	tilecoords += vec2(0.5);
	
	// Finally grab input for the tile we're in
	if(tileidx == 0) {
		o = texture2D(in1, tilecoords);
	} else if(tileidx == 1) {
		o = texture2D(in2, tilecoords);
	} else if(tileidx == 2) {
		o = texture2D(in3, tilecoords);
	} else if(tileidx == 3) {
		o = texture2D(in4, tilecoords);
	} else if(tileidx == 4) {
		o = texture2D(in5, tilecoords);
	} else if(tileidx == 5) {
		o = texture2D(in6, tilecoords);
	}
	
	// Draw black if we're in a border area
	if((tilecoords.x <= 0.0) || (tilecoords.x > 1.0)) {
			o = vec4(0.0);
	}
	if((tilecoords.y <= 0.0) || (tilecoords.y > 1.0)) {
			o = vec4(0.0);
	}
	
	gl_FragColor = o;
}
