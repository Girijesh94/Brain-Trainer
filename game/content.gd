class_name QuestContent
extends RefCounted

const OBJECTS = ["Key", "Apple", "Candle", "Bicycle", "Book", "Umbrella", "Turtle", "Scissors", "Camera", "Mug", "Leaf", "Rocket", "Clock", "Balloon", "Headphones", "Compass", "Fish", "Diamond", "Flower", "Tent", "Star", "Glasses", "Pencil", "Sailboat"]

# Aliases are explicit and visible in feedback. They are not a semantic AI grader.
const CARDS = [
	{"id":"space", "q":"Which planet is known as the Red Planet?", "a":"Mars", "aliases":["mars"]},
	{"id":"octopus", "q":"How many hearts does an octopus have?", "a":"Three", "aliases":["three", "3"]},
	{"id":"water", "q":"What is the chemical formula for water?", "a":"H2O", "aliases":["h2o", "h₂o"]},
	{"id":"triangle", "q":"How many degrees add up inside a triangle?", "a":"180 degrees", "aliases":["180", "180 degrees", "180°"]},
	{"id":"bee", "q":"What sweet food do bees make?", "a":"Honey", "aliases":["honey"]},
	{"id":"moon", "q":"What is Earth's natural satellite called?", "a":"The Moon", "aliases":["moon", "the moon"]},
	{"id":"hexagon", "q":"How many sides does a hexagon have?", "a":"Six", "aliases":["six", "6"]},
	{"id":"oxygen", "q":"Which gas do humans need from air to breathe?", "a":"Oxygen", "aliases":["oxygen", "o2", "o₂"]},
	{"id":"pacific", "q":"What is the largest ocean on Earth?", "a":"Pacific Ocean", "aliases":["pacific", "pacific ocean", "the pacific ocean"]},
	{"id":"piano", "q":"How many keys are on a standard full-size piano?", "a":"88", "aliases":["88", "eighty eight", "eighty-eight"]},
	{"id":"spider", "q":"How many legs does a spider have?", "a":"Eight", "aliases":["eight", "8"]},
	{"id":"equator", "q":"What imaginary line divides Earth into northern and southern halves?", "a":"The equator", "aliases":["equator", "the equator"]},
	{"id":"freeze", "q":"At what temperature in Celsius does pure water freeze at standard pressure?", "a":"0 degrees Celsius", "aliases":["0", "zero", "0 degrees", "0 degrees celsius", "0°c", "0 c"]},
	{"id":"photosynthesis", "q":"What process lets plants use light to make food?", "a":"Photosynthesis", "aliases":["photosynthesis"]},
	{"id":"leap", "q":"How many days are in a leap year?", "a":"366", "aliases":["366", "366 days"]},
	{"id":"mercury", "q":"Which planet is closest to the Sun?", "a":"Mercury", "aliases":["mercury"]},
	{"id":"chess", "q":"How many squares are on a standard chessboard?", "a":"64", "aliases":["64", "sixty four", "sixty-four"]},
	{"id":"lungs", "q":"Which organs exchange oxygen and carbon dioxide when we breathe?", "a":"Lungs", "aliases":["lungs", "the lungs"]},
	{"id":"minute", "q":"How many seconds are in one minute?", "a":"60", "aliases":["60", "sixty", "60 seconds"]},
	{"id":"sahara", "q":"What is the largest hot desert on Earth?", "a":"Sahara", "aliases":["sahara", "the sahara", "sahara desert"]},
	{"id":"diamond", "q":"Which mineral defines 10 on the Mohs hardness scale?", "a":"Diamond", "aliases":["diamond"]},
	{"id":"kilometre", "q":"How many metres are in a kilometre?", "a":"1000", "aliases":["1000", "1,000", "one thousand", "1000 metres", "1000 meters"]},
	{"id":"japan", "q":"What is the capital of Japan?", "a":"Tokyo", "aliases":["tokyo"]},
	{"id":"rainbow", "q":"How many colours are traditionally named in a rainbow?", "a":"Seven", "aliases":["seven", "7"]}
]

