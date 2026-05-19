extends Node

@export var music: AudioStream

func _ready():
	AudioManager.play_music(music)
