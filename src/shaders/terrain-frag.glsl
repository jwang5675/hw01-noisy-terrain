#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Sine;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float random1(vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

// Perlin Noise adapted from https://gist.github.com/patriciogonzalezvivo, referenced from https://thebookofshaders.com/11/
vec4 permute(vec4 x){
	return mod(((x * 34.0) + 1.0) * x, 289.0);
}

vec2 fade(vec2 t) {
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float perlinNoise(vec2 pos){
  vec4 offset = vec4(0.0, 0.0, 1.0, 1.0);
  vec4 grid = floor(pos.xyxy) + offset;
  vec4 decimal = fract(pos.xyxy) - offset;
  
  vec4 ix = grid.xzxz;
  vec4 iy = grid.yyww;
  vec4 fx = decimal.xzxz;
  vec4 fy = decimal.yyww;
  vec4 i = permute(permute(ix) + iy);

  vec4 gx = 2.0 * fract(i * 1.0 / 41.0) - 1.0;
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;

  vec2 g00 = vec2(gx.x, gy.x);
  vec2 g10 = vec2(gx.y, gy.y);
  vec2 g01 = vec2(gx.z, gy.z);
  vec2 g11 = vec2(gx.w, gy.w);
  vec4 norm = 1.79284291400159 - 0.85373472095314 * vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));

  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;

  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  
  vec2 fade_xy = fade(decimal.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}

vec3 snowToTreesMix(vec3 snow, vec2 pos, float threshold) {
   	if (random1(pos, pos) > threshold) {
   		return mix(snow, vec3(0.039, 0.203, 0.301), perlinNoise(pos * 10.0));
   	} else {
   		return snow;
   	}
}

vec3 treesToSnowMix(vec3 tree, vec2 pos, float threshold) {
   	if (random1(pos, pos) > threshold) {
   		return mix(tree, vec3(0.5, 0.5, 0.5), perlinNoise(pos * 5.0));
   	} else {
   		return tree;
   	}
}

vec3 icyTerrainColor(float height, vec2 pos) {
	if (height < 3.2) {
    	// dark water
    	return vec3(0.050, 0.227, 0.529);
    } else if (height < 3.8) {
    	// light water
    	return mix(vec3(0.050, 0.227, 0.529), vec3(0.792, 0.945, 0.988), (height - 3.2) / 0.6);
    } else if (height < 4.1) {
    	// water front
    	vec3 snow = mix(vec3(0.070, 0.235, 0.392), vec3(1.0, 1.0, 1.0), (height - 3.8) / 0.3);
    	return snowToTreesMix(snow, pos, 0.8);
    } else if (height < 4.25) {
    	// grassy front
    	vec3 snow = mix(vec3(1.0, 1.0, 1.0), vec3(0.043, 0.250, 0.254), (height - 4.1) / 0.15);
    	return snowToTreesMix(snow, pos, 0.8);
    } else if (height < 4.4) {
    	// grass to dark tree front
    	vec3 trees = mix(vec3(0.043, 0.250, 0.254), vec3(0.117, 0.054, 0.262), (height - 4.25) / 0.15);
    	return treesToSnowMix(trees, pos, 0.8);
    } else if (height < 5.3) {
    	// dark tree front
    	vec3 trees = mix(vec3(0.117, 0.054, 0.262), vec3(0.070, 0.235, 0.392), (height - 4.4) / 0.9);
    	return treesToSnowMix(trees, pos, 0.8);
    } else if (height < 5.8) {
    	// second snow layer
    	vec3 snow = mix(vec3(0.070, 0.235, 0.392), vec3(0.831, 0.890, 0.878), (height - 5.3) * 2.0);
    	return snowToTreesMix(snow, pos, 0.8);
    } else if (height < 6.3) {
    	// purple rocks
    	vec3 snow = mix(vec3(0.831, 0.890, 0.878), vec3(0.317, 0.286, 0.411), (height - 5.8) * 2.0);
    	return snowToTreesMix(snow, pos, 0.5);
   	} else if (height < 6.8) {
   		// dark tree top
   		vec3 trees = mix(vec3(0.317, 0.286, 0.411), vec3(0.039, 0.203, 0.301), (height - 6.3) * 2.0);
    	return treesToSnowMix(trees, pos, 0.8);
   	} else {
   		// snow top
   		vec3 snow = mix(vec3(0.039, 0.203, 0.301), vec3(1.0, 1.0, 1.0), height - 6.8);
   		return snowToTreesMix(snow, pos, 0.5);
    }
}

vec3 scaledIcyTerrainColor(float height, vec2 point) {
	vec3 color = icyTerrainColor(height, point + vec2(1.0, 0.0)) + 
				 icyTerrainColor(height, point + vec2(0.0, 1.0)) + 
				 icyTerrainColor(height, point + vec2(-1.0, 0.0)) +
				 icyTerrainColor(height, point + vec2(0.0, -1.0)) + 
				 icyTerrainColor(height, point);
	return color / 5.0;
} 

void main()
{
    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    vec2 point = fs_Pos.xz + u_PlanePos; 
    vec3 color = scaledIcyTerrainColor(fs_Pos.y, point);

    // distance fog interpolation
    out_Col = vec4(mix(color, vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
}