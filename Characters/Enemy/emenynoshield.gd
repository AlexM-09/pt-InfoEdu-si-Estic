extends CharacterBody2D
@export var speed: float = 65.0
var player: Node2D = null
var player_chase: bool = false
@onready var anim: AnimatedSprite2D = $"animation manager/AnimatedSprite2D"
@export var max_health = 50
@export var health = 50
@export var damage = 20
var attack_cooldown = false
var player_in_hitbox = false
var player_hurtbox = null
var is_dead = false
var is_attacking = false
@onready var sprite_node = $"animation manager"

func _ready():
	anim.play("idle")
	%enemy_healthbar.max_value = max_health
	add_to_group("enemy")
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta):
	if is_dead:
		return
	if is_attacking:
		velocity=Vector2.ZERO
		move_and_slide()
		return
	if player_chase and player != null:
		var diff = player.global_position - global_position
		var distance = diff.length()
		var stop_distance = 18.0
		if distance > stop_distance:
			var direction = diff.normalized()
			velocity = direction * speed
			if direction.x > 0:
				sprite_node.scale.x = 1
			elif direction.x < 0:
				sprite_node.scale.x = -1
			if anim.animation != "run":
				anim.play("run")
		else:
			var push_dir = (global_position - player.global_position).normalized()
			velocity = push_dir * speed * 0.5
			if anim.animation != "idle" and anim.animation != "attack":
				anim.play("idle")
	move_and_slide()
	update_health()


func _on_detection_area_body_entered(body):
	if body.name == "player":
		player = body
		player_chase = true
		print("player a intrat in zona de range")

func _on_attack_hitbox_area_entered(area):
	if is_attacking:
		return
	if player == null or not is_instance_valid(player):
		return
	var direction = (player.global_position - global_position).normalized()
	print("SEMNAL PRIMIT: ", area.name)
	if area.name == "Hurtbox":
		player_in_hitbox = true
		player_hurtbox = area
		if direction.x>0:
			sprite_node.scale.x = 1
			is_attacking = true
			anim.play("attack")
			_do_damage.call_deferred()
		elif direction.x<0:
			sprite_node.scale.x = -1
			is_attacking = true
			anim.play("attack")
			_do_damage.call_deferred()
		
func _on_animation_finished():
	if anim.animation == "attack":
		is_attacking = false
		anim.offset.x = 0
		
		if player_chase:
			anim.play("run")
		else:
			anim.play("idle")






func _on_detection_area_body_exited(body):
	if body.name == "player":
		player = null
		player_chase = false
		print("player a iesit din zona de range")


func _on_attack_hitbox_area_exited(area):
	if area.name == "Hurtbox":
		player_in_hitbox = false
		player_hurtbox = null


func _do_damage():
	
	if attack_cooldown or player_hurtbox == null:
		return
	if !is_instance_valid(player_hurtbox):
		return
	# verifica daca hurtbox e inca in attack hitbox
	var overlapping = $AttackHitbox.get_overlapping_areas()
	if not overlapping.has(player_hurtbox):
		player_in_hitbox = false
		player_hurtbox = null
		return
	attack_cooldown = true
	player_hurtbox.get_parent().take_damage(damage)
	await get_tree().create_timer(1.0).timeout
	attack_cooldown = false
	if player_hurtbox != null and is_instance_valid(player_hurtbox):
		_do_damage()
		print("si a luat damage player")

func take_damage(attackdamage):
	if is_dead:
		return
	health -= attackdamage
	print("Enemy health: ", health)
	if health <= 0:
		is_dead = true
		SaveManager.add_kill()
		call_deferred("_die")

func _die():
	is_dead = true
	player_in_hitbox = false
	player_hurtbox = null
	$AttackHitbox/CollisionShape2D.disabled = true
	$CollisionShape2D.disabled = true
	player_chase = false
	velocity = Vector2.ZERO
	anim.play("death")
	await anim.animation_finished
	queue_free()
func update_health():
	var healthbar = $enemy_healthbar
	healthbar.value = health
	if health >= max_health:
		healthbar.visible = false
	else:
		healthbar.visible = true
	
	
