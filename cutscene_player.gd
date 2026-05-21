extends CanvasLayer

@export var next_scene: String = ""
@export var spawn_point: String = ""

@onready var video = $VideoStreamPlayer
@onready var skip_button = $SkipButton

func _ready():
	skip_button.pressed.connect(_skip)
	video.finished.connect(_on_video_finished)
	video.play()

func _on_video_finished():
	_go_to_next_scene()

func _skip():
	video.stop()
	_go_to_next_scene()

func _go_to_next_scene():
	if next_scene != "":
		if spawn_point != "":
			SceneTransition.change_scene(next_scene, spawn_point)
		else:
			get_tree().change_scene_to_file(next_scene)
