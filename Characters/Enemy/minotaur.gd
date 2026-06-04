extends CharacterBody2D

var speed: float = 65.0
var player: Node2D = null
var player_chase: bool = false
@onready var anim: AnimatedSprite2D = $animation_manager/AnimatedSprite2D
@export var max_health = 100
@export var health = 100
var damage = 0
var is_dead = false
var is_hurt = false
var is_attacking = false
@onready var sprite_node = $animation_manager
var damage_cooldown: bool = false

var is_dashing = false
var is_dash_windup = false
var dash_direction = Vector2.ZERO
var dash_hit_player = false
var dash_cooldown = false
var dash_traveled = 0.0

var phase = 1
@export var phase1_speed = 65.0
@export var phase1_damage = 25
@export var phase1_dash_speed = 350.0
@export var phase1_dash_distance = 300.0
@export var phase1_dash_cooldown = 2.5

@export var phase2_speed = 100.0
@export var phase2_damage = 40
@export var phase2_dash_speed = 550.0
@export var phase2_dash_distance = 350.0
@export var phase2_dash_cooldown = 1.2

var current_dash_speed = 350.0
var current_dash_distance = 300.0
var current_dash_cooldown = 2.5

var dash_timer: float = 0.0
var next_dash_time: float = 0.0

var is_invincible = false

# --- DEBUG ---
var _debug_last_anim: String = ""
var _debug_last_state: String = ""
var _debug_tick: float = 0.0
const DEBUG_INTERVAL: float = 0.5

func _get_state_string() -> String:
	if is_dead: return "DEAD"
	if is_hurt: return "HURT"
	if is_dash_windup: return "DASH_WINDUP"
	if is_dashing: return "DASHING"
	if is_attacking: return "ATTACKING"
	if damage_cooldown: return "DAMAGE_COOLDOWN"
	if is_invincible: return "INVINCIBLE"
	if player_chase: return "CHASING"
	return "IDLE"

func _debug_print():
	var dist = -1.0
	if player != null and is_instance_valid(player):
		dist = global_position.distance_to(player.global_position)
	var state = _get_state_string()
	var anim_name = anim.animation if anim else "N/A"
	print("[MINO] HP: %d/%d | Faza: %d | Stare: %s | Animatie: %s | Dist player: %.1f | dash_timer: %.2f | next_dash: %.2f | dash_cooldown: %s" % [
		health, max_health,
		phase,
		state,
		anim_name,
		dist,
		dash_timer,
		next_dash_time,
		str(dash_cooldown)
	])
# --- END DEBUG ---

func _ready():
	anim.play("idle")
	anim.animation_finished.connect(_on_animation_finished)
	call_deferred("_setup_healthbar")
	speed = phase1_speed
	damage = phase1_damage
	current_dash_speed = phase1_dash_speed
	current_dash_distance = phase1_dash_distance
	current_dash_cooldown = phase1_dash_cooldown
	next_dash_time = randf_range(2.5, 5.0)
	print("[MINO] Spawnat. HP: %d | Faza: %d | dash urmator in: %.2f sec" % [health, phase, next_dash_time])

func _setup_healthbar():
	if has_node("minotaur_healthbar"):
		$minotaur_healthbar.max_value = max_health
		$minotaur_healthbar.value = max_health
		$minotaur_healthbar.visible = false
	else:
		print("[MINO][WARN] minotaur_healthbar nu a fost gasit!")

func _physics_process(delta):
	_debug_tick += delta
	if _debug_tick >= DEBUG_INTERVAL:
		_debug_tick = 0.0
		_debug_print()

	if is_dead or is_hurt or is_attacking:
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

		if dist < 35 and not damage_cooldown and not is_attacking and not is_invincible:
			_do_melee_attack()
			return

		if not dash_cooldown:
			dash_timer += delta
			if dash_timer >= next_dash_time:
				print("[MINO] Initiere dash! dash_timer=%.2f | next_dash_time=%.2f | directie=%s" % [dash_timer, next_dash_time, str(direction)])
				dash_timer = 0.0
				next_dash_time = randf_range(1.5, 3.5)
				print("[MINO] Urmatorul dash in: %.2f sec" % next_dash_time)
				_start_dash_windup(direction)
				return

		if dist > 30:
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
		dash_timer = 0.0
		velocity = Vector2.ZERO
		if anim.animation != "idle":
			anim.play("idle")

	move_and_slide()

