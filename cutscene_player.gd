extends CanvasLayer

@export var next_scene: String = ""

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
		get_tree().change_scene_to_file(next_scene)
