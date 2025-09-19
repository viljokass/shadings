#version 300 es

precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 outColor;

#define PI 3.1415926538


void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution;

    outColor = vec4(uv, 0.5+sin(u_time)/2.0, 1.0);
    float brdr = sin(u_time)/2.0 + 0.5;
    float brdr2 = sin(u_time * 2.0)/2.0 + 0.5;

    if (uv.y > brdr && uv.y < brdr + 0.01) {
        outColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
    if (uv.x > brdr2 && uv.x < brdr2 + 0.01) {
        outColor = vec4(0.0, 0.0, 0.0, 1.0);
    }
}