#version 300 es

precision highp float;

#define PI 3.1415926538

uniform vec2 u_resolution;
uniform float u_time;

out vec4 outColor;

const float MAX_DIST = 100.0;
const int   MAX_ITER = 40;
const float EPSILON  = 0.005;

const vec3 bg_col = vec3(0.0, 1.0, 1.0);

vec3 campos;
vec3 ligpos;

mat2 rotate(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);  
}

float soft_union( float d1, float d2, float k ) {
    k *= 4.0;
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
}

float soft_subtraction( float d1, float d2, float k ) {
    return -soft_union(d1,-d2,k);
}

float soft_intersection( float d1, float d2, float k ) {
    return -soft_union(-d1,-d2,k);
}

float sphere(vec3 p, float r) {
    return length(p) - r;
}

float hedu(vec3 p) {

    float nose = sphere(p - vec3(0.0, 0.0, -1.0), 0.2);
    float head = soft_union(
        sphere(p, 1.),
        sphere(p - vec3(0.0, 0.7, 0.0), 1.),
        0.07
    );

    return soft_union(
        head, nose, 0.01
    );
}

float map(vec3 p) {
    p.xz *= rotate(u_time/6.0);
    return hedu(p);
}

vec3 shade(vec3 p, vec3 rd, vec3 n) {

    vec3 col = vec3(1.0, 1.0, 1.0) * 0.6;

    vec3 ambient = col * 0.1;

    vec3 dtl = normalize(ligpos - p);
    vec3 diff = max(dot(n, dtl), 0.0) * col;

    vec3 dtc = normalize(campos - p);
    vec3 ref = normalize(reflect(-dtl, n));
    vec3 spec = pow(max(dot(dtc, ref), 0.0), 32.0) * col * 0.2;

    return ambient + diff + spec;
}

vec3 cnorm(vec3 p) {
    vec2 epvec = vec2(1.0, -1.0) * EPSILON;
    return normalize(
        epvec.xyy * map(p + epvec.xyy) +
        epvec.yyx * map(p + epvec.yyx) +
        epvec.yxy * map(p + epvec.yxy) +
        epvec.xxx * map(p + epvec.xxx)
    );
} 

vec3 raymarch(vec3 ro, vec3 rd) {
    float dist = 0.0;
    vec3 p;
    for (int i; i < MAX_ITER; i++) {
        p = ro + dist * rd;
        float d = map(p);
        if (d < EPSILON) {
            vec3 n = cnorm(p);
            return shade(p, rd, n);
        }

        if (dist > MAX_DIST) {
            return bg_col;
        }

        dist += d;
    }
    // No hit, return default
    return bg_col;
}


void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution - vec2(0.5);
    float asprat = u_resolution.x/u_resolution.y;
    uv.x *= asprat;

    campos = vec3(0.0, 0.0, -6.0);
    ligpos = campos + vec3(0.0, 4.0, 0.0);

    vec3 screen = campos + vec3(uv, 1.0);

    vec3 ray_dir = normalize(screen - campos);

    vec3 col = raymarch(campos, ray_dir);

    outColor = vec4(col, 1.0);
}