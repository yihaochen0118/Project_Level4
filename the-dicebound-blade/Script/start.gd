extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var load_button = $VBoxContainer/LoadButton
@onready var setting_button = $VBoxContainer/gamesetting

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	load_button.pressed.connect(_on_load_pressed)
	setting_button.pressed.connect(_on_setting_pressed)  # ✅ 绑定设置按钮

# ===============================
# 🎮 开始游戏
# ===============================
func _on_start_pressed():
	print("🎮 开始游戏！")
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

# ===============================
# ❌ 退出游戏
# ===============================
func _on_quit_pressed():
	get_tree().quit()

# ===============================
# 📂 打开读取存档界面
# ===============================
func _on_load_pressed():
	print("📂 打开读取存档界面")

	var path = ResMgr.get_ui("loadUi")
	if path == "":
		push_error("⚠️ 未在 ResMgr 中登记 load_ui 路径")
		return

	var scene = load(path) as PackedScene
	if scene == null:
		push_error("⚠️ 加载 load_ui.tscn 失败")
		return

	var load_ui = scene.instantiate()
	add_child(load_ui)

# ===============================
# ⚙️ 打开设置界面
# ===============================
func _on_setting_pressed():
	print("⚙️ 打开设置界面")

	# ✅ 直接加载设置界面
	var path = "res://Scenes/ui/SettingMain.tscn"
	var scene = load(path) as PackedScene
	if scene == null:
		push_error("⚠️ 加载 SettingMain.tscn 失败")
		return

	var setting_ui = scene.instantiate()
	add_child(setting_ui)
	setting_ui.set_as_top_level(true)

	print("✅ 设置界面已打开")
