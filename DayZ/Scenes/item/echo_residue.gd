extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "echo_residue"
	item_type = "equipment"
	description = "The unusual fragments left behind by the echoing array patterns. Occasionally, they emit a faint hum at night.  intelligence+3"
	effect = {"intelligence": 3}
	icon = preload("res://images/else/echo_residue.png")
