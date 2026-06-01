extends CharacterBody2D
@export var SPEED = 100
var current_direction = "down"
var is_attacking = false
var is_dashing = false
var dash_speed = 250
var dash_duration = 0.3
var dash_direction = Vector2.ZERO
@export var max_health = 100
@export var health = 100
@export var armor: float= 50
var invincible = false
@export var attackdamage = 1
var current_health: float
@export var attack_bonus: float = 0.0
var dash_cooldown: float = 0.0
var is_dead = false


func _ready():
	$AnimatedSprite2D.play("idle")
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	$AttackHitbox/CollisionShape2D.disabled = true
	$healthbar.max_value = max_health
	add_to_group("player")

func _physics_process(delta):
	if is_dead:
		return
	if dash_cooldown > 0:
		dash_cooldown -= delta
	player_attack()
	player_dash()
	player_movement()
	update_healt()
	

func player_movement():
	var direction = Vector2.ZERO
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	if Input.is_action_pressed("up"):
		direction.y -= 1
	if direction.x > 0:
		current_direction = "right"
	elif direction.x < 0:
		current_direction = "left"
	elif direction.y > 0:
		current_direction = "down"
	elif direction.y < 0:
		current_direction = "up"
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		return
	velocity = direction.normalized() * SPEED
	move_and_slide()
	play_anim(direction)

func player_dash():
	if Input.is_action_just_pressed("dash") and !is_dashing and !is_attacking and dash_cooldown <=0 :
		is_dashing = true
		dash_cooldown = 0.4
		$AnimatedSprite2D.stop()
		dash_direction = Vector2.ZERO
		if Input.is_action_pressed("right"):
			dash_direction.x += 1
		if Input.is_action_pressed("left"):
			dash_direction.x -= 1
		if Input.is_action_pressed("down"):
			dash_direction.y += 1
		if Input.is_action_pressed("up"):
			dash_direction.y -= 1
		if dash_direction == Vector2.ZERO:
			dash_direction = Vector2.DOWN
		dash_direction = dash_direction.normalized()
		$AnimatedSprite2D.speed_scale = 5.0
		$AnimatedSprite2D.play("run")
		call_deferred("_enable_hitbox")
		invincible = true
		await get_tree().create_timer(dash_duration).timeout
		is_dashing = false
		
		call_deferred("_disable_hitbox")
		invincible = false

func play_anim(direction):
	var anim = $AnimatedSprite2D
	if current_direction == "right":
		anim.flip_h = false
	if current_direction == "left":
		anim.flip_h = true
	if is_attacking or is_dashing:
		return
	if direction != Vector2.ZERO:
		anim.speed_scale = 2.0
		anim.play("run")
	else:
		anim.speed_scale = 1.0
		anim.play("idle")

func player_attack():
	if Input.is_action_just_pressed("attack") and !is_attacking:
		if get_viewport().gui_is_drag_successful():
			return
		var mouse_pos = get_viewport().get_mouse_position()
		if get_viewport().gui_get_hovered_control() != null:
			return
		is_attacking = true
		$AnimatedSprite2D.speed_scale = 2.0
		$AnimatedSprite2D.play("attack")
		call_deferred("_enable_hitbox")

func _enable_hitbox():
	$AttackHitbox/CollisionShape2D.disabled = false

func _on_animation_finished():
	$AnimatedSprite2D.speed_scale = 1.0
	if $AnimatedSprite2D.animation == "attack":
		is_attacking = false
		call_deferred("_disable_hitbox")

func _disable_hitbox():
	$AttackHitbox/CollisionShape2D.disabled = true

func _on_attack_hitbox_area_entered(area):
	print("Player HIT: ", area.name)
	if area.name == "Hurtbox":
		var dmg = calculate_attack(attackdamage)
		area.get_parent().take_damage(attackdamage)
		call_deferred("_disable_hitbox")



func player():
	pass



func take_damage(raw_dmg: float):
	if invincible or is_dead:
		return
	var dmg= calculate_dmg(raw_dmg)
	health -= dmg
	print("Player health: ", health)
	SaveManager.add_damage_taken(dmg)
	if health <= 0:
		health = 0
		_die()
		return
	invincible = true
	await get_tree().create_timer(0.5).timeout
	invincible = false
	
	
	

func _die():
	is_dead = true
	invincible = true  
	is_dashing = false
	velocity = Vector2.ZERO
	$CollisionShape2D.disabled = true  
	$Hurtbox/CollisionShape2D.disabled = true 
	$AnimatedSprite2D.speed_scale = 1.0
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	$AnimatedSprite2D.visible = false
	SaveManager.submit_to_hall_of_fame()
	SceneTransition.change_scene("res://Scenes/Maps/Arcadia Hub.tscn", "spawn_hub")
	health = max_health
	is_dead = false
	invincible = false
	


func update_healt():
	var healtbar = $healthbar
	healtbar.value = health
	if health >= max_health:
		healtbar.visible = false
	else:
		healtbar.visible = true




func _on_regen_timer_timeout():
	if health < max_health:
		health += 20
	if health > max_health:
		health = max_health
	if health <= 0:
		health = 0

func calculate_dmg(raw_dmg: float ) -> float :
	
	var final_dmg = raw_dmg * 100 / (100+armor)
	return max(final_dmg,1.0)
func calculate_attack(base_dmg: float) -> float:
	var final_dmg = base_dmg * (1.0+attack_bonus / 100)
	SaveManager.add_damage_dealt(final_dmg)
	return max(final_dmg, 1.0)

func upgrade_hp(value: int):
	max_health += value
	health = min(health + value, max_health)
	$healthbar.max_value = max_health

func upgrade_armor(value: int):
	armor += float(value)

func upgrade_attack(value: int):
	attack_bonus += float(value)

func upgrade_speed(value):
	SPEED += value
	dash_speed += value
