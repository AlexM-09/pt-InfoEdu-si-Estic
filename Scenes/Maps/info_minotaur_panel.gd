extends CanvasLayer

@onready var panel = $Panel
@onready var btn_back = $Panel/BtnBackm

func _ready():
	panel.visible = false

func show_panel():
	panel.visible = true
	get_tree().paused = true

func _on_btn_backm_pressed() -> void:
	panel.visible = false
	get_tree().paused = false
