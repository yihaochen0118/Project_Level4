extends Control

@onready var strength_label = $VBoxContainer/StrengthLabel
@onready var dexterity_label = $VBoxContainer/DexterityLabel
@onready var constitution_label = $VBoxContainer/ConstitutionLabel
@onready var charisma_label = $VBoxContainer/CharismaLabel

func _ready():
	update_stats()
	# 当 PlayerData 改变属性时，刷新显示
	PlayerData.stats_changed.connect(update_stats)


func update_stats():
	strength_label.text = "力量: %d" % PlayerData.get_stat("strength")
	dexterity_label.text = "敏捷: %d" % PlayerData.get_stat("dexterity")
	constitution_label.text = "体质: %d" % PlayerData.get_stat("constitution")
	charisma_label.text = "魅力: %d" % PlayerData.get_stat("charisma")
