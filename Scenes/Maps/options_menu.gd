extends Node2D

@onready var panel = $Panel

func _ready():
	panel.visible = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"): 
		if panel.visible:
			_resume()
		else:
			_pause()

func _pause():
	panel.visible = true
	get_tree().paused = true

func _resume():
	panel.visible = false
	get_tree().paused = false

func _on_back_pressed():
	_resume()

func _on_mainmenu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Maps/mainmenuanimat.tscn")  

func _on_quit_pressed():
	get_tree().quit()
