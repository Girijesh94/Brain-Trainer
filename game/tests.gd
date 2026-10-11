extends SceneTree

const State = preload("res://state.gd")
const Content = preload("res://content.gd")
const Main = preload("res://main.tscn")
var checks := 0
var failures: Array = []

func _initialize() -> void:
	run.call_deferred()

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func fresh_state(name: String = "test"):
	var s = State.new("user://" + name + "-" + str(Time.get_ticks_usec()) + ".json")
	return s

func cleanup(s) -> void:
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(s.save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(s.save_path + suffix))

func click_text(game: Node, text: String) -> bool:
	var pending: Array = [game.body]
	while not pending.is_empty():
		var node = pending.pop_back()
		if node is Button and node.text == text:
			node.pressed.emit()
			return true
		pending.append_array(node.get_children())
	return false

func word_count(node: Node) -> int:
	var count := 0
	if node is Label or node is Button:
		count += node.text.replace("\n"," ").split(" ",false).size()
	for child in node.get_children(): count += word_count(child)
	return count

func run() -> void:
	var s = fresh_state()
	var d := "2026-10-09"
	expect(s.day_string(s.day_number(d) + 1) == "2026-10-10","Date advances by calendar day")
	expect(s.day_string(s.day_number("2026-12-31") + 1) == "2027-01-01","Year rollover")
	expect(s.day_string(s.day_number("2028-02-28") + 1) == "2028-02-29","Leap day rollover")
	expect(State.kim_score(["Key","Book"],["Key","Book"]) == 100,"Perfect object recall")
	expect(State.kim_score(["Key","Book"],["Key","Apple"]) == 0,"Wrong picks penalise score")
	expect(State.kim_score(["Key","Book"],["Key","Key"]) == 50,"Duplicate selections cannot inflate score")
	expect(State.kim_score(["Key","Book"],[]) == 0,"Empty recall")
	expect(Content.correct_answer(Content.CARDS[0],"  MARS!  "),"Answer normalisation")
	expect(not Content.correct_answer(Content.CARDS[0],""),"Blank answers cannot count")
	expect(not Content.correct_answer(Content.CARDS[0],"Marseille"),"Substring answers cannot count as a flashcard match")
	expect(s.review_queue(5,false,d).size() == 5,"A small new-card queue")
	expect(s.is_due("space",s.day_string(s.day_number(s.today()) - 1)),"A new card remains reviewable if a session crosses midnight")
	var reviewed = s.review("space",true,d)
	expect(reviewed.box == 2 and reviewed.due == "2026-10-12","Correct due card moves to 3-day box")
	var early = s.review("space",true,"2026-10-10")
	expect(not early.advanced and early.due == "2026-10-12" and early.box == 2,"Early review does not advance schedule")
	var missed = s.review("space",false,"2026-10-12")
	expect(missed.box == 1 and missed.due == "2026-10-13","Missed card returns to daily box")
	s.data.cards.space = {"box":5,"due":d}
	var top = s.review("space",true,d)
	expect(top.box == 5 and top.due == "2026-11-08","Top box stays at 30-day interval")
	s.data.cards.bee = {"box":2,"due":"2026-10-05"}
	expect(s.review_queue(1,false,d)[0].id == "bee","Overdue reviews precede new cards")
	var reward = s.record("kim",80,true,d)
	expect(reward.xp == 60,"First daily mission grants XP")
	expect(s.record("kim",100,true,d).xp == 0,"Repeating daily mission cannot farm XP")
	expect(s.day_progress(d).kim == 80,"First daily score remains stable")
	s.record("leitner",60,true,d)
	var bonus = s.record("blurting",100,true,d)
	expect(bonus.daily_bonus and bonus.xp == 120,"Daily bonus only on three completed missions")
	expect(s.streak(d) == 1,"One completed day has a streak")
	expect(s.streak("2026-10-10") == 1,"Streak remains available while next day is unfinished")
	expect(s.streak("2026-10-11") == 0,"Missing a whole calendar day breaks streak")
	expect(s.day_progress("2026-10-10").is_empty(),"Daily progress resets on new date")
	var saved = State.new(s.save_path)
	saved.load_progress()
	expect(saved.data.xp == s.data.xp and saved.complete(d),"Progress persists after restart")
	expect(saved.data.cards.space.due == "2026-11-08","Spaced schedule persists")
	var f := FileAccess.open(s.save_path,FileAccess.WRITE)
	f.store_string("broken json")
	f.close()
	var recovered = State.new(s.save_path)
	recovered.load_progress()
	expect(not recovered.warning.is_empty() and recovered.data.xp > 0,"Corrupt save recovers prior backup")
	expect(s.add_card("My favourite fruit?","Pear"),"Personal card saves")
	expect(not s.add_card("","Pear"),"Personal card needs question")
	expect(s.cards().size() == Content.CARDS.size() + 1,"Personal cards join starter deck")
	var adaptive = fresh_state("adaptive")
	for i in range(3): adaptive.record("kim",100,false,d)
	expect(adaptive.data.kim_level == 6,"Three strong rounds raise challenge")
	adaptive.record("kim",100,false,d)
	expect(adaptive.data.kim_level == 6,"A new difficulty needs its own strong rounds")
	for i in range(3): adaptive.record("kim",20,false,d)
	expect(adaptive.data.kim_level == 5,"Three struggling rounds lower challenge")
	var no_due = fresh_state("check")
	no_due.record("leitner",-1,true,d)
	expect(no_due.day_progress(d).leitner == -1 and no_due.data.history.is_empty(),"Schedule check completes day without a fake recall score")
	var suggestions = Content.suggested_ideas(Content.STORIES[0],Content.STORIES[0].body)
	expect(suggestions.all(func(v): return v),"Full story supplies all suggested ideas")
	expect(Content.suggested_ideas(Content.STORIES[0],"").all(func(v): return not v),"Blank story recall supplies no ideas")
	# Exercise actual scene callbacks and buttons, using a separate save.
	var game = Main.instantiate()
	root.add_child(game)
	await process_frame
	game.state = fresh_state("ui")
	game.state.data.settings.sound = false
	game.state.data.settings.reduced_motion = true
	game.show_home()
	expect(game.screen == "home","Native home screen loads")
	expect(word_count(game.body) <= 45,"Home stays within a 45-word budget")
	var core = game.body.find_child("MemoryCore",true,false)
	expect(core != null and core.sculpture.get_child_count() == 12,"Home includes a real native 3D memory core")
	expect(core.stage.size.x <= 480 and core.stage.size.y <= 320,"3D rendering resolution is capped")
	expect(core.stage.render_target_update_mode == SubViewport.UPDATE_ONCE,"Reduced motion renders a static core")
	core.visible = false
	core._process(0.0)
	expect(core.stage.render_target_update_mode == SubViewport.UPDATE_DISABLED,"Hidden 3D scenes stop rendering")
	core.visible = true
	core._process(0.0)
	expect(core.stage.render_target_update_mode == SubViewport.UPDATE_ONCE,"A revealed static scene renders once")
	core.reduced_motion = false
	core.refresh_motion()
	core._process(1.0)
	expect(core.elapsed > 0 and core.stage.render_target_update_mode == SubViewport.UPDATE_ALWAYS,"Normal graphics animate the native 3D scene")
	core._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var core_time: float = core.elapsed
	core._process(1.0)
	expect(core.elapsed == core_time,"Unfocused 3D animation is suspended")
	core._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	core.reduced_motion = true
	core.refresh_motion()
	var frozen: float = game.background.elapsed
	game.background.reduced_motion = true
	game.background._process(1.0)
	expect(game.background.elapsed == frozen,"Reduced motion stops the gradient animation")
	game.state.data.settings.simple_visuals = true
	game.show_home()
	expect(game.body.find_child("MemoryCore",true,false) == null and game.body.find_child("StaticCore",true,false) != null,"Simple visuals replace 3D with an original static SVG")
	expect(game.background.fill.material == null,"Simple visuals disable gradient shaders")
	game.state.data.settings.simple_visuals = false
	game.show_home()
	expect(click_text(game,"PLAY  ›"),"The first-session action is clear and wired")
	expect(game.screen == "intro" and game.daily,"Daily introduction opens")
	expect(word_count(game.body) <= 35,"The visual intro stays within a 35-word budget")
	await process_frame
	expect(not is_instance_valid(core),"Leaving home disposes the 3D scene")
	for intro_mode in ["leitner","blurting"]:
		game.show_intro(intro_mode,true)
		expect(word_count(game.body) <= 35,"The visual intro has at most 35 words: " + intro_mode)
	game.show_home()
	expect(click_text(game,"How to play"),"A hands-on example is discoverable")
	expect(game.screen == "walkthrough_study" and game.remaining < 0,"Example study is untimed")
	click_text(game,"Hide them  ›")
	expect(game.screen == "walkthrough_recall","Example actually hides the objects")
	for object in ["Key","Apple","Book"]:
		game.body.find_child("Pick_" + object,true,false).pressed.emit()
	expect(game.selected.size() == 3,"Example selection buttons work")
	expect(game.body.find_child("Pick_Key",true,false).get_node("SelectedTick").visible,"Selected objects have a visible checkmark")
	game.body.find_child("Pick_Key",true,false).pressed.emit()
	expect(not game.selected.has("Key") and not game.body.find_child("Pick_Key",true,false).get_node("SelectedTick").visible,"Tapping again clears the selection and checkmark")
	game.body.find_child("Pick_Key",true,false).pressed.emit()
	click_text(game,"Check  ›")
	expect(game.screen == "walkthrough_result" and game.state.data.xp == 0 and game.state.data.history.is_empty() and game.state.data.days.is_empty(),"Tutorial leaves real progress untouched")
	click_text(game,"PLAY  ›")
	expect(game.screen == "intro" and game.daily,"Example leads directly into the real daily session")
	expect(click_text(game,game.start_game_label()),"The introduction has a specific start-game action")
	expect(game.screen == "kim_study" and game.targets.size() == 5,"Object study starts with adaptive target count")
	var time_left: float = game.remaining
	game.pause_game()
	game._process(5)
	expect(game.paused and game.remaining == time_left and not game.shell.visible,"Pause stops timer and hides material")
	game.resume_game()
	expect(not game.paused and game.shell.visible,"Pause resumes")
	game._process(40)
	expect(game.screen == "kim_recall","Timer expiry hides objects and opens recall")
	game.selected = game.targets.duplicate()
	expect(click_text(game,"CHECK  ›"),"Object submit button is wired")
	expect(game.screen == "result" and game.result_score == 100 and game.state.day_progress().has("kim"),"Object result records daily progress")
	click_text(game,"NEXT GAME  ›")
	expect(game.mode == "leitner","Daily flow advances to flashcards")
	click_text(game,game.start_game_label())
	expect(game.screen == "card_question","Flashcard question loads")
	for i in range(5):
		game.input.text = game.queue[game.card_index].a
		click_text(game,"REVEAL  ›")
		expect(game.screen == "card_answer","Flashcard reveal works")
		click_text(game,"✓  Got it")
		expect(game.screen == "card_feedback","Flashcard marking shows next due date")
		click_text(game,"NEXT  ›" if i < 4 else "FINISH  ›")
	expect(game.screen == "result" and game.result_score == 100,"Flashcard mission finishes")
	click_text(game,"NEXT GAME  ›")
	click_text(game,game.start_game_label())
	expect(game.screen == "story_study","Daily story loads")
	game._process(100)
	expect(game.screen == "story_recall","Story timer opens hidden recall")
	game.input.text = game.story.body
	click_text(game,"CHECK  ›")
	expect(game.screen == "story_check" and game.idea_checks.size() == 5,"Story supplies transparent review checklist")
	click_text(game,"FINISH  ›")
	expect(game.screen == "result" and game.result_score == 100 and game.state.complete(game.state.today()),"Full daily quest completes")
	var completed_days: Dictionary = game.state.data.days.duplicate(true)
	game.state.data.days[game.state.today()] = {"kim":100}
	game.show_home()
	expect(click_text(game,"CONTINUE  ›"),"Returning players have a clear resume action")
	expect(game.screen == "intro" and game.mode == "leitner","Resume skips the completed object game")
	game.state.data.days = completed_days
	game.show_home()
	expect(click_text(game,"PLAY AGAIN  ›"),"A finished day points to optional practice")
	expect(game.screen == "practice" and click_text(game,"Play objects"),"Practice selection is available outside the guided session")
	expect(game.screen == "intro" and not game.daily,"Practice does not become another daily completion")
	game.show_library()
	expect(game.screen == "library","Card library loads")
	game.show_add_card()
	expect(game.screen == "add_card","Personal card form loads")
	game.show_progress()
	expect(game.screen == "progress","Progress screen loads")
	game.show_settings()
	expect(game.screen == "settings","Settings screen loads")
	game.show_credits()
	expect(game.screen == "credits","In-game third-party credits are accessible")
	# Render every screen at a narrow logical width and check horizontal overflow.
	root.size = Vector2i(360,800)
	for callback in [game.show_home,game.show_library,game.show_progress,game.show_settings]:
		callback.call()
		await process_frame
		await process_frame
		expect(game.body.size.x <= game.scroll.size.x + 1,"No horizontal overflow: " + game.screen)
	game.state.data.days = {}
	game.state.data.history = []
	game.show_home()
	await process_frame
	await process_frame
	var primary = game.body.find_child("DailyStart",true,false)
	expect(primary != null and primary.get_global_rect().end.y <= game.size.y - 12,"The main start button is visible without scrolling on a narrow screen")
	cleanup(s)
	cleanup(adaptive)
	cleanup(no_due)
	cleanup(game.state)
	game.queue_free()
	await process_frame
	print("Recall Quest verification: " + str(checks) + " checks, " + str(failures.size()) + " failures")
	var report := {"checks":checks,"failures":failures,"passed":failures.is_empty(),"engine":Engine.get_version_info().string}
	var report_file := FileAccess.open("res://../builds/test-results.json",FileAccess.WRITE)
	if report_file:
		report_file.store_string(JSON.stringify(report,"\t"))
	quit(0 if failures.is_empty() else 1)
