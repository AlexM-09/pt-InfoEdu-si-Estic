extends CanvasLayer

@onready var minimap_camera = $Control/SubViewportContainer/SubViewport/Camera2D
@onready var control = $Control

func _ready():
	layer = 10
	var subviewport = $Control/SubViewportContainer/SubViewport
	subviewport.world_2d = get_tree().root.get_world_2d()
	_setup_position()

func _setup_position():
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	control.position = Vector2(viewport_size.x - 220, 20)

func _process(_delta):
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	
	var p = players[0]
	minimap_camera.position = p.global_position + Vector2(-50, -30)
