extends CharacterBody2D

var speed: float = 65.0
var player: Node2D = null
var player_chase: bool = false
@onready var anim: AnimatedSprite2D = $animation_manager/AnimatedSprite2D
@export var max_health = 150
@export var health = 150
var damage = 0
var player_in_hitbox = false
var player_hurtbox = null
var is_dead = false
var is_attacking = false
@onready var sprite_node = $animation_manager
var is_hurt = false
var attack_cooldown_timer = false
var is_spawning = false
var _pending_spawn_count = 0
var _attack_coroutine_active = false  
var is_invincible = false

var phase = 1
@export var phase1_speed = 40.0
@export var phase1_damage = 10
@export var phase1_spawn_interval = 5.0
@export var phase1_max_snakes = 3
@export var phase2_speed = 80.0
@export var phase2_damage = 20
@export var phase2_spawn_interval = 2.0
@export var phase2_max_snakes = 6
@export var phase1_spawn_count_min = 1
@export var phase1_spawn_count_max = 2
@export var phase2_spawn_count_min = 2
@export var phase2_spawn_count_max = 4



@export var snake_scene: PackedScene
var spawn_timer = 0.0
var active_snakes = []

func _ready():
	print("[MEDUSA] Ready")
	anim.play("idle")
	anim.animation_finished.connect(_on_animation_finished)
	call_deferred("_setup_healthbar")
	speed = phase1_speed
	damage = phase1_damage
	$medusa_healthbar.visible = false
	spawn_timer = phase1_spawn_interval
	print("[MEDUSA] spawn_timer setat la: ", spawn_timer)

func _setup_healthbar():
	if has_node("medusa_healthbar"):
		$medusa_healthbar.max_value = max_health
		$medusa_healthbar.value = max_health
		print("[MEDUSA] Healthbar setat, max=", max_health)
	else:
		print("[MEDUSA] EROARE: medusa_healthbar nu a fost gasit!")

func _physics_process(delta):
	if is_dead or is_hurt:
		return
	if is_attacking or is_spawning:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	check_phase()

	if player_chase and player != null:
		var dist = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()
		if dist > 30:
			velocity = direction * speed
			if anim.animation != "walk":
				print("[MEDUSA] Incepe sa mearga, dist=", dist)
				anim.play("walk")
		else:
			velocity = Vector2.ZERO
			if anim.animation != "walk" and anim.animation != "idle":
				anim.play("walk")
		if direction.x > 0:
			sprite_node.scale.x = 1
		elif direction.x < 0:
			sprite_node.scale.x = -1
	else:
		velocity = Vector2.ZERO
		if anim.animation != "idle":
			anim.play("idle")

	move_and_slide()

	if player != null:
		spawn_timer -= delta
		if spawn_timer <= 0:
			var count = randi_range(phase1_spawn_count_min, phase1_spawn_count_max) if phase == 1 else randi_range(phase2_spawn_count_min, phase2_spawn_count_max)
			print("[MEDUSA] Spawn timer expirat, spawn ", count, " serpi, faza=", phase)
			spawn_snake(count)

func _on_detection_area_body_entered(body):
	if body.name == "player":
		print("[MEDUSA] Player detectat")
		player = body
		player_chase = true

func _on_detection_area_body_exited(body):
	if body.name == "player":
		print("[MEDUSA] Player a iesit din zona")
		player = null
		player_chase = false

func take_damage(attackdamage):
	if is_dead or is_hurt or is_invincible:
		print("[MEDUSA] take_damage ignorat: is_dead=", is_dead, " is_hurt=", is_hurt)
		return
	print("[MEDUSA] Primit damage: ", attackdamage, " health inainte: ", health)
	health -= attackdamage
	update_health()
	is_hurt = true
	is_invincible = true
	is_attacking = false
	is_spawning = false
	_pending_spawn_count = 0
	attack_cooldown_timer = false
	_attack_coroutine_active = false
	player_hurtbox = null
	anim.play("hurt")
	print("[MEDUSA] Animatie hurt pornita")
	await anim.animation_finished
	is_hurt = false
	if anim.animation != "hurt" and anim.animation != "idle" and anim.animation != "walk":
		return
	print("[MEDUSA] Animatie hurt terminata")
	if health <= 0:
		print("[MEDUSA] Health <= 0, moare")
		is_dead = true
		call_deferred("_die")
	else:
		spawn_timer = phase1_spawn_interval if phase == 1 else phase2_spawn_interval
		if player_chase:
			anim.play("walk")
		else:
			anim.play("idle")
	await get_tree().create_timer(3.0).timeout
	is_invincible = false
	
	if player != null and spawn_timer <= 0:
		var count = randi_range(phase1_spawn_count_min, phase1_spawn_count_max) if phase == 1 else randi_range(phase2_spawn_count_min, phase2_spawn_count_max)
		spawn_snake(count)
	
	var overlapping = $AttackHitbox.get_overlapping_areas()
	for area in overlapping:
		if area.name == "Hurtbox":
			player_hurtbox = area
			is_attacking = true
			anim.play("attack")
			return

