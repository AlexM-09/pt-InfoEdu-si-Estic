extends Area2D

var player_nearby = false

func _ready() -> void:
	if SaveManager.is_level_completed(0):  
		get_parent().queue_free()
		return
	


func _process(_delta: float) -> void:
	pass
