extends Node
const SAVE_PATH = "user://savegame.json"
var data = {
	"character_name": "Pavel Andrei",
	"levels_completed": [false, false, false],
	"hall_of_fame": [],
	"current_run": {
		"enemies_killed": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"max_wave": 0,
	}
}
func _ready():
	load_game()
func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func add_kill():
	data["current_run"]["enemies_killed"] += 1
func add_damage_dealt(amount: float):
	data["current_run"]["damage_dealt"] += int(amount)
func add_damage_taken(amount: float):
	data["current_run"]["damage_taken"] += int(amount)
func update_max_wave(wave: int):
	if wave > data["current_run"]["max_wave"]:
		data["current_run"]["max_wave"] = wave
func submit_to_hall_of_fame():
	var entry = {
		"name": data["character_name"],
		"max_wave": data["current_run"]["max_wave"],
		"enemies_killed": data["current_run"]["enemies_killed"],
		"damage_dealt": data["current_run"]["damage_dealt"],
		"damage_taken": data["current_run"]["damage_taken"],
	}
	data["hall_of_fame"].append(entry)
	data["hall_of_fame"].sort_custom(func(a, b): return a["max_wave"] > b["max_wave"])
	if data["hall_of_fame"].size() > 10:
		data["hall_of_fame"] = data["hall_of_fame"].slice(0, 10)
	reset_current_run()
	save_game()
func reset_current_run():
	data["current_run"] = {
		"enemies_killed": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"max_wave": 0,
	}
func set_character_name(new_name: String):
	data["character_name"] = new_name
	save_game()
func complete_level(index: int):
	data["levels_completed"][index] = true
	save_game()
func is_level_completed(index: int) -> bool:
	if data["levels_completed"].size() > index:
		return data["levels_completed"][index]
	return false

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var result = json.parse(file.get_as_text())
		file.close()
		if result == OK:
			data = json.get_data()
			if not data.has("levels_completed"):
				data["levels_completed"] = [false, false, false]



func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func new_game():
	data["levels_completed"] = [false, false, false]
	data["current_run"] = {
		"enemies_killed": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"max_wave": 0,
	}
	save_game()
