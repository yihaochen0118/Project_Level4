extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "Herbs"
	item_type = "equipment"
	description = "The mysterious herb Lucia gave me looks pretty good; it seems to increase health."
	effect = {"hp": 20}
	icon = preload("res://images/else/Herb.png") 
