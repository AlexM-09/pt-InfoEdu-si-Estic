extends CanvasLayer

@onready var anim = $AnimationPlayer
@onready var rect = $ColorRect

signal animation_finished

func _ready():
	rect.modulate.a = 0

func fade_out():
	anim.play("fade_out")
	await anim.animation_finished
	emit_signal("animation_finished")

func fade_in():
	anim.play("fade_in")
	await anim.animation_finished
	emit_signal("animation_finished")
