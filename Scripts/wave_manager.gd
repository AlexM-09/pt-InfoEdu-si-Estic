extends Node2D

@export var enemy_scenes: Array[PackedScene]
@export var boss_scene: PackedScene
@export var spawn_radius: float = 300.0
@export var spawn_interval: float = 3.0
@export var wave_duration: float = 10
@export var break_duration: float = 10.0
var level_up_pending: bool = false
@export var level_index: int = 0

var current_wave: int = 1
@export var max_waves: int = 5
var wave_timer: float = 0.0
var spawn_timer: float = 0.0
var player: Node2D = null
var is_break: bool = false
var is_boss_break: bool = false
var boss_spawned: bool = false
var boss_defeated: bool = false

@onready var timer_label = $UI/WaveTimer
@onready var level_up_menu = $UI/LevelUpMenu
@onready var btn1 =$UI/LevelUpMenu/HBoxContainer/Btn1
@onready var btn2 = $UI/LevelUpMenu/HBoxContainer/Btn2
@onready var btn3 = $UI/LevelUpMenu/HBoxContainer/Btn3
@export var map_min: Vector2 = Vector2(-360, -120)
@export var map_max: Vector2 = Vector2(360, 120)
@onready var wave_complete_label = $UI/LevelUpMenu/WaveCompleteLabel

@onready var scene_entrance = get_parent().get_node("SceneEntranceDown")
@onready var stats_label = $UI/LevelUpMenu/StatsLabel

var chosen_upgrades = []
var all_upgrades = []
var legendary_chance: float = 1.0
var epic_chance: float = 12.0
const MAX_LEGENDARY_CHANCE: float = 10.0
const MAX_EPIC_CHANCE: float = 25.0

var enemy_health_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0

func _ready():
	wave_complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_complete_label.offset_left -= 100 
	player = get_tree().get_first_node_in_group("player")
	
	if SaveManager.is_level_completed(level_index):
		max_waves = 9999
		print("Level deja completat, max_waves = 9999")
	else:
		print("Level nou, max_waves = ", max_waves)
	
	if scene_entrance:
		scene_entrance.monitoring = false
		scene_entrance.monitorable = false
	else:
		print("[READY] EROARE: SceneEntranceDown nu a fost gasit!")

	all_upgrades = [
		{"name": "Max HP +25", "description": "Creste viata maxima cu 25", "type": "hp"},
		{"name": "Armor +10", "description": "Reduci damage-ul primit", "type": "armor"},
		{"name": "Attack +20%", "description": "Creste damage-ul dat cu 20%", "type": "attack"},
		{"name": "Speed +30", "description": "Te misti mai repede", "type": "speed"},
	]
	level_up_menu.visible = false
	btn1.pressed.connect(_apply_upgrade.bind(0))
	btn2.pressed.connect(_apply_upgrade.bind(1))
	btn3.pressed.connect(_apply_upgrade.bind(2))
	start_wave()

func _process(delta):
	if boss_defeated:
		return

	if boss_spawned:
		var bosses = get_tree().get_nodes_in_group("boss")
		if bosses.is_empty():
			boss_defeated = true
			on_boss_defeated()
		return

	if player == null:
		return
	if level_up_pending:
		return

	wave_timer -= delta
	spawn_timer -= delta

	if is_break:
		var seconds = int(wave_timer) % 60
		if is_boss_break:
			timer_label.text = "Boss in: %02d" % seconds
		else:
			timer_label.text = "Next wave in: %02d" % seconds
		if wave_timer <= 0 and not level_up_pending:
			wave_timer = 999.0
			is_break = false
			if is_boss_break:
				is_boss_break = false
				spawn_boss()
				timer_label.text = "BOSS!"
			else:
				start_wave()
		return

	var seconds = int(wave_timer) % 60
	@warning_ignore("integer_division")
	var minutes = int(wave_timer) / 60
	timer_label.text = "Wave %d | %02d:%02d" % [current_wave, minutes, seconds]

	if spawn_timer <= 0:
		spawn_enemy()
		spawn_timer = spawn_interval

	if wave_timer <= 0:
		wave_timer = 999.0
		current_wave += 1
		SaveManager.update_max_wave(current_wave)
		if current_wave >= max_waves:
			start_boss_break()
		else:
			start_break()

func start_wave():
	wave_timer = wave_duration
	spawn_timer = 0.0
	enemy_health_multiplier = 1.0 + (current_wave - 1) * 0.2
	enemy_damage_multiplier = 1.0 + (current_wave - 1) * 0.15
	print("[WAVE] Start wave: ", current_wave)

func start_break():
	is_break = true
	is_boss_break = false
	wave_timer = break_duration
	kill_all_enemies()
	show_level_up_menu()

func start_boss_break():
	is_break = true
	is_boss_break = true
	wave_timer = break_duration
	kill_all_enemies()
	show_level_up_menu()

func spawn_enemy():
	if enemy_scenes.is_empty() or player == null:
		return
	var spawn_pos = _get_valid_spawn_pos()
	var scene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy = scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_pos
	enemy.add_to_group("enemy")
	if "max_health" in enemy:
		enemy.max_health = int(enemy.max_health * enemy_health_multiplier)
		enemy.health = enemy.max_health
		if enemy.has_node("enemy_healthbar"):
			enemy.get_node("enemy_healthbar").max_value = enemy.max_health
	if "damage" in enemy:
		enemy.damage = int(enemy.damage * enemy_damage_multiplier)

