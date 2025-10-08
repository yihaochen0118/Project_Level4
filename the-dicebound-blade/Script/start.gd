extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var load_button = $VBoxContainer/LoadButton
@onready var setting_button = $VBoxContainer/gamesetting

func _ready():
	# 🚀 启动时自动初始化窗口模式
	_init_window_mode()

	# 按钮信号绑定
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	load_button.pressed.connect(_on_load_pressed)
	setting_button.pressed.connect(_on_setting_pressed)

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
