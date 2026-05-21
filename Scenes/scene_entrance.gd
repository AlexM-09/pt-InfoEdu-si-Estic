extends Area2D

@export var target_scene: String = ""
@export var target_spawn_point: String = ""
@export var spawn_point_name: String = ""

var can_transition = true

func _ready():
	if spawn_point_name != "":
		$SpawnPoint.add_to_group(spawn_point_name)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and can_transition:
		can_transition = false
		AudioManager.stop_music()
		SceneTransition.change_scene(target_scene, target_spawn_point)

func reset_transition():
	can_transition = true
