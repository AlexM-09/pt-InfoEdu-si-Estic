extends CharacterBody2D

@export var speed: float = 50.0
var player: Node2D = null
var player_chase: bool = false
@onready var anim: AnimatedSprite2D = $animation_manager/AnimatedSprite2D
@export var max_health = 200
@export var health = 200
@export var damage = 40
var is_dead = false
var is_hurt = false
var is_attacking = false
var is_tired = false
var attack_cooldown_timer = false
var player_in_hitbox = false
var player_hurtbox = null
@onready var sprite_node = $animation_manager

# Oboseala
var attack_count = 0
var attacks_before_tired = 3  # dupa cate atacuri oboseste
var tired_duration = 4.0      # cat timp sta obosit

func _ready():
	anim.play("idle")
	anim.animation_finished.connect(_on_animation_finished)
	call_deferred("_setup_healthbar")
	$ciclop_healthbar.visible = false

func _setup_healthbar():
	if has_node("ciclop_healthbar"):
		$ciclop_healthbar.max_value = max_health
		$ciclop_healthbar.value = max_health
	else:
		print("ciclop_healthbar nu a fost gasit!")

func _physics_process(_delta):
	if is_dead or is_hurt or is_tired:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if player_chase and player != null:
		var dist = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()
	
	# Atac bazat pe distanta ca la minotaur
		if dist < 55 and not attack_cooldown_timer and not is_attacking and not is_tired:
			is_attacking = true
			attack_cooldown_timer = true
			velocity = Vector2.ZERO
			if direction.x > 0:
				sprite_node.scale.x = 1
			else:
				sprite_node.scale.x = -1
			anim.play("attack")
			return
	
		if dist > 50:
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO
		if direction.x > 0:
			sprite_node.scale.x = 1
		elif direction.x < 0:
			sprite_node.scale.x = -1
		if anim.animation != "walk":
			anim.play("walk")
	move_and_slide()

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
	anim.play("hurt")
	await anim.animation_finished
	is_hurt = false
	if health <= 0:
		SaveManager.add_kill()
		is_dead = true
		call_deferred("_die")
	else:
		if is_tired:
			anim.play("obosit")
		elif player_chase:
			anim.play("walk")
		else:
			anim.play("idle")

func _on_animation_finished():
	if is_hurt or is_dead:
		return
	if anim.animation == "attack":
		is_attacking = false
		if anim.animation == "attack":
			is_attacking = false
		# Damage bazat pe distanta
		if player != null and is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist < 45:
				player.take_damage(damage)
		attack_count += 1
		await get_tree().create_timer(1.5).timeout
		attack_cooldown_timer = false
		if attack_count >= attacks_before_tired:
			_become_tired()
			return
		if player_chase:
			anim.play("walk")
		else:
			anim.play("idle")
			attack_count += 1
			attack_cooldown_timer = true
			await get_tree().create_timer(1.5).timeout
			attack_cooldown_timer = false
			if attack_count >= attacks_before_tired:
				_become_tired()
				return
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

func _become_tired():
	is_tired = true
	attack_count = 0
	anim.speed_scale = 0.5
	anim.play("obosit")
	await get_tree().create_timer(tired_duration).timeout
	is_tired = false
	anim.speed_scale = 1.0
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
	anim.play("death")
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
	if !has_node("ciclop_healthbar"):
		return
	var healthbar = $ciclop_healthbar
	healthbar.value = health
	if health >= max_health:
		healthbar.visible = false
	else:
		healthbar.visible = true

func _on_attack_hitbox_area_entered(area):
	if is_attacking or attack_cooldown_timer or is_tired:
		return
	if player == null:
		return
	var direction = (player.global_position - global_position).normalized()
	if area.name == "Hurtbox":
		player_in_hitbox = true
		player_hurtbox = area
		if direction.x > 0:
			sprite_node.scale.x = 1
		else:
			sprite_node.scale.x = +1
		is_attacking = true
		anim.play("attack")

func _on_attack_hitbox_area_exited(area):
	if area.name == "Hurtbox":
		player_in_hitbox = false
		player_hurtbox = null
