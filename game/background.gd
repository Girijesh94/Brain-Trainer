extends Control
var elapsed := 0.0
var reduced_motion := false
var suspended := false
var simple_visuals := false
var flow: ShaderMaterial
var veil: ColorRect
var fill: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill = ColorRect.new()
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow = ShaderMaterial.new()
	flow.shader = preload("res://shaders/aurora.gdshader")
	fill.material = flow
	add_child(fill)
	veil = ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.color = Color(0.018,0.022,0.055,0.0)
	add_child(veil)
	resized.connect(func(): flow.set_shader_parameter("canvas_size",size))
	flow.set_shader_parameter("canvas_size",size)

func focus_game(focused: bool) -> void:
	veil.color.a = 0.42 if focused else 0.0

func apply_settings(reduced: bool, simple: bool) -> void:
	reduced_motion = reduced
	simple_visuals = simple
	fill.material = null if simple else flow
	fill.color = Color("090c1d") if simple else Color.WHITE

func _process(delta: float) -> void:
	if not reduced_motion and not suspended and not simple_visuals:
		elapsed += delta
		flow.set_shader_parameter("phase",elapsed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		suspended = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		suspended = false
