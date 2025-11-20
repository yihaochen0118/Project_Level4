extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "Mysterious Talisman of Warcraft"
	item_type = "equipment"
	description = "神秘的护符，似乎是某位被袭击的旅人所掉。可以让骰子的次数增加（dice6 +1）"
	effect = {"dice": {"sides": 6, "amount": 1}}
