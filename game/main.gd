extends Control

const State = preload("res://state.gd")
const Content = preload("res://content.gd")
const Backdrop = preload("res://background.gd")
const Core = preload("res://memory_core.gd")
const Sparks = preload("res://celebration.gd")
const INK := Color("090c1d")
const SURFACE := Color("161b32")
const SOFT := Color("22283f")
const BORDER := Color("49516c")
const TEXT := Color("edf5ff")
const MUTED := Color("b0c1d8")
const MINT := Color("90ffd5")
const LAVENDER := Color("b6adff")
const GOLD := Color("f8ce80")
const RED := Color("ffb0bd")
const NAMES := {"kim":"Remember objects", "leitner":"Answer flashcards", "blurting":"Retell a story"}
const METHOD := {"kim":"Kim's game", "leitner":"Leitner system", "blurting":"Blurting method"}

var state = State.new()
var background: Control
var shell: MarginContainer
var scroll: ScrollContainer
var body: VBoxContainer
var sound_player: AudioStreamPlayer
var screen := "home"
var daily := false
var session_date := ""
var mode := "kim"
var remaining := -1.0
var timer_total := 0.0
var clock_label: Label
var timer_bar: ProgressBar
var paused := false
var overlay: PanelContainer
var targets: Array = []
var selected: Array = []
var selection_label: Label
var queue: Array = []
var card_index := 0
var card_hits := 0
var card_attempt := ""
var input: TextEdit
var story: Dictionary = {}
var story_answer := ""
var idea_checks: Array = []
var result_score := 0
var result_info := ""
var last_reward: Dictionary = {}
var is_capture := false
var heading_font: Font
var keyboard_height := 0
var page_tween: Tween
var metal_marks: Array[ShaderMaterial] = []
var visual_time := 0.0
var app_suspended := false

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	is_capture = args.has("--capture")
	if is_capture:
		state = State.new("user://capture-progress.json")
	else:
		state.load_progress()
	create_theme()
	background = Backdrop.new()
	add_child(background)
	background.apply_settings(state.data.settings.reduced_motion,state.data.settings.simple_visuals)
	shell = MarginContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shell)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",18)
	scroll.add_child(body)
	resized.connect(update_margins)
	update_margins()
	setup_sound()
	DisplayServer.window_set_title("Recall Quest")
	show_home()
	if is_capture:
		capture.call_deferred(args)

func create_theme() -> void:
	var t := Theme.new()
	t.default_font_size = 18
	if ResourceLoader.exists("res://assets/Outfit.ttf"):
		var regular := FontVariation.new()
		regular.base_font = load("res://assets/Outfit.ttf")
		regular.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):500.0}
		t.default_font = regular
		var bold := FontVariation.new()
		bold.base_font = regular.base_font
		bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):700.0}
		heading_font = bold
	t.set_color("font_color","Label",TEXT)
	t.set_color("font_color","Button",TEXT)
	t.set_color("font_hover_color","Button",TEXT)
	t.set_color("font_pressed_color","Button",TEXT)
	t.set_color("font_focus_color","Button",TEXT)
	t.set_color("font_disabled_color","Button",MUTED)
	t.set_stylebox("normal","Button",box(SOFT,14,BORDER))
	t.set_stylebox("hover","Button",box(Color("29405d"),14,LAVENDER))
	t.set_stylebox("pressed","Button",box(Color("314d64"),14,MINT))
	t.set_stylebox("focus","Button",box(Color.TRANSPARENT,14,MINT,3))
	t.set_stylebox("disabled","Button",box(Color("142139"),14,BORDER))
	t.set_stylebox("panel","PanelContainer",box(SURFACE,20,BORDER))
	t.set_stylebox("normal","TextEdit",box(Color("0e1b2e"),12,BORDER))
	t.set_stylebox("focus","TextEdit",box(Color("0e1b2e"),12,MINT,2))
	t.set_color("font_color","TextEdit",TEXT)
	t.set_color("font_placeholder_color","TextEdit",MUTED)
	t.set_color("caret_color","TextEdit",MINT)
	t.set_color("selection_color","TextEdit",Color("355b6d"))
	t.set_stylebox("background","ProgressBar",box(Color("0e1b2e"),5))
	t.set_stylebox("fill","ProgressBar",box(MINT,5))
	t.set_color("font_color","CheckButton",TEXT)
	t.set_color("font_color","CheckBox",TEXT)
	t.set_stylebox("focus","CheckButton",box(Color.TRANSPARENT,8,MINT,2))
	t.set_stylebox("focus","CheckBox",box(Color.TRANSPARENT,8,MINT,2))
	t.set_constant("separation","VBoxContainer",12)
	t.set_constant("separation","HBoxContainer",12)
	t.set_constant("h_separation","GridContainer",12)
	t.set_constant("v_separation","GridContainer",12)
	theme = t

