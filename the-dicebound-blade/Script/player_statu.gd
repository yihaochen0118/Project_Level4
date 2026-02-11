extends Control

@onready var strength_label = $VBoxContainer/StrengthLabel
@onready var constitution_label = $VBoxContainer/ConstitutionLabel
@onready var intelligence_label = $VBoxContainer/IntelligenceLabel
@onready var charisma_label = $VBoxContainer/CharismaLabel
@onready var hp_bar = $HP/HpBar
@onready var show_gear_button = $ShowGearButton
@onready var chapter_label: Label = $ChapterLabel
var current_chapter: String = "1"
# 记录装备栏实例
var equipment_bar: Control = null

func _ready():
	update_stats()
	update_hp(PlayerData.hp, PlayerData.max_hp)
	update_chapter(PlayerData.chapter)  # ✅ 初始化显示
	
	PlayerData.stats_changed.connect(update_stats)
	PlayerData.hp_changed.connect(update_hp)
	
	if PlayerData.chapter_changed.is_connected(update_chapter) == false:
		PlayerData.chapter_changed.connect(update_chapter)
		
	set_chapter(current_chapter)
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
	constitution_label.text = "constitution: %d" % PlayerData.get_stat("constitution")
	intelligence_label.text = "intelligence: %d" % PlayerData.get_stat("intelligence")
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

func set_chapter(raw: String) -> void:
	var num := _first_number(raw)
	chapter_label.text = "Chapter " + num

func _first_number(s: String) -> String:
	for i in range(s.length()):
		var ch := s[i]
		if ch >= "0" and ch <= "9":
			var j := i
			while j < s.length() and s[j] >= "0" and s[j] <= "9":
				j += 1
			return s.substr(i, j - i) # 返回连续数字，比如 "10"
	return "1"
	
func update_chapter(ch: String) -> void:
	chapter_label.text = "Chapter " + ch
