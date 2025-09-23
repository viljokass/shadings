#version 300 es

precision highp float;

#define PI 3.1415926538

uniform vec2 u_resolution;
uniform float u_time;

out vec4 outColor;

const float MAX_DIST = 300.0;
const float EPSILON = 0.005;
const int MAX_ITER = 250;

vec3 campos;
vec3 ligpos;


struct material {
    float reflectance;
    float specular_exp;
    vec3 c_ambient;
    vec3 c_diffuse;
    vec3 c_specular;
};

const material gold = material(
    0.5,
    51.2,
    vec3(0.24725, 0.1995, 0.0745),
    vec3(0.75164, 0.60648, 0.22648),
    vec3(0.628281, 0.555802, 0.366065)
);

const material chrome = material(
    0.9,
    76.8,
    vec3(0.25),
    vec3(0.4),
    vec3(0.774597)
);

const material matte_red = material(
    0.0,
    32.0,
    vec3(1.0, 0.0, 0.0) * 0.005,
    vec3(1.0, 0.0, 0.0) * 0.67,
    vec3(1.0, 0.0, 0.0) * 1.0
);


struct surface {
    float sdfv;
    material material;
};

struct ray_hit{
    bool hit;
    vec3 p;
    material material;
    vec3 normal;
};

mat2 rotate(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);  
}

surface box( vec3 p, vec3 b, material material) {
  vec3 q = abs(p) - b;
  float sdfv = length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
  return surface(sdfv, material);
}

surface sphere(vec3 p, float r, material material) {
    float sdfv = length(p) - r;
    return surface(sdfv, material);
}

surface surface_union(surface a, surface b) {
    if (a.sdfv < b.sdfv) return a;
    return b;
}

surface map(vec3 p) {
    
    p.yz *= rotate(sin(u_time * 2.0)*PI/16. + PI/10.0);
    p.xz *= rotate(sin(u_time)*PI/16. + PI/4.0);
    
    surface ball = sphere(
        p - vec3(-1.0, 0.5, 0.0),
        0.75,
        matte_red
    );
    surface floor = box(
        p - vec3(0.0, -2.0, 0.0),
        vec3(4.0, 0.1, 4.0),
        chrome
    );
    surface wall_l = box(
        p - vec3(-4.0, 0.0, 0.0),
        vec3(0.1, 2.0, 4.0),
        chrome
    );
    surface wall_b = box(
        p - vec3(0.0, 0.0, 4.0),
        vec3(4.0, 2.0, 0.1),
        chrome
    );
    return surface_union(
        surface_union(
            ball,
            floor
        ),
        surface_union(
            wall_b,
            wall_l
        )
    );
}

vec3 calculate_normal(vec3 p) {
    vec2 epvec = vec2(1.0, -1.0) * EPSILON;
    return normalize(
        epvec.xyy * map(p + epvec.xyy).sdfv +
        epvec.yyx * map(p + epvec.yyx).sdfv +
        epvec.yxy * map(p + epvec.yxy).sdfv +
        epvec.xxx * map(p + epvec.xxx).sdfv
    );
}

vec3 shade(vec3 ro, vec3 rd, vec3 p, vec3 n, material material) {

    vec3 ambient = material.c_ambient * 0.3;

    vec3 dtl = normalize(ligpos - p);
    vec3 diff = max(dot(n, dtl), 0.0) * material.c_diffuse;

    vec3 dtc = normalize(ro - p);
    vec3 ref = normalize(reflect(-dtl, n));
    vec3 spec = pow(max(dot(dtc, ref), 0.0), material.specular_exp) * material.c_specular;

    return ambient + diff + spec;
}

ray_hit raymarch(vec3 ray_origin, vec3 ray_dir) {

    float distance = 0.0f;
    vec3 p;

    for (int i = 0; i < MAX_ITER; i++) {
        p = ray_origin + distance * ray_dir;
        
        surface item = map(p);
        float sdfv = item.sdfv;
        
        if (sdfv < EPSILON) {
            vec3 n = calculate_normal(p);
            return ray_hit(true, p, item.material, n);
        }

        if (distance > MAX_DIST) break;

        distance += sdfv;
    }
    return ray_hit(
        false,
        vec3(0.0),
        material(
            0.0,
            0.0, 
            vec3(0.0), 
            vec3(0.0), 
            vec3(0.0)
        ),
        vec3(0.0)
    );

}

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution - vec2(0.5);
    float asprat = u_resolution.x/u_resolution.y;
    uv.x *= asprat;

    campos = vec3(0.0, 0.0, -8.0);
    ligpos = campos + vec3(0.0, 3.0, 0.0);
    ligpos.xz *= rotate(u_time*.4);
    vec3 screen = vec3(uv, campos.z + 1.0);
    
    vec3 ray_origin = campos;
    vec3 ray_dir = normalize(screen - campos);

    vec3 col = vec3(0.0);
    float reflectance;

    // Work on this. It's wrong as hell
    for (int i = 0; i < 10; i++) {
        vec3 ncol;
        ray_hit result = raymarch(ray_origin, ray_dir);
        // if (!result.hit) ncol = vec3(0.0, 0.5, 0.9); // Or rather, ambient
        if (!result.hit) ncol = vec3(0.2, 0.5, 0.8); // Or rather, ambient
        else ncol = shade(ray_origin, ray_dir, result.p, result.normal, result.material);
        /*
        */
        if (i == 0) {
            col = ncol;
        }
        else {
            if (reflectance < 0.01) break;
            col = mix(
                col, 
                ncol,
                reflectance);
        }
        if (!(result.material.reflectance > 0.1)) break;

        
        ray_dir = normalize(reflect(normalize(result.p - ray_origin), result.normal));
        ray_origin = result.p + EPSILON*result.normal;
        reflectance = result.material.reflectance;
    }

    outColor = vec4(col, 1.0);
}