func _on_animation_finished():
	print("[MEDUSA] Animatie terminata: ", anim.animation, " is_hurt=", is_hurt, " is_dead=", is_dead, " is_spawning=", is_spawning, " is_attacking=", is_attacking)

	if is_dead:
		return

	if anim.animation == "spawn":
		is_spawning = false
		print("[MEDUSA] Spawn animatie terminata, spawnam ", _pending_spawn_count, " serpi")
		if snake_scene != null:
			for i in range(_pending_spawn_count):
				var angle = randf() * TAU
				var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * 100
				var snake = snake_scene.instantiate()
				get_parent().add_child(snake)
				snake.global_position = spawn_pos
				active_snakes.append(snake)
				print("[MEDUSA] Serpe spawnat la pozitia: ", spawn_pos)
		else:
			print("[MEDUSA] EROARE: snake_scene e null!")
		_pending_spawn_count = 0
		if player_chase:
			anim.play("walk")
		else:
			anim.play("idle")
		return

	if is_hurt:
		print("[MEDUSA] Ignorat din cauza is_hurt=", is_hurt)
		return

	if anim.animation == "attack":
		_finish_attack()

func _finish_attack():
	if _attack_coroutine_active:
		is_attacking = false
		print("[MEDUSA] _finish_attack: coroutine deja activa, ignorat")
		return
	_attack_coroutine_active = true

	var saved_hurtbox = player_hurtbox
	is_attacking = false

	
	if saved_hurtbox != null and is_instance_valid(saved_hurtbox):
		var overlapping = $AttackHitbox.get_overlapping_areas()
		if overlapping.has(saved_hurtbox):
			print("[MEDUSA] Player inca in hitbox la final, dau damage")
			saved_hurtbox.get_parent().take_damage(damage)
		else:
			print("[MEDUSA] Player a iesit din hitbox, nu dau damage")
	else:
		print("[MEDUSA] Hurtbox null, nu dau damage")

	attack_cooldown_timer = true
	await get_tree().create_timer(1.5).timeout

	_attack_coroutine_active = false

	
	if is_dead or is_hurt:
		attack_cooldown_timer = false
		return

	attack_cooldown_timer = false

	
	if is_spawning:
		print("[MEDUSA] Post-attack: spawn in curs, las animatia de spawn sa ruleze")
		attack_cooldown_timer = false
		_attack_coroutine_active = false 
		return

	
	if not is_spawning:
		var overlapping = $AttackHitbox.get_overlapping_areas()
		for area in overlapping:
			if area.name == "Hurtbox":
				player_hurtbox = area
				is_attacking = true
				anim.play("attack")
				print("[MEDUSA] Reatac dupa cooldown")
				return

	if player_chase:
		anim.play("walk")
	else:
		anim.play("idle")

func _die():
	print("[MEDUSA] _die apelat")
	is_dead = true
	player_in_hitbox = false
	player_hurtbox = null
	$AttackHitbox/CollisionShape2D.disabled = true
	player_chase = false
	velocity = Vector2.ZERO
	for snake in active_snakes:
		if is_instance_valid(snake):
			print("[MEDUSA] Omor serpe: ", snake)
			snake.is_dead = true
			snake._die()
	active_snakes.clear()
	anim.play("death")
	print("[MEDUSA] Animatie death pornita")
	await anim.animation_finished
	print("[MEDUSA] Animatie death terminata, queue_free")
	queue_free()

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
	print("[MEDUSA] AttackHitbox area_entered: ", area.name, " is_attacking=", is_attacking, " attack_cooldown_timer=", attack_cooldown_timer)
	if is_attacking or attack_cooldown_timer or is_spawning or is_hurt or is_dead:
		print("[MEDUSA] Atac ignorat: is_attacking=", is_attacking, " cooldown=", attack_cooldown_timer, " is_spawning=", is_spawning)
		return
	if player == null:
		print("[MEDUSA] Atac ignorat: player null")
		return
	if area.name == "Hurtbox":
		var direction = (player.global_position - global_position).normalized()
		print("[MEDUSA] Incepe atac, directie=", direction)
		player_in_hitbox = true
		player_hurtbox = area
		if direction.x > 0:
			sprite_node.scale.x = -1
		else:
			sprite_node.scale.x = 1
		is_attacking = true
		anim.play("attack")
		print("[MEDUSA] Animatie attack pornita")

func _on_attack_hitbox_area_exited(area):
	if area.name == "Hurtbox":
		print("[MEDUSA] Player a iesit din AttackHitbox")
		player_in_hitbox = false
		player_hurtbox = null

func check_phase():
	if phase == 1 and health <= max_health * 0.5:
		phase = 2
		speed = phase2_speed
		damage = phase2_damage
		print("[MEDUSA] Faza 2 activata! speed=", speed, " damage=", damage)

func spawn_snake(count: int = 1):
	if snake_scene == null or player == null:
		print("[MEDUSA] spawn_snake ignorat: snake_scene=", snake_scene, " player=", player)
		return

	if is_attacking or attack_cooldown_timer or _attack_coroutine_active:
		spawn_timer = 2.0
		print("[MEDUSA] Spawn amanat, Medusa ataca, retry in 2s")
		return

	var max_snakes = phase1_max_snakes if phase == 1 else phase2_max_snakes
	active_snakes = active_snakes.filter(func(s): return is_instance_valid(s))
	print("[MEDUSA] spawn_snake: active=", active_snakes.size(), " max=", max_snakes)

	if active_snakes.size() >= max_snakes:
		spawn_timer = phase1_spawn_interval if phase == 1 else phase2_spawn_interval
		print("[MEDUSA] Max serpi atins, reset timer")
		return

	spawn_timer = phase1_spawn_interval if phase == 1 else phase2_spawn_interval
	_pending_spawn_count = min(count, max_snakes - active_snakes.size())
	print("[MEDUSA] Pornesc animatie spawn pentru ", _pending_spawn_count, " serpi")
	is_spawning = true
	anim.play("spawn")
