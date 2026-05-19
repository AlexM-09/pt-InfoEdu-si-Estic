extends CharacterBody2D

@export var speed: float = 65.0
var player: Node2D = null
var player_chase: bool = false
@onready var anim: AnimatedSprite2D = $animation_manager/AnimatedSprite2D
@export var max_health = 100
@export var health = 100
@export var damage = 25
var is_dead = false
var is_hurt = false
@onready var sprite_node = $animation_manager

# Dash
var is_dashing = false
var is_dash_windup = false
var dash_direction = Vector2.ZERO
var dash_hit_player = false
var dash_cooldown = false
var dash_traveled = 0.0

# Faza
var phase = 1
var phase1_speed = 65.0
var phase1_damage = 25
var phase1_dash_speed = 350.0
var phase1_dash_distance = 300.0
var phase1_dash_trigger = 150.0
var phase1_dash_cooldown = 2.5

var phase2_speed = 100.0
var phase2_damage = 40
var phase2_dash_speed = 550.0
var phase2_dash_distance = 350.0
var phase2_dash_trigger = 200.0
var phase2_dash_cooldown = 1.2

var current_dash_speed = 350.0
var current_dash_distance = 300.0
var current_dash_trigger = 150.0
var current_dash_cooldown = 2.5

func _ready():
	anim.play("idle")
	anim.animation_finished.connect(_on_animation_finished)
	call_deferred("_setup_healthbar")
	speed = phase1_speed
	damage = phase1_damage
	current_dash_speed = phase1_dash_speed
	current_dash_distance = phase1_dash_distance
	current_dash_trigger = phase1_dash_trigger
	current_dash_cooldown = phase1_dash_cooldown

func _setup_healthbar():
	if has_node("minotaur_healthbar"):
		$minotaur_healthbar.max_value = max_health
		$minotaur_healthbar.value = max_health
		$minotaur_healthbar.visible = false
	else:
		print("minotaur_healthbar nu a fost gasit!")

func _physics_process(delta):
	if is_dead or is_hurt:
		return

	if is_dash_windup:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_dashing:
		_process_dash(delta)
		return

	check_phase()

	if player_chase and player != null:
		var dist = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()

		if dist <= current_dash_trigger and not dash_cooldown:
			_start_dash_windup(direction)
			return

		if dist > 40:
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO

		if direction.x > 0:
			sprite_node.scale.x = 1
		elif direction.x < 0:
			sprite_node.scale.x = -1

		if anim.animation != "walk":
			anim.play("walk")
	else:
		velocity = Vector2.ZERO
		if anim.animation != "idle":
			anim.play("idle")

	move_and_slide()

func check_phase():
	if phase == 1 and health <= max_health * 0.5:
		phase = 2
		speed = phase2_speed
		damage = phase2_damage
		current_dash_speed = phase2_dash_speed
		current_dash_distance = phase2_dash_distance
		current_dash_trigger = phase2_dash_trigger
		current_dash_cooldown = phase2_dash_cooldown
		print("Minotaur Faza 2!")

func _start_dash_windup(direction: Vector2):
	is_dash_windup = true
	dash_hit_player = false
	dash_direction = direction
	dash_traveled = 0.0
	dash_cooldown = true

	if direction.x > 0:
		sprite_node.scale.x = 1
	elif direction.x < 0:
		sprite_node.scale.x = -1

	anim.play("dash")

func _start_dash_move():
	is_dash_windup = false
	is_dashing = true

func _process_dash(delta):
	velocity = dash_direction * current_dash_speed
	move_and_slide()
	dash_traveled += current_dash_speed * delta

	if player != null and not dash_hit_player:
		var dist = global_position.distance_to(player.global_position)
		if dist < 40:
			dash_hit_player = true
			if player.has_method("take_damage"):
				player.take_damage(damage)

	if dash_traveled >= current_dash_distance:
		_end_dash()

func _end_dash():
	is_dashing = false
	velocity = Vector2.ZERO
	dash_traveled = 0.0

	if player_chase:
		anim.play("walk")
	else:
		anim.play("idle")

	_start_dash_cooldown()

func _start_dash_cooldown():
	await get_tree().create_timer(current_dash_cooldown).timeout
	dash_cooldown = false

func _on_animation_finished():
	if is_hurt or is_dead:
		return
	if anim.animation == "dash":
		_start_dash_move()
		return

func _on_detection_area_body_entered(body):
	if body.name == "player":
		player = body
		player_chase = true

func _on_detection_area_body_exited(body):
	if body.name == "player":
		player = null
		player_chase = false

func take_damage(attackdamage):
	if is_dead or is_hurt:
		return
	health -= attackdamage
	update_health()
	is_hurt = true
	is_dashing = false
	is_dash_windup = false
	velocity = Vector2.ZERO
	anim.play("hurt")
	await anim.animation_finished
	is_hurt = false
	if health <= 0:
		SaveManager.add_kill()
		is_dead = true
		call_deferred("_die")
	else:
		if player_chase:
			anim.play("walk")
		else:
			anim.play("idle")

func _die():
	is_dead = true
	is_dashing = false
	is_dash_windup = false
	player_chase = false
	velocity = Vector2.ZERO
	anim.play("death")
	await anim.animation_finished
	queue_free()

func update_health():
	if !has_node("minotaur_healthbar"):
		return
	var healthbar = $minotaur_healthbar
	healthbar.value = health
	if health >= max_health:
		healthbar.visible = false
	else:
		healthbar.visible = true
