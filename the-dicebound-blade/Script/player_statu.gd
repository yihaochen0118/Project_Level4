extends Control

@onready var strength_label = $VBoxContainer/StrengthLabel
@onready var dexterity_label = $VBoxContainer/DexterityLabel
@onready var constitution_label = $VBoxContainer/ConstitutionLabel
@onready var charisma_label = $VBoxContainer/CharismaLabel
@onready var hp_bar = $HP/HpBar   # ⚡ 新增一个 Label 显示 HP


func _ready():
	update_stats()
	update_hp(PlayerData.hp, PlayerData.max_hp)

	PlayerData.stats_changed.connect(update_stats)
	PlayerData.hp_changed.connect(update_hp)


func update_stats():
	strength_label.text = "strength: %d" % PlayerData.get_stat("strength")
	dexterity_label.text = "dexterity: %d" % PlayerData.get_stat("dexterity")
	constitution_label.text = "constitution: %d" % PlayerData.get_stat("constitution")
	charisma_label.text = "charisma: %d" % PlayerData.get_stat("charisma")

func update_hp(new_hp: int, max_hp: int):
	hp_bar.min_value = 0
	hp_bar.max_value = max_hp
	hp_bar.value = new_hp