func box(color: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(width)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func update_margins() -> void:
	if shell == null:
		return
	var h := maxi(20,int((size.x - 620) / 2))
	var top := 18
	var bottom := 20
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var physical := DisplayServer.screen_get_size()
		if physical.y > 0:
			top = maxi(top,int(safe.position.y * size.y / physical.y) + 12)
			bottom = maxi(bottom,int((physical.y - safe.end.y) * size.y / physical.y) + 16)
			bottom = maxi(bottom,int(keyboard_height * size.y / physical.y) + 16)
	shell.add_theme_constant_override("margin_left",h)
	shell.add_theme_constant_override("margin_right",h)
	shell.add_theme_constant_override("margin_top",top)
	shell.add_theme_constant_override("margin_bottom",bottom)

func label(text: String, font_size: int = 18, color: Color = TEXT, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",font_size)
	if font_size >= 23 and heading_font != null:
		l.add_theme_font_override("font",heading_font)
	l.add_theme_color_override("font_color",color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(parent if parent != null else body).add_child(l)
	return l

func button(text: String, action: Callable, parent: Node = null, primary: bool = false, small: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 56
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",17 if small else 19)
	if primary:
		var glowing := box(MINT,18,Color("c5ffe9"))
		glowing.shadow_color = Color(0.22,0.98,0.73,0.18)
		glowing.shadow_size = 14
		b.add_theme_stylebox_override("normal",glowing)
		b.add_theme_stylebox_override("hover",box(Color("c0ffe8"),18))
		b.add_theme_stylebox_override("pressed",box(Color("63dbac"),18))
		b.custom_minimum_size.y = 62
		for property in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			b.add_theme_color_override(property,INK)
	b.pressed.connect(func():
		play_sound()
		action.call()
	)
	(parent if parent != null else body).add_child(b)
	return b

func card(parent: Node = null, color: Color = SURFACE) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",box(color,20,BORDER))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(parent if parent != null else body).add_child(panel)
	glass_surface(panel,color)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation",12)
	panel.add_child(v)
	return v

func glass_surface(panel: Control, color: Color) -> void:
	if state.data.settings.simple_visuals: return
	var glass := ColorRect.new()
	glass.name = "GlassSurface"
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/glass.gdshader")
	mat.set_shader_parameter("tint",Color(color.r,color.g,color.b,0.80))
	glass.material = mat
	# Internal decoration is excluded from container sizing and focus traversal.
	panel.add_child(glass,false,Node.INTERNAL_MODE_FRONT)
	glass.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.resized.connect(func():
		glass.set_deferred("position",Vector2.ZERO)
		glass.set_deferred("size",panel.size)
		mat.set_shader_parameter("panel_size",panel.size)
	)
	panel.sort_children.connect(func():
		glass.set_deferred("position",Vector2.ZERO)
		glass.set_deferred("size",panel.size)
	)
	mat.set_shader_parameter("panel_size",panel.size)

func center_label(text: String, font_size: int = 18, color: Color = TEXT, parent: Node = null) -> Label:
	var l := label(text,font_size,color,parent)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func add_core(height: int = 190) -> Control:
	if state.data.settings.simple_visuals:
		var still := texture("quest-mark",height,body)
		still.name = "StaticCore"
		still.modulate = MINT
		return still
	var core = Core.new()
	core.name = "MemoryCore"
	core.custom_minimum_size.y = height
	core.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	core.reduced_motion = state.data.settings.reduced_motion
	body.add_child(core)
	return core

func animate_entry(control: Control, delay: float = 0.0) -> void:
	if state.data.settings.reduced_motion: return
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(control,"modulate:a",1.0,0.22)

func texture(name: String, dimension: int, parent: Node) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load("res://assets/" + name.to_lower() + ".svg")
	image.custom_minimum_size = Vector2(dimension,dimension)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

func reset_page(new_screen: String, back: Callable = Callable()) -> void:
	remaining = -1
	paused = false
	shell.visible = true
	if is_instance_valid(overlay):
		overlay.queue_free()
	screen = new_screen
	background.apply_settings(state.data.settings.reduced_motion,state.data.settings.simple_visuals)
	background.focus_game(new_screen in ["kim_study","kim_recall","card_question","card_answer","story_study","story_recall","story_check"])
	body.add_theme_constant_override("separation",14)
	metal_marks.clear()
	if page_tween != null and page_tween.is_valid(): page_tween.kill()
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	scroll.scroll_vertical = 0
	var header := HBoxContainer.new()
	body.add_child(header)
	var mark := texture("quest-mark",32,header)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not state.data.settings.reduced_motion and not state.data.settings.simple_visuals:
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/metal_mark.gdshader")
		mark.material = mat
		metal_marks.append(mat)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("separation",0)
	header.add_child(brand)
	brand.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label("RECALL QUEST",15,TEXT,brand)
	if back.is_valid():
		var b := button("Pause" if new_screen in ["kim_study","kim_recall","card_question","card_answer","card_feedback","story_study","story_recall","story_check"] else "Back",back,header,false,true)
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.custom_minimum_size.y = 48
	else:
		var b := button("Settings",show_settings,header,false,true)
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.custom_minimum_size.y = 48
	if not state.warning.is_empty():
		label(state.warning,15,GOLD)
	if not state.data.settings.reduced_motion:
		body.modulate.a = 0.0
		page_tween = create_tween()
		page_tween.tween_property(body,"modulate:a",1.0,0.18)
	else:
		body.modulate.a = 1.0

func nav(active: String) -> void:
	var row := HBoxContainer.new()
	body.add_child(row)
	for entry in [["Play",show_home],["Cards",show_library],["Progress",show_progress]]:
		var b := button(entry[0],entry[1],row,entry[0] == active,true)
		b.custom_minimum_size.y = 56

func show_home() -> void:
	daily = false
	reset_page("home")
	body.add_theme_constant_override("separation",10)
	var progress: Dictionary = state.day_progress()
	var finished := progress.size() == 3
	var next_mode := ""
	for m in State.MODES:
		if not progress.has(m):
			next_mode = m
			break
	center_label("YOUR DAILY MEMORY ARCADE",12,MINT)
	center_label("Make memories stick." if not finished else "Today's quest: complete.",30)
	add_core(180 if size.y < 750 else 220)
	var strip := HBoxContainer.new()
	strip.name = "DailyGames"
	strip.add_theme_constant_override("separation",10)
	body.add_child(strip)
	for m in State.MODES:
		var chip := card(strip)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.add_theme_constant_override("separation",2)
		chip.get_parent().add_theme_stylebox_override("panel",compact_box(SURFACE))
		texture({"kim":"camera","leitner":"book","blurting":"pencil"}[m],38,chip)
		center_label({"kim":"Objects","leitner":"Cards","blurting":"Story"}[m],15,TEXT,chip)
		center_label("✓" if progress.has(m) else str(State.MODES.find(m) + 1),12,MINT if progress.has(m) else MUTED,chip)
	if finished:
		button("PLAY AGAIN  ›",show_practice,null,true)
		center_label("3 / 3 complete  ·  See you tomorrow",14,MINT)
	else:
		var action := "PLAY  ›" if progress.is_empty() else "CONTINUE  ›"
		var primary := button(action,start_daily,null,true)
		primary.name = "DailyStart"
		var hint := center_label("3 games  ·  5–8 min" if progress.is_empty() else str(progress.size()) + " / 3 complete  ·  Next: " + {"kim":"Objects","leitner":"Cards","blurting":"Story"}[next_mode],14,MUTED)
		hint.name = "NextGameHint"
	var help := quiet_button("How to play",show_walkthrough,body)
	help.name = "HowToPlay"
	var footer := HBoxContainer.new()
	body.add_child(footer)
	quiet_button("Cards",show_library,footer)
	quiet_button("Progress",show_progress,footer)
	quiet_button("Practice",show_practice,footer)

func quiet_button(text: String, action: Callable, parent: Node) -> Button:
	var b := button(text,action,parent,false,true)
	b.add_theme_font_size_override("font_size",15)
	b.add_theme_stylebox_override("normal",box(Color.TRANSPARENT,10))
	b.add_theme_color_override("font_color",MUTED)
	b.custom_minimum_size.y = 48
	return b

func show_practice() -> void:
	daily = false
	reset_page("practice",show_home)
	label("Pick your game.",32)
	label("Extra practice · no daily XP",14,MUTED)
	for m in State.MODES:
		var chosen: String = m
		var c := card()
		texture({"kim":"camera","leitner":"book","blurting":"pencil"}[m],60,c)
		label(NAMES[m],24,TEXT,c)
		button("Play " + {"kim":"objects","leitner":"flashcards","blurting":"a story"}[m],func(): show_intro(chosen,false),c)

func show_walkthrough() -> void:
	daily = false
	reset_page("walkthrough_study",show_home)
	center_label("TRY IT  ·  NO TIMER",12,MINT)
	center_label("Remember these three.",30)
	targets = ["Key","Apple","Book"]
	selected = []
	object_grid(targets)
	button("Hide them  ›",show_walkthrough_recall,null,true)
	center_label("Demo · your progress stays the same",14,MUTED)

func show_walkthrough_recall() -> void:
	reset_page("walkthrough_recall",show_home)
	center_label("TAP THE OBJECTS YOU SAW",12,MINT)
	center_label("What was there?",30)
	selection_label = center_label("0 / 3 picked  ·  Tap again to undo",16,MINT)
	object_grid(["Key","Mug","Apple","Book"],true)
	button("Check  ›",show_walkthrough_result,null,true)

func show_walkthrough_result() -> void:
	var hits := 0
	var wrong := 0
	var missed: Array = []
	for item in targets:
		if selected.has(item): hits += 1
		else: missed.append(item)
	for item in selected:
		if not targets.has(item): wrong += 1
	reset_page("walkthrough_result",show_home)
	center_label("LOOK → HIDE → RECALL",12,MINT)
	center_label("You've got the idea.",32)
	center_label(str(hits) + " / 3 remembered" + ("  ·  " + str(wrong) + " extra" if wrong > 0 else ""),20,MINT)
	object_grid(targets)
	if not missed.is_empty():
		label("Missed: " + ", ".join(missed) + ".",17,MUTED)
	center_label("Extra picks lower your score",15,GOLD)
	var progress: Dictionary = state.day_progress()
	if progress.size() < 3:
		button("PLAY  ›" if progress.is_empty() else "CONTINUE  ›",start_daily,null,true)
	else:
		button("PLAY AGAIN  ›",show_practice,null,true)
	button("Try again",show_walkthrough,null,false,true)

func start_daily() -> void:
	var progress = state.day_progress()
	for m in State.MODES:
		if not progress.has(m):
			show_intro(m,true)
			return
	show_home()

func show_intro(chosen: String, is_daily: bool) -> void:
	mode = chosen
	daily = is_daily
	session_date = state.today()
	reset_page("intro",show_home)
	center_label("ROUND " + str(State.MODES.find(mode) + 1) + " / 3" if daily else "PRACTICE",13,MINT)
	center_label(NAMES[mode],30)
	texture({"kim":"camera","leitner":"book","blurting":"pencil"}[mode],130,body)
	var sequence: Array = {"kim":[["camera","Look"],["quest-mark","Hide"],["key","Pick"]],"leitner":[["book","Recall"],["glasses","Reveal"],["star","Check"]],"blurting":[["book","Read"],["pencil","Retell"],["star","Check"]]}[mode]
	var steps := HBoxContainer.new()
	body.add_child(steps)
	for i in range(3):
		var c := card(steps)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.get_parent().add_theme_stylebox_override("panel",compact_box(SURFACE))
		texture(sequence[i][0],44,c)
		center_label(sequence[i][1],16,TEXT,c)
		animate_entry(c.get_parent(),i * 0.08)
	var summary: String = {"kim":str(state.data.kim_level) + " objects · " + str(35 if state.data.settings.slow_study else 20) + " seconds","leitner":"Up to 5 cards · no timer","blurting":"One story · " + str(90 if state.data.settings.slow_study else 60) + " seconds"}[mode]
	center_label(summary,17,MUTED)
	button(start_game_label(),begin_mode,null,true)
	center_label({"kim":"Extra picks lower your score","leitner":"Answer first. Then reveal.","blurting":"Remember ideas, not exact words."}[mode],14,GOLD)

func start_game_label() -> String:
	return "LET'S GO  ›"

func begin_mode() -> void:
	match mode:
		"kim": begin_kim()
		"leitner": begin_leitner()
		"blurting": begin_story()

func game_heading(step: String, title: String, description: String) -> void:
	center_label(step,12,MINT)
	center_label(title,29)
	if not description.is_empty(): center_label(description,15,MUTED)

func start_timer(seconds: float) -> void:
	remaining = seconds
	timer_total = seconds
	var row := HBoxContainer.new()
	body.add_child(row)
	clock_label = label(str(int(ceil(seconds))) + "s",24,MINT,row)
	clock_label.custom_minimum_size.x = 62
	clock_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	timer_bar = ProgressBar.new()
	timer_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	timer_bar.max_value = seconds
	timer_bar.value = seconds
	timer_bar.show_percentage = false
	timer_bar.custom_minimum_size.y = 8
	row.add_child(timer_bar)

func _process(delta: float) -> void:
	if not state.data.settings.reduced_motion and not app_suspended:
		visual_time += delta
		for mark in metal_marks: mark.set_shader_parameter("phase",visual_time)
	if OS.has_feature("mobile"):
		var height := DisplayServer.virtual_keyboard_get_height()
		if height != keyboard_height:
			keyboard_height = height
			update_margins()
	if remaining > 0 and not paused:
		remaining = maxf(0,remaining - delta)
		if is_instance_valid(clock_label):
			clock_label.text = str(int(ceil(remaining))) + "s"
			clock_label.add_theme_color_override("font_color",GOLD if remaining <= 5 else MINT)
		if is_instance_valid(timer_bar):
			timer_bar.value = remaining
		if remaining <= 0:
			if screen == "kim_study": show_kim_recall()
			elif screen == "story_study": show_story_recall()

func object_grid(items: Array, clickable: bool = false) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 4 if size.x >= 660 and items.size() > 6 else 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	for item in items:
		var name: String = item
		if clickable:
			var b := button("",func(): toggle_object(name),grid)
			b.name = "Pick_" + name
			b.toggle_mode = true
			b.custom_minimum_size = Vector2(0,96)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.tooltip_text = name
			b.add_theme_stylebox_override("normal",box(Color(0.09,0.11,0.20,0.86),18,Color("555b76")))
			b.add_theme_stylebox_override("pressed",box(Color("164e46"),18,MINT,2))
			var margin := MarginContainer.new()
			margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
			margin.add_theme_constant_override("margin_top",8)
			margin.add_theme_constant_override("margin_bottom",8)
			b.add_child(margin)
			var v := VBoxContainer.new()
			v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_theme_constant_override("separation",3)
			margin.add_child(v)
			texture(name,54,v)
			var l := label(name,13,TEXT,v)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var tick := Label.new()
			tick.name = "SelectedTick"
			tick.text = "✓"
			tick.add_theme_color_override("font_color",MINT)
			tick.add_theme_font_size_override("font_size",18)
			tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tick.position = Vector2(8,3)
			tick.visible = false
			b.add_child(tick)
			animate_entry(b,grid.get_child_count() * 0.025)
		else:
			var c := card(grid,Color("152840"))
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var tile_style := box(Color("152840"),16,BORDER)
			tile_style.content_margin_top = 8
			tile_style.content_margin_bottom = 8
			tile_style.content_margin_left = 8
			tile_style.content_margin_right = 8
			c.get_parent().add_theme_stylebox_override("panel",tile_style)
			c.add_theme_constant_override("separation",4)
			texture(name,66,c)
			var l := label(name,14,TEXT,c)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			animate_entry(c.get_parent(),grid.get_child_count() * 0.025)
	return grid

func begin_kim() -> void:
	var pool: Array = Content.OBJECTS.duplicate()
	pool.shuffle()
	targets = pool.slice(0,int(state.data.kim_level))
	selected = []
	reset_page("kim_study",confirm_leave)
	game_heading("ROUND 1 · OBJECTS" if daily else "OBJECTS","Look. Remember.","")
	start_timer(35 if state.data.settings.slow_study else 20)
	object_grid(targets)
	button("Hide objects  ›",show_kim_recall,null,true)

func show_kim_recall() -> void:
	reset_page("kim_recall",confirm_leave)
	game_heading("OBJECTS · RECALL","Pick what you saw.","Extra picks lower your score")
	selection_label = center_label("0 / " + str(targets.size()) + " picked",17,MINT)
	var extras: Array = Content.OBJECTS.filter(func(o): return not targets.has(o))
	extras.shuffle()
	var options: Array = targets.duplicate()
	options.append_array(extras.slice(0,mini(6,targets.size())))
	options.shuffle()
	object_grid(options,true)
	button("CHECK  ›",finish_kim,null,true)
	center_label("No timer · tap again to undo",13,MUTED)

func toggle_object(name: String) -> void:
	if selected.has(name):
		selected.erase(name)
	else:
		selected.append(name)
	selection_label.text = str(selected.size()) + " / " + str(targets.size()) + " picked"
	var pick := body.find_child("Pick_" + name,true,false)
	if pick != null:
		pick.button_pressed = selected.has(name)
		pick.get_node("SelectedTick").visible = selected.has(name)

func finish_kim() -> void:
	var hits := 0
	var misses: Array = []
	var wrong: Array = []
	for item in targets:
		if selected.has(item): hits += 1
		else: misses.append(item)
	for item in selected:
		if not targets.has(item): wrong.append(item)
	result_info = str(hits) + " / " + str(targets.size()) + " remembered"
	if not misses.is_empty(): result_info += "\nMissed: " + ", ".join(misses)
	if not wrong.is_empty(): result_info += "\nExtra picks: " + ", ".join(wrong)
	finish_round(State.kim_score(targets,selected))

func begin_leitner() -> void:
	queue = state.review_queue(5,not daily,session_date)
	card_index = 0
	card_hits = 0
	if queue.is_empty():
		reset_page("cards_empty",show_home)
		texture("star",100,body)
		center_label("Cards: all caught up.",30)
		center_label("Nothing due today",18,MUTED)
		if daily:
			button("Continue  ›",func():
				result_info = "No cards due · schedule checked"
				finish_round(-1)
			,null,true)
		else:
			button("Back to home",show_home,null,true)
		return
	show_flashcard()

func show_flashcard() -> void:
	card_attempt = ""
	reset_page("card_question",confirm_leave)
	game_heading("ROUND 2 · CARDS" if daily else "CARDS","Know this one?","")
	var flash: Dictionary = queue[card_index]
	center_label(str(card_index + 1) + " / " + str(queue.size()),14,LAVENDER)
	var c := card(null,Color("242643"))
	texture("book",64,c)
	center_label(flash.q,25,TEXT,c)
	input = make_input("Your answer…",90)
	button("REVEAL  ›",reveal_flashcard,null,true)
	button("Don't know",func():
		input.text = ""
		reveal_flashcard()
	,null,false,true)
	if not state.is_due(flash.id,session_date):
		center_label("Early practice · schedule unchanged",14,GOLD)

func make_input(placeholder: String, height: int) -> TextEdit:
	var field := TextEdit.new()
	field.placeholder_text = placeholder
	field.custom_minimum_size.y = height
	field.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.virtual_keyboard_enabled = true
	body.add_child(field)
	return field

func reveal_flashcard() -> void:
	card_attempt = input.text.strip_edges().left(1000)
	reset_page("card_answer",confirm_leave)
	var flash: Dictionary = queue[card_index]
	var suggested := Content.correct_answer(flash,card_attempt)
	center_label("CARDS · SELF-CHECK",13,LAVENDER)
	center_label("How did you do?",29)
	var c := card()
	label("YOU WROTE",12,MUTED,c)
	label(card_attempt if not card_attempt.is_empty() else "I don't remember",20,TEXT,c)
	label("ANSWER",12,MINT,c)
	label(flash.a,30,MINT,c)
	center_label("Same meaning counts. Be honest.",15,MUTED)
	var yes := button("✓  Got it",func(): mark_card(true),null,suggested)
	yes.disabled = card_attempt.is_empty()
	button("↻  Review again",func(): mark_card(false),null,not suggested)
	if card_attempt.is_empty():
		center_label("No answer · try this card again later",14,GOLD)

func mark_card(correct: bool) -> void:
	var flash: Dictionary = queue[card_index]
	var review_info = state.review(flash.id,correct,session_date)
	if correct: card_hits += 1
	reset_page("card_feedback",confirm_leave)
	texture("star" if correct else "book",100,body)
	center_label("Nice recall!" if correct else "You'll see it again.",32)
	center_label(flash.a,26,MINT)
	if review_info.advanced:
		center_label("Next review · " + review_info.due,17,LAVENDER)
	else:
		center_label("Still due · " + review_info.due,17,LAVENDER)
	var ladder := HBoxContainer.new()
	body.add_child(ladder)
	for i in range(1,6):
		var rung := card(ladder,Color("164e46") if review_info.box >= i else SURFACE)
		rung.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rung.get_parent().add_theme_stylebox_override("panel",compact_box(SURFACE))
		center_label(str(State.INTERVALS[i - 1]) + "d",14,MINT if review_info.box >= i else MUTED,rung)
	button("NEXT  ›" if card_index + 1 < queue.size() else "FINISH  ›",next_card,null,true)

func next_card() -> void:
	card_index += 1
	if card_index < queue.size():
		show_flashcard()
	else:
		result_info = str(card_hits) + " / " + str(queue.size()) + " remembered · self-check"
		finish_round(int(round(100.0 * card_hits / queue.size())))

func begin_story() -> void:
	var index := state.day_number(session_date) % Content.STORIES.size() if daily else randi() % Content.STORIES.size()
	story = Content.STORIES[index].duplicate(true)
	story_answer = ""
	reset_page("story_study",confirm_leave)
	game_heading("ROUND 3 · STORY" if daily else "STORY","Picture the scene.","")
	start_timer(90 if state.data.settings.slow_study else 60)
	var c := card(null,Color("292b3a"))
	texture("pencil",46,c)
	label(story.title,23,GOLD,c)
	var text := label(story.body,22,TEXT,c)
	text.add_theme_constant_override("line_spacing",8)
	button("Hide story  ›",show_story_recall,null,true)

func show_story_recall() -> void:
	reset_page("story_recall",confirm_leave)
	game_heading("STORY · RECALL","What happened?","Your own words · no timer")
	input = make_input("Who? Where? What happened?",240)
	var b := button("CHECK  ›",show_story_check,null,true)
	b.disabled = true
	input.text_changed.connect(func(): b.disabled = input.text.strip_edges().is_empty())

func show_story_check() -> void:
	story_answer = input.text.strip_edges().left(10000)
	if story_answer.is_empty():
		return
	reset_page("story_check",confirm_leave)
	center_label("STORY · SELF-CHECK",13,GOLD)
	center_label("Which did you recall?",29)
	center_label("Suggested ticks · keep only what you remembered",15,MUTED)
	var answer := card()
	label("YOUR RECALL",12,LAVENDER,answer)
	label(story_answer,18,TEXT,answer)
	idea_checks = []
	var suggestions := Content.suggested_ideas(story,story_answer)
	for i in range(story.ideas.size()):
		var c := card()
		var check := CheckBox.new()
		check.text = "Idea " + str(i + 1)
		check.button_pressed = suggestions[i]
		check.custom_minimum_size.y = 48
		c.add_child(check)
		label(story.ideas[i].label,18,TEXT,c)
		idea_checks.append(check)
	button("FINISH  ›",finish_story,null,true)
	var original := card()
	label("ORIGINAL STORY",12,GOLD,original)
	label(story.body,17,MUTED,original)

func finish_story() -> void:
	var hits := 0
	for check in idea_checks:
		if check.button_pressed: hits += 1
	result_info = str(hits) + " / 5 ideas remembered · self-check"
	finish_round(hits * 20)

func finish_round(score: int) -> void:
	result_score = score
	last_reward = state.record(mode,score,daily,session_date)
	if state.data.settings.sound:
		play_sound(660)
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(35)
	show_result()

func show_result() -> void:
	reset_page("result",show_home)
	center_label("ROUND COMPLETE",13,MINT)
	var sparks = Sparks.new()
	sparks.reduced_motion = state.data.settings.reduced_motion
	body.add_child(sparks)
	var star := texture("star",86,sparks)
	star.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_label("Nice recall!" if result_score >= 80 else "Keep the spark going.",30)
	var c := card()
	var score := center_label(str(result_score) + "%" if result_score >= 0 else "Ready",64,MINT,c)
	center_label("Schedule checked" if result_score < 0 else ("Self-checked recall" if mode != "kim" else "Object recall"),13,MUTED,c)
	center_label(result_info.split("\n")[0],17,TEXT,c)
	if result_score >= 0 and not state.data.settings.reduced_motion:
		var count_up := score.create_tween()
		count_up.tween_method(func(value: float): score.text = str(int(round(value))) + "%",0.0,float(result_score),0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if result_info.contains("\n"):
		var details := label(result_info,15,MUTED,c)
		details.visible = false
		quiet_button("Show details",func(): details.visible = not details.visible,c)
	if last_reward.get("xp",0) > 0:
		center_label("+" + str(last_reward.xp) + " XP" + ("  ·  Daily bonus!" if last_reward.daily_bonus else ""),21,MINT)
	else:
		center_label("Practice saved",15,MUTED)
	if daily and not state.complete(session_date):
		button("NEXT GAME  ›",start_daily,null,true)
	else:
		if daily:
			center_label("3 / 3 done  ·  " + str(state.streak()) + " day streak",17,GOLD)
		button("HOME  ›",show_home,null,true)
	quiet_button("Play again",func(): show_intro(mode,false),body)

func show_library() -> void:
	reset_page("library")
	nav("Cards")
	label("Your cards.",32)
	button("+  Add a card",show_add_card,null,true)
	var counts := [0,0,0,0,0]
	var new_count := 0
	var due_count := 0
	for c in state.cards():
		if state.data.cards.has(c.id):
			counts[int(state.card_state(c.id).box) - 1] += 1
			if state.is_due(c.id): due_count += 1
		else: new_count += 1
	var summary := card()
	label(str(due_count) + " due  ·  " + str(new_count) + " new",23,LAVENDER,summary)
	for i in range(5):
		label("Box " + str(i + 1) + "  ·  " + str(State.INTERVALS[i]) + "-day interval  ·  " + str(counts[i]) + " cards",17,TEXT,summary)
	button("Practise flashcards",func(): show_intro("leitner",false),null,false,true)
	label("PERSONAL CARDS",13,MINT)
	if state.data.custom_cards.is_empty():
		label("No personal cards yet. Try a person's name, a word you're learning, or a useful fact.",17,MUTED)
	for c in state.data.custom_cards:
		var panel := card()
		label(c.q,20,TEXT,panel)
		label(c.a,18,MINT,panel)
		var status = state.card_state(c.id)
		label("New" if not state.data.cards.has(c.id) else "Box " + str(status.box) + "  ·  Due " + status.due,14,MUTED,panel)

func show_add_card() -> void:
	reset_page("add_card",show_library)
	label("Make it personal.",32)
	label("One clear question, one short answer. Personal cards are stored only on this device.",17,MUTED)
	label("Question",17,LAVENDER)
	var question := make_input("For example: What is the Spanish word for apple?",110)
	label("Answer",17,MINT)
	var answer := make_input("For example: Manzana",95)
	var helper := label("Keep each field within 300 characters.",15,MUTED)
	button("Save this card",func():
		if question.text.strip_edges().is_empty() or answer.text.strip_edges().is_empty():
			helper.text = "Please enter both a question and an answer."
			helper.add_theme_color_override("font_color",RED)
		elif question.text.length() > 300 or answer.text.length() > 300:
			helper.text = "Please shorten each field to 300 characters or fewer."
			helper.add_theme_color_override("font_color",RED)
		elif state.add_card(question.text,answer.text):
			show_library()
		else:
			helper.text = "Card could not be saved. Check storage or the 200-card limit."
	,null,true)

func show_progress() -> void:
	reset_page("progress")
	nav("Progress")
	label("Your progress.",32)
	var c := card()
	label("Level " + str(1 + int(state.data.xp / 300)) + "  ·  " + str(state.data.xp) + " XP",28,MINT,c)
	var bar := ProgressBar.new()
	bar.value = int(state.data.xp) % 300
	bar.max_value = 300
	bar.show_percentage = false
	bar.custom_minimum_size.y = 10
	c.add_child(bar)
	label(str(300 - int(state.data.xp) % 300) + " XP to the next level",16,MUTED,c)
	label("LAST SEVEN DAYS",13,LAVENDER)
	var calendar := HBoxContainer.new()
	body.add_child(calendar)
	var current := state.day_number(state.today())
	for offset in range(6,-1,-1):
		var date := state.day_string(current - offset)
		var day := card(calendar,Color("1e403d") if state.complete(date) else SURFACE)
		day.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Compact day cells use a smaller padding so they fit a phone screen.
		day.get_parent().add_theme_stylebox_override("panel",compact_box(Color("1e403d") if state.complete(date) else SURFACE))
		var l := label(date.right(2),15,TEXT,day)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var count := label(str(state.day_progress(date).size()) + "/3",12,MINT,day)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for m in State.MODES:
		var scores: Array = []
		for h in state.data.history:
			if h.mode == m: scores.append(h.score)
		var recent := scores.slice(-7)
		var total := 0.0
		for value in recent: total += value
		var summary := card()
		label(NAMES[m],22,TEXT,summary)
		label(str(int(round(total / recent.size()))) + "% average across last " + str(recent.size()) + " rounds" if not recent.is_empty() else "No completed rounds yet",17,MUTED,summary)
		if m == "kim": label("Current challenge: " + str(state.data.kim_level) + " objects",16,MINT,summary)
	label("RECENT ROUNDS",13,GOLD)
	if state.data.history.is_empty(): label("Your first completed game will appear here.",17,MUTED)
	var history: Array = state.data.history.slice(-10)
	history.reverse()
	for h in history:
		label(h.date + "  ·  " + NAMES[h.mode] + "  ·  " + str(h.score) + "%" + ("  ·  Daily" if h.daily else "  ·  Practice"),15,MUTED)

func compact_box(color: Color) -> StyleBoxFlat:
	var style := box(color,10,BORDER)
	style.content_margin_left = 3
	style.content_margin_right = 3
	return style

func show_settings() -> void:
	reset_page("settings",show_home)
	label("Your settings.",32)
	var c := card()
	setting_toggle("Gentle sound effects","sound",c)
	setting_toggle("Reduce all motion","reduced_motion",c)
	setting_toggle("Simple visuals","simple_visuals",c)
	setting_toggle("Longer study timers","slow_study",c)
	label("Longer timers: 35 seconds for objects and 90 seconds for stories. Recall itself is always untimed.",16,MUTED,c)
	var help := card()
	label("WHAT THIS GAME TRAINS",13,MINT,help)
	label("The object game practises observation and recall. Flashcards use retrieval and spaced review. Retelling a story practises recalling meaning and details.",18,TEXT,help)
	label("The game does not promise photographic memory or a general increase in brain capacity. Flashcard and story scores include your own honest assessment.",16,MUTED,help)
	label("OFFLINE BY DESIGN",13,LAVENDER,help)
	label("No account, ads or internet required. Progress stays on this device and does not automatically sync to another device.",17,TEXT,help)
	label("Tab moves focus. Enter or Space activates buttons. Escape pauses a game or returns to the home screen.",16,MUTED,help)
	button("Credits & licences",show_credits,null,false,true)
	button("Back to home",show_home,null,true)

func show_credits() -> void:
	reset_page("credits",show_settings)
	label("Made for a little daily practice.",31)
	label("Original game text, stories, object illustrations and the Recall Quest mascot were created for this game.",18,MUTED)
	label("Built with Godot Engine 4.6.3, available under the MIT licence. Outfit by Rodrigo Fuenzalida is available under the SIL Open Font License.",18,TEXT)
	label("THIRD-PARTY LICENCES",13,MINT)
	var licences := TextEdit.new()
	licences.editable = false
	licences.virtual_keyboard_enabled = false
	licences.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	licences.custom_minimum_size.y = 340
	licences.add_theme_font_size_override("font_size",14)
	for file in ["GODOT_LICENSE.txt","OFL.txt","GODOT_COPYRIGHT.txt"]:
		licences.text += file + "\n\n" + FileAccess.get_file_as_string("res://assets/" + file) + "\n\n"
	body.add_child(licences)
	button("Back to settings",show_settings,null,true)

func setting_toggle(text: String, key: String, parent: Node) -> void:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.custom_minimum_size.y = 52
	toggle.button_pressed = state.data.settings[key]
	parent.add_child(toggle)
	toggle.toggled.connect(func(enabled):
		state.data.settings[key] = enabled
		background.apply_settings(state.data.settings.reduced_motion,state.data.settings.simple_visuals)
		# Reduced motion changes are applied to every effect, including the logo.
		if key in ["reduced_motion","simple_visuals"]:
			show_settings()
		state.save()
	)

func pause_game() -> void:
	if paused or is_instance_valid(overlay):
		return
	paused = true
	background.suspended = true
	shell.visible = false
	overlay = PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel",box(INK,0))
	add_child(overlay)
	var center := CenterContainer.new()
	overlay.add_child(center)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",24)
	margin.add_theme_constant_override("margin_right",24)
	center.add_child(margin)
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = minf(390,size.x - 48)
	margin.add_child(v)
	texture("mascot",120,v)
	label("Paused.",34,TEXT,v)
	button("RESUME  ›",resume_game,v,true)
	button("Leave round",func():
		resume_game()
		show_home()
	,v,false,true)

func resume_game() -> void:
	paused = false
	background.suspended = app_suspended
	shell.visible = true
	if is_instance_valid(overlay):
		overlay.queue_free()
		overlay = null

func confirm_leave() -> void:
	pause_game()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if paused: resume_game()
		elif screen in ["kim_study","kim_recall","card_question","card_answer","card_feedback","story_study","story_recall","story_check"]: pause_game()
		else: show_home()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		app_suspended = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		app_suspended = false
	if what == NOTIFICATION_APPLICATION_PAUSED and is_instance_valid(shell) and screen in ["kim_study","story_study"]:
		pause_game()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if paused: resume_game()
		elif screen == "home": get_tree().quit()
		elif screen in ["kim_study","kim_recall","card_question","card_answer","card_feedback","story_study","story_recall","story_check"]: pause_game()
		else: show_home()

func setup_sound() -> void:
	sound_player = AudioStreamPlayer.new()
	sound_player.volume_db = -20
	add_child(sound_player)

func play_sound(frequency: float = 440.0) -> void:
	if not state.data.settings.sound or sound_player == null:
		return
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = 22050
	var samples := PackedByteArray()
	var count := 2205
	samples.resize(count * 2)
	for i in range(count):
		var amplitude := sin(TAU * frequency * i / 22050.0) * pow(1.0 - float(i)/count,2) * 12000
		samples.encode_s16(i * 2,int(amplitude))
	audio.data = samples
	sound_player.stream = audio
	sound_player.play()

func capture(args: PackedStringArray) -> void:
	var destination := ""
	var scene := "home"
	for i in range(args.size() - 1):
		if args[i] == "--output": destination = args[i + 1]
		if args[i] == "--scene": scene = args[i + 1]
	mode = "kim"
	daily = true
	session_date = state.today()
	match scene:
		"intro": show_intro("kim",true)
		"tutorial": show_walkthrough()
		"tutorial-recall":
			targets = ["Key","Apple","Book"]
			selected = []
			show_walkthrough_recall()
		"home-resume":
			state.data.days[state.today()] = {"kim":80}
			show_home()
		"home-complete":
			state.data.days[state.today()] = {"kim":80,"leitner":60,"blurting":80}
			show_home()
		"kim": begin_kim()
		"recall":
			targets = ["Key","Apple","Book","Turtle","Rocket"]
			show_kim_recall()
		"card":
			mode = "leitner"
			begin_leitner()
		"story":
			mode = "blurting"
			begin_story()
		"progress": show_progress()
		"result":
			result_score = 100
			result_info = "5 / 5 remembered"
			last_reward = {"xp":70,"daily_bonus":false}
			show_result()
		"recall-picked":
			targets = ["Key","Apple","Book","Turtle","Rocket"]
			show_kim_recall()
			for object in ["Key","Book"]: toggle_object(object)
		"home-still":
			state.data.settings.reduced_motion = true
			background.reduced_motion = true
			show_home()
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	if not destination.is_empty():
		get_viewport().get_texture().get_image().save_png(destination)
		print("Saved native screenshot: " + destination)
	get_tree().quit()
