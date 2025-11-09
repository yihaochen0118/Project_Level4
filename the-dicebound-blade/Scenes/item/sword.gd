extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "Sword"
	item_type = "equipment"
	description = "一把锋利的铁剑。使用后永久提升力量。"
	effect = {"strength": 2}
