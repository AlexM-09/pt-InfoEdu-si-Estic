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

var attack_count = 0
var attacks_before_tired = 3
var tired_duration = 4.0

const ATTACK_RANGE = 25.0


var _last_dist = -1.0
var _last_anim = ""
var _last_state = ""

func _ready():
	anim.play("idle")
	anim.animation_finished.connect(_on_animation_finished)
	call_deferred("_setup_healthbar")
	$ciclop_healthbar.visible = false
	print("[CICLOP] Ready. ATTACK_RANGE=", ATTACK_RANGE)

func _setup_healthbar():
	if has_node("ciclop_healthbar"):
		$ciclop_healthbar.max_value = max_health
		$ciclop_healthbar.value = max_health
	else:
		print("[CICLOP] EROARE: ciclop_healthbar nu a fost gasit!")

func _physics_process(_delta):
	var current_state = "dead=%s hurt=%s tired=%s attacking=%s cooldown=%s" % [is_dead, is_hurt, is_tired, is_attacking, attack_cooldown_timer]
	if current_state != _last_state:
		print("[CICLOP] Stare schimbata: ", current_state)
		_last_state = current_state

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

		
		if abs(dist - _last_dist) > 2.0:
			print("[CICLOP] Distanta fata de player: ", snappedf(dist, 0.1), " | ATTACK_RANGE=", ATTACK_RANGE, " | cooldown=", attack_cooldown_timer)
			_last_dist = dist

		if direction.x > 0:
			sprite_node.scale.x = 1
		elif direction.x < 0:
			sprite_node.scale.x = -1

		if dist < ATTACK_RANGE and not attack_cooldown_timer:
			print("[CICLOP] >>> IN RANGE, INCEP ATAC! dist=", snappedf(dist, 0.1), " cooldown=", attack_cooldown_timer)
			is_attacking = true
			attack_cooldown_timer = true
			velocity = Vector2.ZERO
			anim.play("attack")
			print("[CICLOP] Animatie pornita: attack")
			move_and_slide()
			return

		if dist < ATTACK_RANGE and attack_cooldown_timer:
			print("[CICLOP] In range DAR cooldown activ, nu atac. dist=", snappedf(dist, 0.1))

		if dist > ATTACK_RANGE:
			velocity = direction * speed
			if anim.animation != "walk":
				anim.play("walk")
				print("[CICLOP] Animatie pornita: walk (merg spre player, dist=", snappedf(dist, 0.1), ")")
		else:
			velocity = Vector2.ZERO
			if anim.animation != "walk":
				anim.play("walk")
				print("[CICLOP] Animatie pornita: walk (astept in zona, dist=", snappedf(dist, 0.1), ")")
	else:
		velocity = Vector2.ZERO
		if anim.animation != "idle":
			anim.play("idle")
			print("[CICLOP] Animatie pornita: idle (no player)")

	move_and_slide()

func _on_detection_area_body_entered(body):
	if body.name == "player":
		print("[CICLOP] Player detectat!")
		player = body
		player_chase = true

func _on_detection_area_body_exited(body):
	if body.name == "player":
		print("[CICLOP] Player a iesit din zona de detectie")
		player = null
		player_chase = false

func take_damage(attackdamage):
	if is_dead or is_hurt:
		print("[CICLOP] take_damage ignorat: is_dead=", is_dead, " is_hurt=", is_hurt)
		return
	print("[CICLOP] Primit damage: ", attackdamage, " health inainte: ", health)
	health -= attackdamage
	update_health()
	is_hurt = true
	is_attacking = false
	anim.play("hurt")
	print("[CICLOP] Animatie pornita: hurt")
	await anim.animation_finished
	print("[CICLOP] Animatie terminata: hurt")
	is_hurt = false
	if health <= 0:
		print("[CICLOP] Health <= 0, moare")
		SaveManager.add_kill()
		is_dead = true
		call_deferred("_die")
	else:
		if is_tired:
			anim.play("obosit")
			print("[CICLOP] Animatie pornita: obosit (dupa hurt)")
		elif player_chase:
			anim.play("walk")
			print("[CICLOP] Animatie pornita: walk (dupa hurt)")
		else:
			anim.play("idle")
			print("[CICLOP] Animatie pornita: idle (dupa hurt)")

