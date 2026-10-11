extends SubViewportContainer
# Real native 3D, bounded to 480 x 320 pixels; no browser or remote assets.
var reduced_motion := false
var suspended := false
var elapsed := 0.0
var stage: SubViewport
var sculpture: Node3D
var materials: Array[ShaderMaterial] = []
var pulse := 0.0
var on_screen := true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	stretch = true
	stretch_shrink = 2
	stage = SubViewport.new()
	stage.transparent_bg = true
	stage.own_world_3d = true
	stage.size = Vector2i(240,160)
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage.msaa_3d = Viewport.MSAA_2X
	add_child(stage)
	var world := Node3D.new()
	stage.add_child(world)
	var camera := Camera3D.new()
	camera.position = Vector3(0,0,5.0)
	camera.fov = 35
	world.add_child(camera)
	sculpture = Node3D.new()
	sculpture.rotation = Vector3(0.30,0.15,0.36)
	world.add_child(sculpture)
	for i in range(3):
		var mesh := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.83
		ring.outer_radius = 1.06
		ring.rings = 48
		ring.ring_segments = 12
		mesh.mesh = ring
		mesh.rotation = Vector3(PI * 0.5 if i == 0 else 0.0, PI * 0.5 if i == 2 else 0.0,0)
		mesh.material_override = metal([Color("80ffcf"),Color("b3a0ff"),Color("ffaddb")][i])
		sculpture.add_child(mesh)
	var nucleus := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.37
	sphere.height = 0.74
	sphere.radial_segments = 32
	sphere.rings = 16
	nucleus.mesh = sphere
	nucleus.material_override = metal(Color("75ffdc"))
	sculpture.add_child(nucleus)
	for i in range(8):
		var satellite := MeshInstance3D.new()
		var dot := SphereMesh.new()
		dot.radius = 0.035 if i % 2 == 0 else 0.06
		dot.height = dot.radius * 2
		dot.radial_segments = 12
		dot.rings = 6
		satellite.mesh = dot
		satellite.position = Vector3(cos(i * TAU / 8) * 1.36,sin(i * TAU / 8) * 1.20,sin(i * 2.1) * 0.25)
		satellite.material_override = materials[i % 3]
		sculpture.add_child(satellite)
	resized.connect(fit_view)
	fit_view()
	gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not reduced_motion:
			pulse = 1.0
	)
	refresh_motion()

func metal(accent: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/core_metal.gdshader")
	mat.set_shader_parameter("accent",accent)
	materials.append(mat)
	return mat

func fit_view() -> void:
	# Limit rendering resolution even on large or high-density displays.
	stretch_shrink = maxi(1,int(ceil(maxf(size.x / 480.0,size.y / 320.0))))

func refresh_motion() -> void:
	if stage == null: return
	stage.render_target_update_mode = SubViewport.UPDATE_ONCE if reduced_motion or suspended else SubViewport.UPDATE_ALWAYS

func _process(delta: float) -> void:
	var visible_now := is_visible_in_tree() and get_global_rect().intersects(get_viewport().get_visible_rect())
	if on_screen != visible_now:
		on_screen = visible_now
		if on_screen: refresh_motion()
		else: stage.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if not on_screen: return
	if not reduced_motion and not suspended:
		elapsed += delta
		pulse = maxf(0.0,pulse - delta * 1.7)
		sculpture.rotation = Vector3(0.30 + sin(elapsed * 0.3) * 0.12,elapsed * 0.19 + pulse * 0.45,0.36 + sin(elapsed * 0.4) * 0.1)
		sculpture.position.y = sin(elapsed * 0.9) * 0.045
		sculpture.scale = Vector3.ONE * (1.0 + pulse * 0.10)
		for mat in materials: mat.set_shader_parameter("phase",elapsed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		suspended = true
		refresh_motion()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		suspended = false
		refresh_motion()
