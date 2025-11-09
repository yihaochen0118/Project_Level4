# ItemBase.gd
extends Node
class_name ItemBase

@export var item_name: String
@export var item_type: String = "equipment" # 或 "consumable"
@export var description: String
@export var icon: Texture2D
@export var effect: Dictionary = {}  # 比如 {"hp": +10} 或 {"strength": +2}

func use():
	print("使用物品: ", item_name)
	if effect.has("hp"):
		PlayerData.change_hp(effect["hp"])
	if effect.has("strength"):
		PlayerData.add_stat("strength", effect["strength"])
