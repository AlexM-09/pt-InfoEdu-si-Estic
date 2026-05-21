extends Area2D

@onready var interact_label = $InteractLabel
var player_nearby = false


func _ready():
	interact_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$"../CanvasLayer/Panel".visible = false

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact"):
		var panel = get_node("/root/Arcadia Hub/infomedusa/CanvasLayer/Panel")
		panel.visible = !panel.visible
		

func _on_body_entered(body):
	if body.name == "player":
		player_nearby = true
		interact_label.visible = true

func _on_body_exited(body):
	if body.name == "player":
		player_nearby = false
		interact_label.visible = false
