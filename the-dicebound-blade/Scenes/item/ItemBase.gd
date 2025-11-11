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

	# 🩸 回复生命
	if effect.has("hp"):
		PlayerData.change_hp(effect["hp"])

	# 💪 增加属性
	if effect.has("strength"):
		PlayerData.add_stat("strength", effect["strength"])
	if effect.has("dexterity"):
		PlayerData.add_stat("dexterity", effect["dexterity"])
	if effect.has("constitution"):
		PlayerData.add_stat("constitution", effect["constitution"])
	if effect.has("intelligence"):
		PlayerData.add_stat("intelligence", effect["intelligence"])
	if effect.has("wisdom"):
		PlayerData.add_stat("wisdom", effect["wisdom"])
	if effect.has("charisma"):
		PlayerData.add_stat("charisma", effect["charisma"])

	# 🎲 增加骰子使用次数（可选效果）
	if effect.has("dice"):
		var dice_data = effect["dice"]
		if typeof(dice_data) == TYPE_DICTIONARY:
			var sides = int(dice_data.get("sides", 6))
			var amount = int(dice_data.get("amount", 1))
			PlayerData.add_dice_uses(sides, amount)
			print("🎲 使用装备增加骰子: D%d +%d 次" % [sides, amount])
