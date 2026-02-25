extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "Soul Fragment"
	item_type = "equipment"
	description = "A fragment of a Soul Core. Effect: D20 Dice Uses +1."
	effect = {"dice": {"sides": 20, "amount": 1}}
	icon = preload("res://images/else/soul_fragment.png") 
