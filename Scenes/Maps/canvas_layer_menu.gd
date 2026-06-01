extends CanvasLayer

@onready var popup = $NamePopup
@onready var name_input = $NamePopup/NameInput
@onready var btn_confirm = $NamePopup/BtnConfirm
@onready var continue_btn = get_parent().get_node("VBoxContainer/continue")
@onready var new_game_btn = get_parent().get_node("VBoxContainer/newgame")

func _ready():
	popup.visible = false
	continue_btn.visible = false
	new_game_btn.visible = false
	
	btn_confirm.pressed.connect(_on_confirm_pressed)
	get_parent().get_node("VBoxContainer/start").pressed.connect(_on_start_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	new_game_btn.pressed.connect(_on_new_game_pressed)
	
	
	if not SaveManager.has_save():
		continue_btn.modulate = Color(0.5, 0.5, 0.5, 1)
		continue_btn.disabled = true

func _on_start_pressed():
	continue_btn.visible = true
	new_game_btn.visible = true

func _on_continue_pressed():
	if SaveManager.has_save():
		AudioManager.stop_music()
		get_tree().change_scene_to_file("res://Scenes/Maps/Arcadia Hub.tscn")

func _on_new_game_pressed():
	popup.visible = true
	name_input.text = ""
	name_input.placeholder_text="PAVEL ANDREI"
	name_input.grab_focus()

func _on_confirm_pressed():
	var nume = name_input.text.strip_edges()
	if nume == "":
		name_input.placeholder_text = "Scrie un nume!"
		return
	SaveManager.new_game()
	SaveManager.set_character_name(nume)
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://Scenes/CutscenePlayer.tscn")
