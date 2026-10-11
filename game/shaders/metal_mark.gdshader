// Original liquid-metal treatment for the original Quest SVG mask.
shader_type canvas_item;
render_mode unshaded;
uniform float phase = 0.0;
void fragment() {
    vec4 mask = texture(TEXTURE, UV);
    float contour = sin((UV.x * 1.6 + UV.y * 0.6 + sin(UV.y * 9.0 + phase * 0.4) * 0.10) * 18.0 - phase * 0.8);
    float light = smoothstep(-0.75, 0.55, contour);
    vec3 metal = mix(vec3(0.10, 0.15, 0.23), vec3(0.86, 0.97, 1.0), light);
    metal += vec3(0.07, 0.18, 0.14) * pow(max(contour, 0.0), 7.0);
    COLOR = vec4(metal, mask.a);
}