func _on_animation_finished():
	print("[CICLOP] === Animatie terminata: '", anim.animation, "' | is_hurt=", is_hurt, " is_dead=", is_dead, " is_attacking=", is_attacking, " attack_cooldown_timer=", attack_cooldown_timer, " attack_count=", attack_count)

	if is_hurt or is_dead:
		print("[CICLOP] Ignorat: is_hurt=", is_hurt, " is_dead=", is_dead)
		return

	if anim.animation == "attack":
		is_attacking = false
		print("[CICLOP] is_attacking setat false")

		if player != null and is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			print("[CICLOP] Verificare damage: dist=", snappedf(dist, 0.1), " threshold=", ATTACK_RANGE + 10.0)
			if dist < ATTACK_RANGE + 10.0:
				print("[CICLOP] DAU DAMAGE playerului: ", damage)
				player.take_damage(damage)
			else:
				print("[CICLOP] Player prea departe, nu dau damage")
		else:
			print("[CICLOP] Player null sau invalid, nu dau damage")

		attack_count += 1
		print("[CICLOP] attack_count acum: ", attack_count, " / ", attacks_before_tired)

		print("[CICLOP] Incep cooldown 1.5s...")
		await get_tree().create_timer(1.5).timeout
		print("[CICLOP] Cooldown terminat, attack_cooldown_timer -> false")
		attack_cooldown_timer = false

		if is_dead or is_hurt:
			print("[CICLOP] Dupa cooldown: mort sau hurt, ies")
			return

		if attack_count >= attacks_before_tired:
			print("[CICLOP] Obosit! attack_count=", attack_count)
			_become_tired()
			return

		if player_chase:
			anim.play("walk")
			print("[CICLOP] Animatie pornita: walk (dupa cooldown)")
		else:
			anim.play("idle")
			print("[CICLOP] Animatie pornita: idle (dupa cooldown)")
		return

	if anim.animation == "obosit":
		print("[CICLOP] Animatie obosit terminata (gestionata de _become_tired)")
		return

	print("[CICLOP] Animatie necunoscuta terminata: ", anim.animation)

func _become_tired():
	print("[CICLOP] _become_tired inceput, durata=", tired_duration)
	is_tired = true
	attack_count = 0
	anim.speed_scale = 0.5
	anim.play("obosit")
	print("[CICLOP] Animatie pornita: obosit")
	await get_tree().create_timer(tired_duration).timeout
	print("[CICLOP] Oboseala terminata")
	if is_dead:
		return
	is_tired = false
	anim.speed_scale = 1.0
	attack_cooldown_timer = false
	if player_chase:
		anim.play("walk")
		print("[CICLOP] Animatie pornita: walk (dupa oboseala)")
	else:
		anim.play("idle")
		print("[CICLOP] Animatie pornita: idle (dupa oboseala)")

func _die():
	print("[CICLOP] _die apelat")
	is_dead = true
	player_in_hitbox = false
	player_hurtbox = null
	$AttackHitbox/CollisionShape2D.disabled = true
	player_chase = false
	velocity = Vector2.ZERO
	anim.play("death")
	print("[CICLOP] Animatie pornita: death")
	await anim.animation_finished
	print("[CICLOP] Death terminat, queue_free")
	queue_free()

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
	print("[CICLOP] AttackHitbox area_entered: ", area.name)
	if area.name == "Hurtbox":
		player_in_hitbox = true
		player_hurtbox = area

func _on_attack_hitbox_area_exited(area):
	print("[CICLOP] AttackHitbox area_exited: ", area.name)
	if area.name == "Hurtbox":
		player_in_hitbox = false
		player_hurtbox = null
