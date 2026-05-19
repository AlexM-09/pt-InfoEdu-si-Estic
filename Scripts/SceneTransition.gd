extends Node

const TRANSITION_SCENE = preload("res://Scenes/TransitionOverlay.tscn")

var transition_overlay = null
var player_spawn_name = "default"

func _ready():
	transition_overlay = TRANSITION_SCENE.instantiate()
	get_tree().root.call_deferred("add_child", transition_overlay)

func change_scene(target_scene: String, spawn_point: String):
	player_spawn_name = spawn_point
	transition_overlay.fade_out()
	await transition_overlay.animation_finished
	get_tree().change_scene_to_file(target_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	_place_player_at_spawn()
	transition_overlay.fade_in()

func _place_player_at_spawn():
	var spawn_points = get_tree().get_nodes_in_group(player_spawn_name)
	if spawn_points.size() > 0:
		var player = get_tree().get_nodes_in_group("player")[0]
		player.global_position = spawn_points[0].global_position
	else:
		push_warning("Spawn point '" + player_spawn_name + "' nu a fost gasit!")
	
	await get_tree().create_timer(0.5).timeout
	var entrances = get_tree().get_nodes_in_group(player_spawn_name)
	for e in entrances:
		if e.has_method("reset_transition"):
			e.reset_transition()
