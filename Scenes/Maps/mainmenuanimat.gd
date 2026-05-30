extends Control

@onready var name_popup = $CanvasLayerMenu/NamePopup
@onready var name_input = $CanvasLayerMenu/NamePopup/NameInput
@onready var confirm_btn = $CanvasLayerMenu/NamePopup/BtnConfirm
@onready var options_panel = $Options

func _ready() -> void:
	name_popup.visible = false
	options_panel.visible = false


func _on_settings_pressed() -> void:
	options_panel.visible = true

func _on_back_options_pressed() -> void:
	options_panel.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
