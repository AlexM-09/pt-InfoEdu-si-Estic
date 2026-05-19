extends Node

var music_player = AudioStreamPlayer.new()

func _ready():
	add_child(music_player) 
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.finished.connect(_on_music_finished)

func play_music(stream: AudioStream, volume: float = 0.0):
	if music_player.stream == stream and music_player.playing:
		return 
	music_player.stream = stream
	music_player.volume_db = volume
	music_player.play()

func stop_music():
	music_player.stop()

func _on_music_finished():
	music_player.play() # loop
