extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "keeper_badge"
	item_type = "equipment"
	description = "An old bronze badge. Symbolizing being entrusted with something and being trusted. constitution+2"
	effect = {"constitution": 2}
	icon = preload("res://images/else/keeper_badge.png")
