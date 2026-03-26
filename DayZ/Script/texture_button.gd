extends TextureButton

@export var item_name: String = "item_1"
@export var icon_path: String = ""
@export var description: String = ""
@export var stat_bonus: Dictionary = {}  # 例如 {"strength": 1}
@export var consumable: bool = true       # 是否一次性物品

@onready var name_label = $Label

func _ready():
	name_label.text = item_name.capitalize()
	if icon_path != "" and ResourceLoader.exists(icon_path):
		texture_normal = load(icon_path)
	else:
		texture_normal = load("res://icon.svg")

func _pressed():
	print("✅ 使用物品：", item_name)
	PlayerData.apply_item_effect(stat_bonus)
	if consumable:
		queue_free()  # 使用后消失
