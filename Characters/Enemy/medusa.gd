extends CharacterBody2D

@export var speed: float = 65.0
var player: Node2D = null
var player_chase: bool = false
@onready var anim: AnimatedSprite2D = $animation_manager/AnimatedSprite2D
@export var max_health = 50
@export var health = 50
@export var damage = 20
var attack_cooldown = false
var player_in_hitbox = false
var player_hurtbox = null
var is_dead = false
var is_attacking = false
@onready var sprite_node = $animation_manager
var is_hurt = false
var attack_cooldown_timer = false
var is_spawning = false
var _pending_spawn_count = 0

var phase = 1
var phase1_speed = 40.0
var phase1_damage = 10
var phase1_spawn_interval = 5.0
var phase1_max_snakes = 3
var phase2_speed = 80.0
var phase2_damage = 20
var phase2_spawn_interval = 2.0
var phase2_max_snakes = 6

@export var snake_scene: PackedScene
var spawn_timer = 0.0
var active_snakes = []

func _ready():
	anim.play("idle")
	anim.animation_finished.connect(_on_animation_finished)
	call_deferred("_setup_healthbar")
	speed = phase1_speed
	damage = phase1_damage
	$medusa_healthbar.visible = false
	spawn_timer = phase1_spawn_interval

func _setup_healthbar():
	if has_node("medusa_healthbar"):
		$medusa_healthbar.max_value = max_health
		$medusa_healthbar.value = max_health
	else:
		print("medusa_healthbar nu a fost gasit!")

func _physics_process(delta):
	if is_dead or is_hurt:
		return
	if is_attacking or is_spawning:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	check_phase()

	# Miscarea si animatia PRIMA
	if player_chase and player != null:
		var dist = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()
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

	# Spawn DUPA move_and_slide
	if player != null:
		spawn_timer -= delta
		if spawn_timer <= 0:
			var count = 2 if phase == 1 else 4
			spawn_snake(count)

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
	is_attacking = false
	is_spawning = false
	anim.play("hurt")
	await anim.animation_finished
	is_hurt = false
	if health <= 0:
		is_dead = true
		call_deferred("_die")
	else:
		if player_chase:
			anim.play("walk")
		else:
			anim.play("idle")

func _on_animation_finished():
	# Spawn se gestioneaza PRIMUL, inaintea oricarui return
	if anim.animation == "spawn":
		is_spawning = false
		if snake_scene != null:
			for i in range(_pending_spawn_count):
				var angle = randf() * TAU
				var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * 100
				var snake = snake_scene.instantiate()
				get_parent().add_child(snake)
				snake.global_position = spawn_pos
				active_snakes.append(snake)
		_pending_spawn_count = 0
		if player_chase:
			anim.play("walk")
		else:
			anim.play("idle")
		return

	# Abia acum verificam is_hurt / is_dead
	if is_hurt or is_dead:
		return

	if anim.animation == "attack":
		is_attacking = false
		_do_damage()
		attack_cooldown_timer = true
		await get_tree().create_timer(1.5).timeout
		attack_cooldown_timer = false
		var overlapping = $AttackHitbox.get_overlapping_areas()
		for area in overlapping:
			if area.name == "Hurtbox":
				player_in_hitbox = true
				player_hurtbox = area
				is_attacking = true
				anim.play("attack")
				return
		if player_chase:
			anim.play("walk")
		else:
			anim.play("idle")

func _die():
	is_dead = true
	player_in_hitbox = false
	player_hurtbox = null
	$AttackHitbox/CollisionShape2D.disabled = true
	player_chase = false
	velocity = Vector2.ZERO
	# Omoara toti serpii activi
	for snake in active_snakes:
		if is_instance_valid(snake):
			snake.is_dead = true
			snake._die()
	active_snakes.clear()
	anim.play("death")
	var timeout = get_tree().create_timer(3.0)
	await anim.animation_finished
	queue_free()

func _do_damage():
	if player_hurtbox == null:
		return
	if !is_instance_valid(player_hurtbox):
		return
	var overlapping = $AttackHitbox.get_overlapping_areas()
	if overlapping.has(player_hurtbox):
		player_hurtbox.get_parent().take_damage(damage)

func update_health():
	if !has_node("medusa_healthbar"):
		return
	var healthbar = $medusa_healthbar
	healthbar.value = health
	if health >= max_health:
		healthbar.visible = false
	else:
		healthbar.visible = true

func _on_attack_hitbox_area_entered(area):
	if is_attacking or attack_cooldown_timer:
		return
	if player == null:
		return
	var direction = (player.global_position - global_position).normalized()
	if area.name == "Hurtbox":
		player_in_hitbox = true
		player_hurtbox = area
		if direction.x > 0:
			sprite_node.scale.x = -1
		else:
			sprite_node.scale.x = 1
		is_attacking = true
		anim.play("attack")

func _on_attack_hitbox_area_exited(area):
	if area.name == "Hurtbox":
		player_in_hitbox = false
		player_hurtbox = null

func check_phase():
	if phase == 1 and health <= max_health * 0.5:
		phase = 2
		speed = phase2_speed
		damage = phase2_damage
		print("Faza 2!")

func spawn_snake(count: int = 1):
	if snake_scene == null or player == null:
		return
	var max_snakes = phase1_max_snakes if phase == 1 else phase2_max_snakes
	active_snakes = active_snakes.filter(func(s): return is_instance_valid(s))
	if active_snakes.size() >= max_snakes:
		spawn_timer = phase1_spawn_interval if phase == 1 else phase2_spawn_interval
		return

	spawn_timer = phase1_spawn_interval if phase == 1 else phase2_spawn_interval
	_pending_spawn_count = min(count, max_snakes - active_snakes.size())
	is_spawning = true
	anim.play("spawn")
