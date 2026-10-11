extends Control
# Short, non-flashing result sparks. Removed with the result screen.
var elapsed := 0.0
var reduced_motion := false
const COLORS = [Color("8affd5"),Color("d0b3ff"),Color("ffbcdf"),Color("fff2b6")]
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = 110
func _process(delta: float) -> void:
	if not reduced_motion and elapsed < 2.6:
		elapsed += delta
		queue_redraw()
func _draw() -> void:
	var t := 0.35 if reduced_motion else elapsed
	for i in range(28):
		var angle := i * 2.39996
		var travel := 18.0 + minf(t,2.0) * (22 + i % 7 * 7)
		var point := Vector2(size.x * 0.5 + cos(angle) * travel,52 + sin(angle) * travel * 0.45 + t * t * 6)
		var color: Color = COLORS[i % 4]
		color.a = 0.75 * maxf(0.0,1.0 - t / 2.6)
		draw_circle(point,2.0 + i % 3,color)
