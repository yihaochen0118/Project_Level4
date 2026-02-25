extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "time_mark_stone"
	item_type = "equipment"
	description = "The gravel is engraved with unusual patterns. Touching it produces a slight temporal resonance.  intelligence+2"
	effect = {"intelligence": 2}
	icon = preload("res://images/else/time_mark_stone.png")
