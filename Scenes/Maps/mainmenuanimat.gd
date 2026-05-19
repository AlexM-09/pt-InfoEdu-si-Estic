extends Control

@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var options: Panel = $Options

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	v_box_container.visible=true
	options.visible=false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_start_pressed() -> void:
	pass




func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_pressed() -> void:
	v_box_container.visible=false
	options.visible=true


func _on_back_options_pressed() -> void:
	_ready()
