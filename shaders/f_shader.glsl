#version 300 es

precision highp float;

#define PI 3.1415926538

uniform vec2 u_resolution;
uniform float u_time;

out vec4 outColor;

const float MAX_DIST = 300.0;
const float EPSILON = 0.001;
const int MAX_ITER = 250;

vec3 campos;
vec3 ligpos;

struct material {
    float reflectance;
    vec3 c_ambient;
    vec3 c_diffuse;
    vec3 c_specular;
};

struct surface {
    float sdfv;
    material material;
};

mat2 rotate(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);  
}

float box( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sphere(vec3 p, float r) {
    return length(p) - r;
}

float soft_min( float a, float b, float k )
{
    k *= 4.0;
    float h = max( k-abs(a-b), 0.0 )/k;
    return min(a,b) - h*h*k*(1.0/4.0);
}

float map(vec3 p) {
    p.xz *= rotate(u_time);
    return soft_min(
        sphere(p, 1.0), 
        box(p - vec3(0.0, -2.0, 0.0), vec3(2.0, 0.1, 2.0)),
        0.5
    );
}

vec3 calculate_normal(vec3 p) {
    vec2 epvec = vec2(1.0, -1.0) * EPSILON;
    return normalize(
        epvec.xyy * map(p + epvec.xyy) +
        epvec.yyx * map(p + epvec.yyx) +
        epvec.yxy * map(p + epvec.yxy) +
        epvec.xxx * map(p + epvec.xxx)
    );
}

vec3 shade(vec3 p, vec3 n) {
    vec3 dtl = normalize(ligpos - p);
    vec3 diff = max(dot(n, dtl), 0.0) * vec3(0.0, 0.0, 1.0);

    vec3 dtc = normalize(campos - p);
    vec3 ref = normalize(reflect(-dtl, n));
    vec3 spec = pow(max(dot(dtc, ref), 0.0), 32.0) * vec3(1.0);

    return diff + spec;
}

vec3 raymarch(vec3 ray_origin, vec3 ray_dir) {

    float distance = 0.0f;
    vec3 p;

    for (int i = 0; i < MAX_ITER; i++) {
        p = ray_origin + distance * ray_dir;
        
        float sdfv = map(p);
        
        if (sdfv < EPSILON) {
            vec3 n = calculate_normal(p);
            return shade(p, n);
        }

        if (distance > MAX_DIST) break;

        distance += sdfv;
    }
    return vec3(0.0);

}

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution - vec2(0.5);
    float asprat = u_resolution.x/u_resolution.y;
    uv.x *= asprat;

    campos = vec3(0.0, 0.0, -8.0);
    ligpos = campos + vec3(0.0, sin(u_time)*2.0, 0.0);
    vec3 screen = vec3(uv, campos.z + 1.0);

    vec3 raydir = normalize(screen - campos);
    vec3 result = raymarch(campos, raydir);

    outColor = vec4(result, 1.0);
}