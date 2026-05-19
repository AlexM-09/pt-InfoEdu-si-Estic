extends CanvasLayer

@onready var minimap_camera = $Control/SubViewportContainer/SubViewport/Camera2D
@onready var control = $Control

var poi_icons = []

func _ready():
	layer = 10
	_setup_position()

func _setup_position():
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	control.position = Vector2(viewport_size.x - 220, 20)
	

func _process(_delta):
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	
	var player = players[0]
	minimap_camera.global_position = player.global_position
	
	if poi_icons.size() == 0:
		_create_poi_icons()
	
	_update_poi_icons()

func _create_poi_icons():
	for icon in poi_icons:
		icon.queue_free()
	poi_icons.clear()
	
	var pois = get_tree().get_nodes_in_group("poi")
	for poi in pois:
		var icon = _make_icon(poi)
		control.add_child(icon)
		poi_icons.append({"node": icon, "world_node": poi})

func _update_poi_icons():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var player = players[0]
	
	for item in poi_icons:
		var icon = item["node"]
		var world_node = item["world_node"]
		
		if not is_instance_valid(world_node):
			continue
		
		var screen_pos = _world_to_minimap(world_node.global_position, player.global_position)
		
		var in_bounds = (screen_pos.x >= 0 and screen_pos.x <= 200 and
						screen_pos.y >= 0 and screen_pos.y <= 150)
		icon.visible = in_bounds
		icon.position = screen_pos - Vector2(8, 8)

func _world_to_minimap(world_pos: Vector2, player_pos: Vector2) -> Vector2:
	var diff = world_pos - player_pos
	var zoom = minimap_camera.zoom.x
	var scale_factor = zoom * (200.0 / 400.0)
	return Vector2(100, 75) + diff * scale_factor

func _make_icon(poi_node) -> Control:
	var container = Control.new()
	container.size = Vector2(16, 16)
	
	var rect = ColorRect.new()
	rect.size = Vector2(16, 16)
	
	match poi_node.poi_type:
		"Temple":
			rect.color = Color(1, 0.84, 0, 1)
		"Training Area":
			rect.color = Color(0.6, 0.6, 0.6, 1)
		"House":
			rect.color = Color(0.85, 0.1, 0.1, 1)
		"Minotaur":
			rect.color = Color(0.4, 0.25, 0.1, 1)
		"Medusa":
			rect.color = Color(0, 0.7, 0.6, 1)
		"Cyclop":
			rect.color = Color(0.9, 0.7, 0.5, 1)
		_:
			rect.color = Color(1, 1, 1, 1)
	
	container.add_child(rect)
	return container
