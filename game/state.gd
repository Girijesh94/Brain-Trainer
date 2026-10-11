class_name QuestState
extends RefCounted

const INTERVALS := [1, 3, 7, 14, 30]
const MODES := ["kim", "leitner", "blurting"]
var save_path := "user://progress.json"
var warning := ""
var data: Dictionary

func _init(custom_path: String = "user://progress.json") -> void:
	save_path = custom_path
	data = fresh()

func fresh() -> Dictionary:
	return {"version":1, "xp":0, "days":{}, "history":[], "cards":{}, "custom_cards":[], "settings":{"sound":true,"reduced_motion":false,"slow_study":false,"simple_visuals":false}, "kim_level":5, "kim_high_run":0, "kim_low_run":0}

func today() -> String:
	return Time.get_date_string_from_system(false)

func day_number(date: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(date + "T00:00:00") / 86400)

func day_string(number: int) -> String:
	return Time.get_datetime_string_from_unix_time(number * 86400).substr(0,10)

func valid_date(date: String) -> bool:
	return date.length() == 10 and date.substr(4,1) == "-" and date.substr(7,1) == "-" and day_string(day_number(date)) == date

func read_save(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return {}
	var parser := JSON.new()
	if parser.parse(f.get_as_text()) != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or parsed.get("version",0) != 1:
		return {}
	return parsed

func load_progress() -> void:
	var loaded := read_save(save_path)
	if loaded.is_empty() and FileAccess.file_exists(save_path):
		loaded = read_save(save_path + ".bak")
		warning = "Recovered a backup of your progress." if not loaded.is_empty() else "Your save could not be read. A fresh journey is ready."
	if loaded.is_empty():
		return
	data.xp = clampi(int(loaded.get("xp",0)) if loaded.get("xp",0) is float or loaded.get("xp",0) is int else 0, 0, 10000000)
	data.kim_level = clampi(int(loaded.get("kim_level",5)) if loaded.get("kim_level",5) is float or loaded.get("kim_level",5) is int else 5,5,10)
	for key in ["kim_high_run","kim_low_run"]:
		if loaded.get(key) is float or loaded.get(key) is int:
			data[key] = clampi(int(loaded[key]),0,2)
	if loaded.get("days") is Dictionary:
		for date in loaded.days:
			if not valid_date(str(date)) or not loaded.days[date] is Dictionary:
				continue
			var entry := {}
			for mode in MODES:
				var value: Variant = loaded.days[date].get(mode)
				if value is float or value is int:
					entry[mode] = clampi(int(value),-1,100)
			data.days[date] = entry
	if loaded.get("cards") is Dictionary:
		for id in loaded.cards:
			var c: Variant = loaded.cards[id]
			if c is Dictionary and (c.get("box") is float or c.get("box") is int) and c.get("due") is String and valid_date(c.due):
				data.cards[str(id)] = {"box":clampi(int(c.box),1,5), "due":c.due}
	if loaded.get("custom_cards") is Array:
		for c in loaded.custom_cards.slice(0,200):
			if c is Dictionary and c.get("id") is String and str(c.id).begins_with("custom_") and c.get("q") is String and c.get("a") is String and not c.q.strip_edges().is_empty() and not c.a.strip_edges().is_empty():
				data.custom_cards.append({"id":c.id,"q":c.q.left(300),"a":c.a.left(300),"aliases":[c.a.left(300)]})
	if loaded.get("history") is Array:
		for h in loaded.history.slice(-120):
			if h is Dictionary and MODES.has(h.get("mode")) and h.get("date") is String and valid_date(h.date) and (h.get("score") is float or h.get("score") is int):
				data.history.append({"date":h.date,"mode":h.mode,"score":clampi(int(h.score),0,100),"daily":bool(h.get("daily",false))})
	if loaded.get("settings") is Dictionary:
		for key in data.settings:
			if loaded.settings.get(key) is bool:
				data.settings[key] = loaded.settings[key]

func save() -> bool:
	var tmp := save_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		warning = "Progress could not be saved. Check device storage."
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.flush()
	f.close()
	# Only back up a readable save; do not replace a good backup with corruption.
	if not read_save(save_path).is_empty():
		DirAccess.copy_absolute(ProjectSettings.globalize_path(save_path),ProjectSettings.globalize_path(save_path + ".bak"))
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp),ProjectSettings.globalize_path(save_path))
	if err != OK:
		warning = "Progress could not be saved. Check device storage."
		return false
	return true