func _do_melee_attack():
	print("[MINO] Atac melee! dist=%.1f | damage=%d" % [global_position.distance_to(player.global_position), damage])
	is_attacking = true
	damage_cooldown = true
	velocity = Vector2.ZERO
	anim.play("attack")
	await anim.animation_finished
	if player != null and is_instance_valid(player):
		var dist_after = global_position.distance_to(player.global_position)
		print("[MINO] Atac terminat. dist_after=%.1f" % dist_after)
		if dist_after < 45:
			print("[MINO] Hit! Player primeste %d damage." % damage)
			player.take_damage(damage)
		else:
			print("[MINO] Miss! Playerul s-a miscat (dist_after=%.1f)" % dist_after)
	await get_tree().create_timer(0.8).timeout
	damage_cooldown = false
	is_attacking = false

func check_phase():
	if phase == 1 and health <= max_health * 0.5:
		phase = 2
		speed = phase2_speed
		damage = phase2_damage
		current_dash_speed = phase2_dash_speed
		current_dash_distance = phase2_dash_distance
		current_dash_cooldown = phase2_dash_cooldown
		print("[MINO] !! FAZA 2 ACTIVATA !! HP: %d | speed: %.1f | damage: %d | dash_speed: %.1f | dash_cooldown: %.2f" % [
			health, speed, damage, current_dash_speed, current_dash_cooldown
		])

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
	print("[MINO] Dash windup inceput. directie=%s" % str(direction))
	anim.play("dash")

func _start_dash_move():
	is_dash_windup = false
	is_dashing = true
	print("[MINO] Dash PORNIT! speed=%.1f | distanta max=%.1f" % [current_dash_speed, current_dash_distance])

func _process_dash(delta):
	velocity = dash_direction * current_dash_speed
	move_and_slide()
	dash_traveled += current_dash_speed * delta
	if player != null and not dash_hit_player:
		var dist = global_position.distance_to(player.global_position)
		if dist < 40:
			dash_hit_player = true
			print("[MINO] Dash HIT player! dist=%.1f | damage=%d" % [dist, damage])
			if player.has_method("take_damage"):
				player.take_damage(damage)
	if dash_traveled >= current_dash_distance:
		print("[MINO] Dash terminat. dist_parcursa=%.1f" % dash_traveled)
		_end_dash()

func _end_dash():
	is_dashing = false
	is_attacking = false
	damage_cooldown = false
	velocity = Vector2.ZERO
	dash_traveled = 0.0
	dash_cooldown = true
	get_tree().create_timer(current_dash_cooldown).timeout.connect(
		func(): dash_cooldown = false, CONNECT_ONE_SHOT
	)

func _on_animation_finished():
	print("[MINO] Animatie terminata: '%s'" % anim.animation)
	if is_hurt or is_dead:
		return
	if anim.animation == "dash":
		print("[MINO] Animatie dash terminata -> _start_dash_move()")
		_start_dash_move()
		return
	if anim.animation == "attack":
		if player_chase:
			anim.play("walk")
		else:
			anim.play("idle")

func _on_detection_area_body_entered(body):
	if body.name == "player":
		player = body
		player_chase = true
		print("[MINO] Player detectat! Incep chase.")

func _on_detection_area_body_exited(body):
	if body.name == "player":
		player = null
		player_chase = false
		print("[MINO] Player a iesit din detection area. Opresc chase.")

func take_damage(attackdamage):
	if is_dead or is_hurt or is_invincible:
		print("[MINO] take_damage ignorat (is_dead=%s | is_hurt=%s | is_invincible=%s)" % [str(is_dead), str(is_hurt), str(is_invincible)])
		return

	print("[MINO] Primesc %d damage! HP: %d -> %d" % [attackdamage, health, health - attackdamage])
	health -= attackdamage
	update_health()

	is_hurt = true
	is_invincible = true
	is_attacking = false
	is_dashing = false
	is_dash_windup = false
	damage_cooldown = false
	dash_cooldown = false
	velocity = Vector2.ZERO

	anim.play("hurt")
	await anim.animation_finished
	is_hurt = false

	if health <= 0:
		SaveManager.add_kill()
		is_dead = true
		call_deferred("_die")
		return

	await get_tree().create_timer(3.0).timeout
	is_invincible = false
	print("[MINO] Invincibilitate terminata.")

	if player != null and is_instance_valid(player) and player_chase and not damage_cooldown:
		var dist = global_position.distance_to(player.global_position)
		if dist < 35:
			_do_melee_attack()
			return

	if player_chase:
		anim.play("walk")
	else:
		anim.play("idle")

func _die():
	print("[MINO] _die() apelat.")
	is_dead = true
	is_attacking = false
	is_dashing = false
	is_dash_windup = false
	player_chase = false
	velocity = Vector2.ZERO
	anim.play("death")
	await anim.animation_finished
	print("[MINO] Animatie death terminata. queue_free().")
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
