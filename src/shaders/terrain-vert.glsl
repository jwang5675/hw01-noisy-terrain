#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;

float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

vec2 worlyCenter(vec2 pos, float gridSize) {
	vec2 grid = floor(pos) - mod(floor(pos), gridSize);
	return grid + gridSize * vec2(random1(grid, vec2(8.0, 8.0)), random1(grid, vec2(27.0, 27.0)));
}

float getWorlyHeight(vec2 pos, float gridSize) {
	vec2 closest = worlyCenter(pos, gridSize);

	for (float i = -1.0; i < 2.0; i++) {
		for (float j = -1.0; j < 2.0; j++) {
			vec2 newNeighbor = vec2(pos.x + gridSize * i, pos.y + gridSize * j);
			vec2 neighborCenter = worlyCenter(newNeighbor, gridSize);
			if (distance(pos, neighborCenter) < distance(pos, closest)) {
				closest = neighborCenter;
			}
		}
	}

	return mix(0.0, 8.0, clamp(distance(closest, pos) / (1.4142 * gridSize), 0.0, 1.0));
}

float interpolation(vec2 pos) {
    vec2 numComponent = vec2(floor(pos.x), floor(pos.y));
    vec2 fracComponent = vec2(fract(pos.x), fract(pos.y));

    float a = random1(numComponent, vec2(0, 0));
    float b = random1(numComponent + vec2(1.0, 0.0), vec2(0, 0));
    float c = random1(numComponent + vec2(0.0, 1.0), vec2(0, 0));
    float d = random1(numComponent + vec2(1.0, 1.0), vec2(0, 0));

    vec2 u = fracComponent * fracComponent * vec2(3.0 - 2.0 * fracComponent.x, 3.0 - 2.0 * fracComponent.y);

    return mix(a, b, u[0]) + (c - a)* u[1] * (1.0 - u[0]) + (d - b) * u[0] * u[1];
}

float fbm(vec2 pos) {
	float ret = 0.f;
	float amplitude = 0.5;
    int frequency = 16;

    for (int i = 0; i < frequency; i++) {
        ret = ret + amplitude * interpolation(pos);
        amplitude = 0.25 * amplitude;
    }

	return ret;
}

float getRedistributionNoise(vec2 pos, float distributionValue) {
	float ret = 1.0 * random1(pos, vec2(7.0, 7.0)) + 
	            0.5 * random1(2.0 * pos, vec2(7.0, 7.0)) + 
	            0.25 * random1(4.0 * pos, vec2(7.0, 7.0));
	return pow(ret, distributionValue);
}

void main()
{
  vec2 point = vs_Pos.xz + u_PlanePos;

  float height = 0.33 * getRedistributionNoise(point, 0.54) + 3.0 * fbm(point) + getWorlyHeight(point, 20.0) + 0.5;
  height = max(3.2, height);
  
  vec4 modelposition = vec4(vs_Pos.x, height, vs_Pos.z, 1.0);
  fs_Pos = modelposition.xyz;
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
}