func spawn_boss():
	if boss_scene == null or player == null:
		return
	if boss_spawned:
		return
	kill_all_enemies()
	var spawn_pos = _get_valid_spawn_pos()
	var boss = boss_scene.instantiate()
	get_parent().add_child(boss)
	boss.global_position = spawn_pos
	boss.add_to_group("boss")
	boss_spawned = true
	print("[SPAWN_BOSS] Boss spawnat!")

func kill_all_enemies():
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and enemy.has_method("_die"):
			enemy.is_dead = true
			enemy._die()

func on_boss_defeated():
	print("=== BOSS DEFEATED! ===")
	kill_all_enemies()
	SaveManager.update_max_wave(current_wave)
	SaveManager.submit_to_hall_of_fame()
	SaveManager.complete_level(level_index)
	for b in get_tree().get_nodes_in_group("boss"):
		if is_instance_valid(b):
			b.queue_free()
	if scene_entrance:
		scene_entrance.monitoring = true
		scene_entrance.monitorable = true
	timer_label.text = "BOSS DEFEATED!"
	timer_label.add_theme_color_override("font_color", Color.GOLD)
	level_up_menu.visible = false
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _apply_upgrade(index: int):
	var upgrade = chosen_upgrades[index]
	var value = upgrade["value"]
	match upgrade["type"]:
		"hp":
			player.upgrade_hp(value)
		"armor":
			player.upgrade_armor(value)
		"attack":
			player.upgrade_attack(value)
		"speed":
			player.upgrade_speed(value)

	level_up_menu.visible = false
	level_up_pending = false
	get_tree().paused = false

func show_level_up_menu():
	increase_rarity_chances()
	_update_stats_label()
	chosen_upgrades = []
	var pool = all_upgrades.duplicate()
	pool.shuffle()
	var selected = pool.slice(0, 3)

	for upgrade in selected:
		var rarity = get_rarity()
		var value = 0
		match upgrade["type"]:
			"hp":
				value = get_upgrade_value(10.0, 25.0, rarity["multiplier"])
			"armor":
				value = get_upgrade_value(5.0, 15.0, rarity["multiplier"])
			"attack":
				value = get_upgrade_value(5.0, 20.0, rarity["multiplier"])
			"speed":
				value = get_upgrade_value(10.0, 30.0, rarity["multiplier"])
		chosen_upgrades.append({
			"type": upgrade["type"],
			"rarity": rarity,
			"value": value,
		})

	_setup_button(btn1, chosen_upgrades[0])
	_setup_button(btn2, chosen_upgrades[1])
	_setup_button(btn3, chosen_upgrades[2])

	if is_boss_break:
		wave_complete_label.text = "Boss-ul vine!\nAlege un upgrade:"
	else:
		wave_complete_label.text = "Wave %d completat!\nAlege un upgrade:" % (current_wave-1)

	level_up_menu.visible = true
	level_up_pending = true
	get_tree().paused = true

func get_rarity() -> Dictionary:
	var roll = randf() * 100
	if roll < legendary_chance:
		return {"name": "Legendar", "color": Color.GOLD, "multiplier": 3.0}
	elif roll < legendary_chance + epic_chance:
		return {"name": "Epic", "color": Color.PURPLE, "multiplier": 2.0}
	elif roll < legendary_chance + epic_chance + 25.0:
		return {"name": "Rar", "color": Color.CYAN, "multiplier": 1.5}
	else:
		return {"name": "Normal", "color": Color.WHITE, "multiplier": 1.0}

func increase_rarity_chances():
	if legendary_chance < MAX_LEGENDARY_CHANCE:
		legendary_chance += 1.0
		legendary_chance = min(legendary_chance, MAX_LEGENDARY_CHANCE)
	if epic_chance < MAX_EPIC_CHANCE:
		epic_chance += 1.5
		epic_chance = min(epic_chance, MAX_EPIC_CHANCE)

func get_upgrade_value(base_min: float, base_max: float, multiplier: float) -> int:
	var base = randf_range(base_min, base_max)
	return int(base * multiplier)

func _setup_button(btn: Button, upgrade: Dictionary):
	var rarity = upgrade["rarity"]
	var value = upgrade["value"]
	var descriere = ""
	var icon_path = ""
	match upgrade["type"]:
		"hp":
			descriere = "Max HP +%d" % value
			icon_path = "res://Assets/iconite/heart_16x16.png"
		"armor":
			descriere = "Armor +%d" % value
			icon_path = "res://Assets/iconite/armura.png"
		"attack":
			descriere = "Attack +%d%%" % value
			icon_path = "res://Assets/iconite/atac.png"
		"speed":
			descriere = "Speed +%d" % value
			icon_path = "res://Assets/iconite/skibidiviteza1.png"

	btn.text = "[%s]\n%s" % [rarity["name"], descriere]
	btn.add_theme_color_override("font_color", rarity["color"])
	if icon_path != "":
		var texture = load(icon_path)
		if texture:
			btn.icon = texture
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _update_stats_label():
	stats_label.text = """Stats:
 HP: %d / %d
 Armor: %.0f
 Attack Bonus: %.0f%%
 Speed: %d""" % [
		player.health,
		player.max_health,
		player.armor,
		player.attack_bonus,
		player.SPEED
	]

func _get_valid_spawn_pos() -> Vector2:
	for i in 10:
		var angle = randf() * TAU
		var distance = randf_range(150.0, spawn_radius)
		var pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		pos.x = clamp(pos.x, map_min.x, map_max.x)
		pos.y = clamp(pos.y, map_min.y, map_max.y)
		return pos
	return player.global_position
