extends CanvasLayer

@onready var minimap_camera = $Control/SubViewportContainer/SubViewport/Camera2D
@onready var control = $Control

var poi_icons = []

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
	
	var pois = get_tree().get_nodes_in_group("poi")
	print("POI count: ", pois.size())
	for poi in pois:
		print("POI: ", poi.name, " type: ", poi.poi_type)
	
	if pois.size() != poi_icons.size():
		_create_poi_icons()
	
	_update_poi_icons(p)

func _create_poi_icons():
	for icon in poi_icons:
		icon.queue_free()
	poi_icons.clear()
	var pois = get_tree().get_nodes_in_group("poi")
	for poi in pois:
		var icon = _make_icon(poi)
		control.add_child(icon)
		poi_icons.append({"node": icon, "world_node": poi})

func _update_poi_icons(p):
	for item in poi_icons:
		var icon = item["node"]
		var world_node = item["world_node"]
		if not is_instance_valid(world_node):
			continue
		var screen_pos = _world_to_minimap(world_node.global_position, p.global_position)
		var in_bounds = (screen_pos.x >= 0 and screen_pos.x <= 200 and
						screen_pos.y >= 0 and screen_pos.y <= 150)
		icon.visible = in_bounds
		icon.position = screen_pos - Vector2(16, 16)

func _world_to_minimap(world_pos: Vector2, player_pos: Vector2) -> Vector2:
	var diff = world_pos - player_pos
	var zoom = minimap_camera.zoom.x
	var scale_factor = zoom * (200.0 / 400.0)
	return Vector2(100, 75) + diff * scale_factor

func _make_icon(poi_node) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.size = Vector2(32, 32)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_path = ""
	match poi_node.poi_type:
		"Temple":
			icon_path = "res://Assets/MinimapIcons/temple.png"
		"Training Area":
			icon_path = "res://Assets/MinimapIcons/Dummy.png"
		"House":
			icon_path = "res://Assets/MinimapIcons/pat.png"
		"Minotaur":
			icon_path = "res://Assets/MinimapIcons/minotaur.png"
		"Medusa":
			icon_path = "res://Assets/MinimapIcons/medusa.png"
		"Cyclop":
			icon_path = "res://Assets/MinimapIcons/cyclop.png"
	
	if icon_path != "":
		texture_rect.texture = load(icon_path)
	
	return texture_rect
