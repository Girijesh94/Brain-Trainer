// Original Recall Quest shader. No upstream shader source is used.
shader_type canvas_item;
render_mode unshaded;
uniform float phase = 0.0;
uniform vec2 canvas_size = vec2(420.0, 840.0);
void fragment() {
    vec2 p = (UV - 0.5) * vec2(canvas_size.x / canvas_size.y, 1.0);
    float t = phase * 0.13;
    vec2 a = vec2(0.20 * sin(t), -0.24 + 0.09 * cos(t * 1.1));
    vec2 b = vec2(-0.24 + 0.13 * cos(t * 0.7), 0.18 * sin(t * 0.8));
    vec2 c = vec2(0.24 * cos(t * 0.8), 0.39 + 0.10 * sin(t));
    float wave = sin(p.x * 9.0 + p.y * 7.0 + t) * 0.025;
    float teal = exp(-length(p - a + wave) * 5.4);
    float violet = exp(-length(p - b - wave) * 4.8);
    float rose = exp(-length(p - c) * 6.0);
    vec3 col = vec3(0.018, 0.022, 0.055);
    col += vec3(0.018, 0.30, 0.29) * teal + vec3(0.23, 0.09, 0.43) * violet + vec3(0.24, 0.035, 0.18) * rose;
    float grain = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
    col += (grain - 0.5) * 0.012;
    COLOR = vec4(col, 1.0);
}
