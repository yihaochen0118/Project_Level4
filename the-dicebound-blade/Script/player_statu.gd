extends Control

@onready var strength_label = $VBoxContainer/StrengthLabel
@onready var dexterity_label = $VBoxContainer/DexterityLabel
@onready var constitution_label = $VBoxContainer/ConstitutionLabel
@onready var intelligence_label = $VBoxContainer/IntelligenceLabel
@onready var wisdom_label = $VBoxContainer/WisdomLabel
@onready var charisma_label = $VBoxContainer/CharismaLabel
@onready var hp_bar = $HP/HpBar
@onready var show_gear_button = $ShowGearButton

# 记录装备栏实例
var equipment_bar: Control = null

func _ready():
	update_stats()
	update_hp(PlayerData.hp, PlayerData.max_hp)

	PlayerData.stats_changed.connect(update_stats)
	PlayerData.hp_changed.connect(update_hp)

	# ⚙️ 一开始就实例化装备栏
	var bar_scene = preload("res://Scenes/ui/EquipmentBar.tscn")
	equipment_bar = bar_scene.instantiate()
	add_child(equipment_bar)

	# 默认隐藏装备栏（如果你想默认显示可改为 true）
	equipment_bar.visible = false
	print("✅ 装备栏已实例化，但暂未显示。")

	# 🔘 按钮点击时控制显隐
	show_gear_button.pressed.connect(_on_show_gear_button_pressed)


func update_stats():
	strength_label.text = "strength: %d" % PlayerData.get_stat("strength")
	dexterity_label.text = "dexterity: %d" % PlayerData.get_stat("dexterity")
	constitution_label.text = "constitution: %d" % PlayerData.get_stat("constitution")
	intelligence_label.text = "intelligence: %d" % PlayerData.get_stat("intelligence")
	wisdom_label.text = "wisdom: %d" % PlayerData.get_stat("wisdom")
	charisma_label.text = "charisma: %d" % PlayerData.get_stat("charisma")


func update_hp(new_hp: int, max_hp: int):
	hp_bar.min_value = 0
	hp_bar.max_value = max_hp
	hp_bar.value = new_hp


# 🧭 点击按钮：切换装备栏显隐
func _on_show_gear_button_pressed():
	equipment_bar.visible = not equipment_bar.visible
	print("🎯 装备栏可见性: ", equipment_bar.visible)
	show_gear_button.release_focus()
