extends Node
class_name ResourceManager
var dialogues = {}
var current_lang: String  # 当前语言（zh 或 en）
var items = {}

func _ready():
	print("🟢 ResourceManager 初始化中……")

	# 读取保存的语言配置
	current_lang = _load_saved_language()
	print("🌍 当前语言设定:", current_lang)

	# 同步给翻译系统
	TranslationServer.set_locale(current_lang)

	# 加载剧情脚本
	autoLoad_Dialogue("res://ZhScript", "zh")

	if DirAccess.dir_exists_absolute("res://EnScript"):
		autoLoad_Dialogue("res://EnScript", "en")
		print("✅ 英文剧情目录加载完成")
	else:
		print("⚠️ 未找到 EnScript 目录，跳过英文加载")

	print("📚 已加载剧情文件数量:", dialogues.size())
	print("🔎 示例键:", dialogues.keys().slice(0, 6))
	
	if DirAccess.dir_exists_absolute("res://Scenes/item"):
		autoLoad_Items("res://Scenes/item")
	else:
		print("⚠️ 未找到装备目录，跳过装备加载")

# 背景场景路径
var backgrounds = {
	"tavern": "res://Scenes/Background/tavern.tscn",
	"tavern_night": "res://Scenes/Background/tavern_night.tscn",
	"tavern_empty": "res://Scenes/Background/tavern_empty.tscn",
	"Street": "res://Scenes/Background/Street.tscn",
	"forest_path": "res://Scenes/Background/forest_path.tscn",
	"tavern_out": "res://Scenes/Background/tavern_out.tscn",
	"town_gate_day": "res://Scenes/Background/town_gate_day.tscn",
	"town_market_day": "res://Scenes/Background/town_market_day.tscn",
	"town_medical_tent": "res://Scenes/Background/town_medical_tent.tscn",
	"town_snow_street": "res://Scenes/Background/town_snow_street.tscn",
	"Square": "res://Scenes/Background/Square.tscn",
	"Black": "res://Scenes/Background/Black.tscn",
	"underground_entrance": "res://Scenes/Background/underground_entrance.tscn",
	"GameTree": "res://Scenes/ui/Gametree.tscn"
}

# 角色场景路径
var characters = {
	"Alicia": "res://Scenes/Characters/Alicia.tscn",
	"Monster1": "res://Scenes/Characters/Monster1.tscn",
	"Junker": "res://Scenes/Characters/Junker.tscn",
	"Lucia": "res://Scenes/Characters/Lucia.tscn",
	"EnemyLeader": "res://Scenes/Characters/EnemyLeader.tscn",
	"Enemy1": "res://Scenes/Characters/Enemy1.tscn",
}

var ui = {
	"Dice_CardChoose": "res://Scenes/ui/Dice_CardChoose.tscn",
	"talk_ui": "res://Scenes/ui/talk_ui.tscn",
	"Option_ui":"res://Scenes/ui/Option_ui.tscn",
	"PlayerStatu":"res://Scenes/ui/PlayerStatu.tscn",
	"Setting":"res://Scenes/ui/Setting.tscn",
	"EquipmentBar":"res://Scenes/ui/EquipmentBar.tscn",
	"loadUi":"res://Scenes/ui/loadUi.tscn"
}

func autoLoad_Dialogue(base_path: String, lang_code: String):
	var dir = DirAccess.open(base_path)
	if not dir:
		push_error("❌ 无法打开目录: %s" % base_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				autoLoad_Dialogue(base_path + "/" + file_name, lang_code)
		elif file_name.ends_with(".json"):
			var scene_key = file_name.replace(".json", "")
			var full_path = base_path + "/" + file_name

			# ✅ 把不同语言的同名文件归类
			if not dialogues.has(scene_key):
				dialogues[scene_key] = {}
			dialogues[scene_key][lang_code] = full_path

			print("[%s] 加载剧情: %s → %s" % [lang_code.to_upper(), scene_key, full_path])
		file_name = dir.get_next()
	dir.list_dir_end()


# 获取背景
func get_background(name: String) -> String:
	return backgrounds.get(name, "")

# 获取角色
func get_character(name: String) -> String:
	return characters.get(name, "")

func get_ui(name: String) -> String:
	return ui.get(name, "")
	
func get_dialogue(scene_name: String) -> String:
	print("📖 请求剧情文件:", scene_name, "语言:", current_lang)

	if dialogues.has(scene_name):
		var entry = dialogues[scene_name]
		if entry.has(current_lang):
			print("✅ 命中语言文件:", entry[current_lang])
			return entry[current_lang]
		elif entry.has("zh"):
			print("⚙️ 找不到 %s 版，回退到中文: %s" % [current_lang, entry["zh"]])
			return entry["zh"]

	push_warning("⚠️ 未找到剧情文件: %s（语言: %s）" % [scene_name, current_lang])
	return ""
	
	# ==================================================
# 外部调用：切换语言
# ==================================================
func set_language(lang_code: String):
	current_lang = lang_code
	TranslationServer.set_locale(lang_code)
	print("🌐 ResourceManager 语言切换 →", lang_code)

# ==================================================
# 从配置文件读取语言
# ==================================================
func _load_saved_language() -> String:
	var cfg = ConfigFile.new()
	if cfg.load("user://config.cfg") == OK:
		return cfg.get_value("settings", "language", "zh")
	return "zh"

func autoLoad_Items(base_path: String = "res://Scenes/item"):
	if not DirAccess.dir_exists_absolute(base_path):
		push_warning("⚠️ 未找到物品目录: %s" % base_path)
		return

	var dir = DirAccess.open(base_path)
	if not dir:
		push_error("❌ 无法打开物品目录: %s" % base_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				autoLoad_Items(base_path + "/" + file_name)
		elif file_name.ends_with(".tscn"):
			var item_name = file_name.replace(".tscn", "")
			var full_path = base_path + "/" + file_name
			items[item_name] = full_path
			print("💎 加载物品: %s → %s" % [item_name, full_path])
		file_name = dir.get_next()
	dir.list_dir_end()

	print("✅ 装备目录加载完成，总数量: %d" % items.size())
