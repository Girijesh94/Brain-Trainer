// Original lightweight studio-metal material for native 3D meshes.
shader_type spatial;
render_mode unshaded;
uniform vec4 accent : source_color = vec4(0.44, 0.97, 0.80, 1.0);
uniform float phase = 0.0;
void fragment() {
    vec3 n = normalize(NORMAL);
    float strip = sin(n.x * 5.0 + n.y * 2.4 + phase * 0.15);
    float fresnel = pow(1.0 - max(dot(n, normalize(VIEW)), 0.0), 2.0);
    float diffuse = max(dot(n, normalize(vec3(-0.6, 0.8, 1.4))), 0.0);
    vec3 metal = mix(vec3(0.035, 0.05, 0.09), vec3(0.80, 0.90, 0.97), smoothstep(-0.25, 0.30, strip));
    metal *= 0.22 + diffuse * 0.75;
    metal += accent.rgb * fresnel * 0.8;
    metal += vec3(0.85, 0.94, 1.0) * pow(diffuse, 32.0) * 0.8;
    ALBEDO = metal;
}
