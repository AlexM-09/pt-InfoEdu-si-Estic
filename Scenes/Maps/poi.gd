extends Node2D

@export var poi_type: String = "temple"  # "temple", "shop", "training"

func _ready():
	add_to_group("poi")
