extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "Talisman"
	item_type = "equipment"
	description = "神秘的护符，似乎可以让骰子的次数增加（dice6 +1）"
	effect = {"dice": {"sides": 8, "amount": 1}}
