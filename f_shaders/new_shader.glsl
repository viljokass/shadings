#version 300 es

precision highp float;

#define PI 3.1415926538

uniform vec2 u_resolution;
uniform float u_time;

out vec4 outColor;

mat2 rotate(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);  
}

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution - vec2(0.5);
    uv *= 2.0;
    outColor = vec4(uv * rotate(u_time), 0.0, 1.0);
}