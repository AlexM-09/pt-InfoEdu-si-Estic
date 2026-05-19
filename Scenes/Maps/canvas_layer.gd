extends CanvasLayer

@onready var vbox = $HallOfFamePanel/ScrollContainer/VBoxContainer
@onready var panel = $HallOfFamePanel
@onready var btn_back = $HallOfFamePanel/BtnBack

func _ready():
	panel.visible = false
	btn_back.pressed.connect(_on_back_pressed)

func show_hall_of_fame():
	panel.visible = true
	get_tree().paused = true
	_populate_list()

func _populate_list():
	for child in vbox.get_children():
		child.queue_free()
	var hall = SaveManager.data["hall_of_fame"]
	if hall.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Nu există recorduri încă!\nTermină o bătălie ca să apari aici."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color.GOLD)
		empty_label.add_theme_font_size_override("font_size", 24)
		vbox.add_child(empty_label)
		return
	for i in hall.size():
		var entry = hall[i]
		var label = Label.new()
		label.text = "#%d  %s  |  Wave: %d  |  Kills: %d  |  Damage dat: %d  |  Damage primit: %d" % [
			i + 1,
			entry["name"],
			entry["max_wave"],
			entry["enemies_killed"],
			entry["damage_dealt"],
			entry["damage_taken"],
		]
		if i == 0:
			label.add_theme_color_override("font_color", Color.GOLD)
		elif i == 1:
			label.add_theme_color_override("font_color", Color.SILVER)
		elif i == 2:
			label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
		vbox.add_child(label)

func _on_back_pressed():
	panel.visible = false
	get_tree().paused = false
