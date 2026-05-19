extends CanvasLayer
@onready var popup = $NamePopup
@onready var name_input = $NamePopup/NameInput
@onready var btn_confirm = $NamePopup/BtnConfirm
@onready var btn_start = get_parent().get_node("VBoxContainer/start")

func _ready():
	popup.visible = false
	btn_confirm.pressed.connect(_on_confirm_pressed)
	# verifica daca nu e deja conectat inainte sa conecteze
	if not get_parent().get_node("VBoxContainer/start").pressed.is_connected(_on_start_pressed):
		get_parent().get_node("VBoxContainer/start").pressed.connect(_on_start_pressed)

func _on_start_pressed():
	popup.visible = true
	name_input.text = SaveManager.data["character_name"]
	
	name_input.grab_focus()

func _on_confirm_pressed():
	var nume = name_input.text.strip_edges()
	if nume == "":
		name_input.placeholder_text = "Scrie un nume!"
		return
	SaveManager.set_character_name(nume)
	print("Nume setat: ", nume)
	get_tree().change_scene_to_file("res://Scenes/CutscenePlayer.tscn")
