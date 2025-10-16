extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var load_button = $VBoxContainer/LoadButton
@onready var setting_button = $VBoxContainer/gamesetting

func _ready():
	# ✅ 启动时先加载语言（非常重要）
	_init_language()

	# 🚀 初始化窗口模式
	_init_window_mode()
	
	# 按钮信号绑定
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	load_button.pressed.connect(_on_load_pressed)
	setting_button.pressed.connect(_on_setting_pressed)

	print("🌍 启动完成，当前语言:", TranslationServer.get_locale())


# ===================================
# 🌐 初始化语言设置
# ===================================
func _init_language():
	var cfg = ConfigFile.new()
	var lang = "zh"
	if cfg.load("user://config.cfg") == OK:
		lang = cfg.get_value("settings", "language", "zh")

	TranslationServer.set_locale(lang)
	print("✅ 已加载语言设置:", lang)

	# ✅ 立即更新主菜单文字
	_update_ui_texts(lang)


# ===================================
# 🈶 主菜单文字翻译
# ===================================
func _update_ui_texts(lang_code: String) -> void:
	start_button.text = tr("开始游戏")
	load_button.text = tr("读取存档")
	setting_button.text = tr("游戏设置")
	quit_button.text = tr("退出游戏")
	print("🈶 主菜单界面文字已更新 →", lang_code)


# ===============================
# 🪟 初始化窗口模式
# ===============================
func _init_window_mode():
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	if is_fullscreen:
		print("🖥️ 启动时检测到全屏模式")
	else:
		print("🖥️ 启动时检测到窗口模式")
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		var window_size: Vector2i = (screen_size * 0.765).floor()  # 屏幕 80%
		DisplayServer.window_set_size(window_size)
		DisplayServer.window_set_position(screen_size / 2 - window_size / 2)
		print("📐 已自动将窗口设为屏幕 80%% 并居中显示")

# ===============================
# 🎮 开始游戏
# ===============================
func _on_start_pressed():
	print("🎮 开始游戏！")

	# ✅ 每次开局都重置骰子使用次数
	if PlayerData.has_method("reset_dice_uses"):
		PlayerData.reset_dice_uses()
	else:
		push_warning("⚠️ PlayerData 中未定义 reset_dice_uses()")

	# ✅ （可选）如果你想重置血量、flags 等，也可以这样：
	PlayerData.reset_all()
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

	var path = "res://Scenes/ui/SettingMain.tscn"
	var scene = load(path) as PackedScene
	if scene == null:
		push_error("⚠️ 加载 SettingMain.tscn 失败")
		return

	var setting_ui = scene.instantiate()
	add_child(setting_ui)
	setting_ui.set_as_top_level(true)

	print("✅ 设置界面已打开")
