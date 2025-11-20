extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var load_button = $VBoxContainer/LoadButton
@onready var setting_button = $VBoxContainer/gamesetting
@onready var bgm_name_label = $BGMName
@onready var bgm_player = $AudioStreamPlayer


func _ready():
	# ✅ 启动时先加载语言（非常重要）
	_init_language()
	_apply_saved_master_volume()
	# 🚀 初始化窗口模式
	_init_window_mode()
	$AudioStreamPlayer.play()
	_apply_saved_bgm_state()
	_show_bgm_name()
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
	_show_bgm_name()
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
	PlayerData.reset_all_data()
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

func _apply_saved_master_volume() -> void:
	var cfg = ConfigFile.new()
	var saved_volume: float = 80.0

	if cfg.load("user://config.cfg") == OK:
		saved_volume = cfg.get_value("settings", "master_volume", 80.0)

	var db = lerp(-30.0, 0.0, saved_volume / 100.0)
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, db)
	AudioServer.set_bus_mute(bus, saved_volume <= 0)
	print("🔊 已加载主音量:", saved_volume, "% (", db, "dB )")

func _apply_saved_bgm_state() -> void:
	var cfg = ConfigFile.new()
	var bgm_enabled = true
	if cfg.load("user://config.cfg") == OK:
		bgm_enabled = cfg.get_value("settings", "bgm_enabled", true)

	var bgm_player = $AudioStreamPlayer
	if bgm_player:
		if bgm_enabled:
			if not bgm_player.playing:
				bgm_player.play()
			print("🎵 BGM 已启用并播放")
		else:
			bgm_player.stop()
			print("🔇 BGM 已关闭")
	else:
		print("⚠️ 未找到 AudioStreamPlayer 节点")
	

# ===================================
# 🎵 显示当前BGM名称
# ===================================
func _show_bgm_name():
	# ✅ 从 config.cfg 读取是否显示 BGM 名称
	var cfg = ConfigFile.new()
	var show_bgm_name = true
	if cfg.load("user://config.cfg") == OK:
		show_bgm_name = cfg.get_value("settings", "bgm_name_visible", true)

	# ✅ 若 Label 节点存在则更新可见性
	if bgm_name_label:
		bgm_name_label.visible = show_bgm_name

	# ✅ 更新文字内容
	if not bgm_player or not bgm_player.stream:
		bgm_name_label.text = tr("🎵 当前BGM：无")
	else:
		var name = bgm_player.stream.resource_path.get_file().get_basename()
		bgm_name_label.text = tr("🎵 当前BGM：") +("   ")+name

	print("🎵 BGM 名称显示:", show_bgm_name, " 名称:", bgm_name_label.text)
