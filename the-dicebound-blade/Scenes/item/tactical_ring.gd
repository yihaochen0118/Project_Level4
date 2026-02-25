extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "tactical_ring"
	item_type = "equipment"
	description = "A silver ring engraved with tactical circuitry. Permanently increases strength when worn. strength+3"
	effect = {"strength": 3}
	icon = preload("res://images/else/tactical_ring.png")