func day_progress(date: String = "") -> Dictionary:
	return data.days.get(today() if date.is_empty() else date,{}).duplicate()

func complete(date: String) -> bool:
	var day := day_progress(date)
	for mode in MODES:
		if not day.has(mode):
			return false
	return true

func streak(date: String = "") -> int:
	var number := day_number(today() if date.is_empty() else date)
	if not complete(day_string(number)):
		number -= 1
	var count := 0
	while complete(day_string(number)):
		count += 1
		number -= 1
	return count

func record(mode: String, score: int, is_daily: bool, date: String = "") -> Dictionary:
	var day := today() if date.is_empty() else date
	score = clampi(score,-1,100)
	var first := is_daily and not day_progress(day).has(mode)
	var earned := 0
	var bonus := false
	if first:
		var entry := day_progress(day)
		entry[mode] = score
		data.days[day] = entry
		earned = 20 + int(round(maxi(0,score) * 0.5))
		if complete(day):
			earned += 50
			bonus = true
		data.xp += earned
	if score >= 0:
		data.history.append({"date":day,"mode":mode,"score":score,"daily":first})
	if data.history.size() > 120:
		data.history.pop_front()
	if mode == "kim":
		data.kim_high_run = int(data.kim_high_run) + 1 if score >= 80 else 0
		data.kim_low_run = int(data.kim_low_run) + 1 if score < 50 else 0
		if data.kim_high_run >= 3:
			data.kim_level = mini(10,int(data.kim_level) + 1)
			data.kim_high_run = 0
		if data.kim_low_run >= 3:
			data.kim_level = maxi(5,int(data.kim_level) - 1)
			data.kim_low_run = 0
	save()
	return {"xp":earned,"daily_bonus":bonus,"first":first}

func cards() -> Array:
	var result: Array = QuestContent.CARDS.duplicate(true)
	result.append_array(data.custom_cards)
	return result

func card_state(id: String) -> Dictionary:
	return data.cards.get(id,{"box":1,"due":today()}).duplicate()

func is_due(id: String, date: String = "") -> bool:
	if not data.cards.has(id):
		return true
	return day_number(card_state(id).due) <= day_number(today() if date.is_empty() else date)

func review_queue(limit: int = 5, allow_early: bool = false, date: String = "") -> Array:
	var day := today() if date.is_empty() else date
	var due: Array = []
	var unseen: Array = []
	var early: Array = []
	for card in cards():
		if not data.cards.has(card.id):
			unseen.append(card)
		elif is_due(card.id,day):
			due.append(card)
		else:
			early.append(card)
	due.sort_custom(func(a,b): return card_state(a.id).due < card_state(b.id).due)
	# Overdue cards come first, then a small number of new cards.
	var result := due.slice(0,limit)
	if result.size() < limit:
		result.append_array(unseen.slice(0,limit - result.size()))
	if allow_early and result.size() < limit:
		early.shuffle()
		result.append_array(early.slice(0,limit - result.size()))
	return result

func review(id: String, correct: bool, date: String = "") -> Dictionary:
	var day := today() if date.is_empty() else date
	var old := card_state(id)
	if not is_due(id,day):
		return {"advanced":false,"box":old.box,"due":old.due}
	var box := mini(5,int(old.box) + 1) if correct else 1
	var next_due := day_string(day_number(day) + INTERVALS[box - 1])
	data.cards[id] = {"box":box,"due":next_due}
	save()
	return {"advanced":true,"box":box,"due":next_due}

func add_card(question: String, answer: String) -> bool:
	if question.strip_edges().is_empty() or answer.strip_edges().is_empty() or data.custom_cards.size() >= 200:
		return false
	var id := "custom_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
	data.custom_cards.append({"id":id,"q":question.strip_edges().left(300),"a":answer.strip_edges().left(300),"aliases":[answer.strip_edges().left(300)]})
	return save()

static func kim_score(targets: Array, selected: Array) -> int:
	if targets.is_empty():
		return 0
	var hits := 0
	var wrong := 0
	var unique: Array = []
	for item in selected:
		if unique.has(item):
			continue
		unique.append(item)
		if targets.has(item):
			hits += 1
		else:
			wrong += 1
	return clampi(int(round(100.0 * (hits - wrong) / targets.size())),0,100)
