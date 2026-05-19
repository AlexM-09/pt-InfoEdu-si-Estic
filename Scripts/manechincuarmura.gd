extends CharacterBody2D


func _ready() -> void:
	$AnimatedSprite2D.play("idle")

func _on_area_2d_area_entered(area):
	if area.name == "AttackHitbox":
		$AnimatedSprite2D.play("hurt")
