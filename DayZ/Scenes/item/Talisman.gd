extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "Mysterious Talisman of Warcraft"
	item_type = "equipment"
	description = "Alicia的贴身护符，可以让骰子的次数增加（dice6 +2）"
	effect = {"dice": {"sides": 10, "amount": 2}}