const STORIES = [
	{"title":"The lighthouse delivery", "body":"On Tuesday morning, Mira cycled to the lighthouse. She carried a blue backpack with three oranges inside. Near the gate, she found a silver key. The keeper offered her peppermint tea. Before leaving, Mira promised to return on Friday.", "ideas":[
		{"label":"Mira cycled to the lighthouse on Tuesday morning.", "groups":[["mira"],["cycled","bicycle","bike"],["lighthouse"],["tuesday"]]},
		{"label":"Her blue backpack held three oranges.", "groups":[["blue"],["backpack","bag"],["three","3"],["oranges","orange"]]},
		{"label":"She found a silver key near the gate.", "groups":[["silver"],["key"],["gate"]]},
		{"label":"The keeper offered peppermint tea.", "groups":[["keeper"],["peppermint"],["tea"]]},
		{"label":"She promised to return on Friday.", "groups":[["return","back"],["friday"]]}
	]},
	{"title":"A small garden surprise", "body":"At sunrise, Arun planted six sunflower seeds in a green pot. He placed the pot beside the kitchen window. His sister Leela brought a red watering can. They marked the date on a wooden label. In the afternoon, a robin landed on the fence.", "ideas":[
		{"label":"Arun planted six sunflower seeds at sunrise.", "groups":[["arun"],["six","6"],["sunflower"],["sunrise"]]},
		{"label":"The green pot was beside the kitchen window.", "groups":[["green"],["pot"],["kitchen"],["window"]]},
		{"label":"His sister Leela brought a red watering can.", "groups":[["leela","sister"],["red"],["watering","can"]]},
		{"label":"They wrote the date on a wooden label.", "groups":[["date"],["wooden","wood"],["label"]]},
		{"label":"A robin landed on the fence in the afternoon.", "groups":[["robin"],["fence"],["afternoon"]]}
	]},
	{"title":"The museum's missing map", "body":"On Saturday, Nia visited the railway museum with her grandfather. Their tickets cost twelve coins each. Inside the first room stood a yellow locomotive. Nia left her paper map on a bench. A guard in a brown jacket returned it before lunch.", "ideas":[
		{"label":"Nia visited the railway museum with her grandfather on Saturday.", "groups":[["nia"],["railway","train"],["museum"],["grandfather","grandpa"],["saturday"]]},
		{"label":"Each ticket cost twelve coins.", "groups":[["ticket"],["twelve","12"],["coins","coin"]]},
		{"label":"A yellow locomotive stood in the first room.", "groups":[["yellow"],["locomotive","train"],["first","1st"]]},
		{"label":"Nia left her paper map on a bench.", "groups":[["map"],["bench"]]},
		{"label":"A guard wearing a brown jacket returned it before lunch.", "groups":[["guard"],["brown"],["jacket"],["lunch"]]}
	]},
	{"title":"The mountain picnic", "body":"At nine o'clock, Dev and Sora started walking up Pine Hill. Dev packed two cheese sandwiches in a purple lunchbox. Sora carried a compass borrowed from her aunt. They stopped beside a waterfall for twenty minutes. On the way home, they spotted a white rabbit.", "ideas":[
		{"label":"Dev and Sora started up Pine Hill at nine.", "groups":[["dev"],["sora"],["pine"],["nine","9"]]},
		{"label":"Dev packed two cheese sandwiches in a purple lunchbox.", "groups":[["two","2"],["cheese"],["sandwich"],["purple"]]},
		{"label":"Sora carried a compass borrowed from her aunt.", "groups":[["compass"],["aunt"]]},
		{"label":"They stopped beside a waterfall for twenty minutes.", "groups":[["waterfall"],["twenty","20"],["minutes","minute"]]},
		{"label":"They saw a white rabbit on the way home.", "groups":[["white"],["rabbit"],["home"]]}
	]},
	{"title":"The night market", "body":"On Thursday evening, Isha took a tram to the night market. She bought a striped scarf for her brother. At a stall with a pink roof, she tried mango juice. A musician played a violin beside the fountain. Isha caught the last tram at ten o'clock.", "ideas":[
		{"label":"Isha took a tram to the night market on Thursday evening.", "groups":[["isha"],["tram"],["market"],["thursday"]]},
		{"label":"She bought a striped scarf for her brother.", "groups":[["striped","stripes"],["scarf"],["brother"]]},
		{"label":"She tried mango juice at a stall with a pink roof.", "groups":[["mango"],["juice"],["pink"],["roof"]]},
		{"label":"A violinist played beside the fountain.", "groups":[["violin","violinist"],["fountain"]]},
		{"label":"She caught the last tram at ten.", "groups":[["last"],["tram"],["ten","10"]]}
	]},
	{"title":"The library parcel", "body":"On Monday afternoon, Ravi delivered a parcel to the library. The parcel contained four books about birds. A librarian called Ada placed them on the top shelf. Ravi borrowed a book with a golden cover. He agreed to bring it back in two weeks.", "ideas":[
		{"label":"Ravi delivered a parcel to the library on Monday afternoon.", "groups":[["ravi"],["parcel","package"],["library"],["monday"]]},
		{"label":"The parcel held four books about birds.", "groups":[["four","4"],["books","book"],["birds","bird"]]},
		{"label":"Ada put the books on the top shelf.", "groups":[["ada"],["top"],["shelf"]]},
		{"label":"Ravi borrowed a book with a golden cover.", "groups":[["book"],["golden","gold"],["cover"]]},
		{"label":"He would return it in two weeks.", "groups":[["return","back"],["two","2"],["weeks","week"]]}
	]},
	{"title":"The beach cleanup", "body":"At eight on Sunday, Zoya met five friends at Coral Beach. Everyone wore orange gloves. They collected litter in three large sacks. Under a rock, Zoya discovered a tiny crab. The group finished with coconut water at a nearby cafe.", "ideas":[
		{"label":"Zoya met five friends at Coral Beach at eight on Sunday.", "groups":[["zoya"],["five","5"],["coral"],["eight","8"],["sunday"]]},
		{"label":"Everyone wore orange gloves.", "groups":[["orange"],["gloves","glove"]]},
		{"label":"They filled three large sacks with litter.", "groups":[["three","3"],["sacks","bags"],["litter","rubbish","trash"]]},
		{"label":"Zoya found a tiny crab under a rock.", "groups":[["crab"],["rock"]]},
		{"label":"They drank coconut water at a nearby cafe.", "groups":[["coconut"],["water"],["cafe","café"]]}
	]},
	{"title":"The observatory visit", "body":"On Wednesday night, Eli visited the hilltop observatory. The guide showed him Saturn through a large telescope. Eli wrote three notes in a yellow notebook. At midnight, clouds covered the sky. He took the red bus home with his cousin.", "ideas":[
		{"label":"Eli visited the hilltop observatory on Wednesday night.", "groups":[["eli"],["observatory"],["wednesday"]]},
		{"label":"The guide showed Saturn through a telescope.", "groups":[["saturn"],["telescope"]]},
		{"label":"Eli wrote three notes in a yellow notebook.", "groups":[["three","3"],["notes","note"],["yellow"],["notebook"]]},
		{"label":"Clouds covered the sky at midnight.", "groups":[["clouds","cloud"],["midnight"]]},
		{"label":"He took a red bus home with his cousin.", "groups":[["red"],["bus"],["cousin"]]}
	]}
]

static func normalize(value: String) -> String:
	var result := value.strip_edges().to_lower()
	for punctuation in [".", ",", "!", "?", ";", ":"]:
		result = result.replace(punctuation, "")
	while result.contains("  "):
		result = result.replace("  ", " ")
	return result

static func correct_answer(card: Dictionary, answer: String) -> bool:
	var clean := normalize(answer)
	if clean.is_empty():
		return false
	for alias in card.get("aliases", [card.a]):
		if normalize(str(alias)) == clean:
			return true
	return false

static func suggested_ideas(story: Dictionary, answer: String) -> Array:
	var clean := normalize(answer)
	var matches: Array = []
	for idea in story.ideas:
		var matched := true
		for group in idea.groups:
			var found := false
			for word in group:
				if clean.contains(str(word)):
					found = true
			matched = matched and found
		matches.append(matched)
	return matches
