extends Control

# 属性 Label 引用
@onready var strength_label = $VBoxContainer/StrengthLabel
@onready var dexterity_label = $VBoxContainer/DexterityLabel
@onready var constitution_label = $VBoxContainer/ConstitutionLabel
@onready var intelligence_label = $VBoxContainer/IntelligenceLabel
@onready var wisdom_label = $VBoxContainer/WisdomLabel
@onready var charisma_label = $VBoxContainer/CharismaLabel

# HP 状态条
@onready var hp_bar = $HP/HpBar

func _ready():
	update_stats()
	update_hp(PlayerData.hp, PlayerData.max_hp)

	# 绑定信号，当属性或 HP 变化时实时更新
	PlayerData.stats_changed.connect(update_stats)
	PlayerData.hp_changed.connect(update_hp)

# 更新六大能力值显示
func update_stats():
	strength_label.text = "strength: %d" % PlayerData.get_stat("strength")
	dexterity_label.text = "dexterity: %d" % PlayerData.get_stat("dexterity")
	constitution_label.text = "constitution: %d" % PlayerData.get_stat("constitution")
	intelligence_label.text = "intelligence: %d" % PlayerData.get_stat("intelligence")
	wisdom_label.text = "wisdom: %d" % PlayerData.get_stat("wisdom")
	charisma_label.text = "charisma: %d" % PlayerData.get_stat("charisma")

# 更新 HP 条
func update_hp(new_hp: int, max_hp: int):
	hp_bar.min_value = 0
	hp_bar.max_value = max_hp
	hp_bar.value = new_hp
