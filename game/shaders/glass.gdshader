// Original native refraction; decoration stays behind opaque UI text.
shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform vec2 panel_size = vec2(200.0, 120.0);
uniform float radius = 21.0;
uniform vec4 tint : source_color = vec4(0.06, 0.075, 0.15, 0.76);
void fragment() {
    vec2 p = (UV - 0.5) * panel_size;
    vec2 q = abs(p) - panel_size * 0.5 + radius;
    float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    float mask = 1.0 - smoothstep(-1.0, 1.0, d);
    float rim = 1.0 - smoothstep(0.0, 5.0, abs(d));
    vec2 bend = normalize(p + vec2(0.001)) * rim * 3.0 * SCREEN_PIXEL_SIZE;
    vec2 sample_uv = SCREEN_UV - bend;
    vec3 scene = texture(screen_texture, sample_uv).rgb * 0.5;
    scene += texture(screen_texture, sample_uv + SCREEN_PIXEL_SIZE * vec2(2.0, 2.0)).rgb * 0.25;
    scene += texture(screen_texture, sample_uv - SCREEN_PIXEL_SIZE * vec2(2.0, 2.0)).rgb * 0.25;
    vec3 col = mix(scene, tint.rgb, tint.a);
    float sheen = pow(max(0.0, 1.0 - UV.y), 3.0) * 0.04;
    col += vec3(sheen) + rim * vec3(0.13, 0.20, 0.23) * (0.35 + UV.y * 0.20);
    COLOR = vec4(col, mask);
}
