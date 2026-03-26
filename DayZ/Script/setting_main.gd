extends Control

@onready var back_button = $Panel/BackButton
@onready var main_sound_slider = $Panel/TabContainer/声音设置/ScrollContainer/Music/GlobalSound/MainSound
@onready var global_label = $Panel/TabContainer/声音设置/ScrollContainer/Music/GlobalSound/GlobalShow

@onready var fullscreen_button = $Panel/TabContainer/界面设置/ScrollContainer/Interface/button/fullScreen
@onready var window_button = $Panel/TabContainer/界面设置/ScrollContainer/Interface/button/windows

@onready var chinese_button = $Panel/TabContainer/文本设置/ScrollContainer/Language/button/Chinese
@onready var english_button = $Panel/TabContainer/文本设置/ScrollContainer/Language/button/English
@onready var bgm_toggle = $Panel/TabContainer/声音设置/ScrollContainer/Music/button/BGM
@onready var bgm_name_label = $Panel/TabContainer/界面设置/ScrollContainer/Interface/button/BGMname
@onready var sfx_toggle = $Panel/TabContainer/声音设置/ScrollContainer/Music/button/SoundEffects
@onready var tab_container = $Panel/TabContainer
var _language_lock = false  # 🔒 防止循环触发
func _ready():
	
	var saved_lang = _load_language()
	TranslationServer.set_locale(saved_lang)
	if saved_lang == "en":
		english_button.button_pressed = true
		chinese_button.button_pressed = false
	else:
		chinese_button.button_pressed = true
		english_button.button_pressed = false

	# ✅ 信号绑定（互斥逻辑）
	chinese_button.toggled.connect(_on_chinese_toggled)
	english_button.toggled.connect(_on_english_toggled)
	
	print("🌐 当前语言:", saved_lang)
	_update_ui_texts(saved_lang)
	
	var saved_volume = _load_master_volume()
	main_sound_slider.min_value = 0
	main_sound_slider.max_value = 100
	main_sound_slider.step = 1
	main_sound_slider.value = saved_volume
	_update_master_volume(saved_volume)
	global_label.text = "%d%%" % saved_volume

	_init_window_mode_buttons()
	back_button.pressed.connect(_on_back_pressed)
	set_process_input(true)
	
	var bgm_enabled = _load_bgm_enabled()
	bgm_toggle.button_pressed = bgm_enabled
	_update_bgm_state(bgm_enabled)
	bgm_toggle.toggled.connect(_on_bgm_toggled)
	
	bgm_name_label.toggled.connect(_on_bgm_name_toggled)
	var bgm_name_visible = _load_bgm_name_visible()
	bgm_name_label.button_pressed = bgm_name_visible
	_update_bgm_name_visible(bgm_name_visible)
	main_sound_slider.value_changed.connect(_on_main_sound_changed)
	var sfx_enabled = _load_sfx_enabled()
	sfx_toggle.button_pressed = sfx_enabled
	SdMgr.set_sfx_enabled(sfx_enabled)
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	tab_container.tab_changed.connect(_on_tab_changed)

func _on_tab_changed(tab_index: int) -> void:
	SdMgr.play_sfx(preload("res://images/Sound/Tab.mp3"))
	print("🔁 切换到 Tab:", tab_index)
func _on_sfx_toggled(pressed: bool) -> void:
	SdMgr.set_sfx_enabled(pressed)
	_save_sfx_enabled(pressed)
	print("🔊 音效开关:", pressed)

func _save_sfx_enabled(enabled: bool) -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://config.cfg") != OK:
		cfg = ConfigFile.new()
	cfg.set_value("settings", "sfx_enabled", enabled)
	cfg.save("user://config.cfg")

func _load_sfx_enabled() -> bool:
	var cfg = ConfigFile.new()
	if cfg.load("user://config.cfg") == OK:
		return bool(cfg.get_value("settings", "sfx_enabled", true))
	return true
	
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back_pressed()

func _on_back_pressed():
	print("⬅️ 返回主菜单（关闭设置界面）")
	SdMgr.play_sfx(preload("res://images/Sound/Back.mp3"))  # ← 加这里
	queue_free()

# ===================================
# 🌏 语言切换
# ===================================

# ===============================
# 中文按钮逻辑
# ===============================
func _on_chinese_toggled(pressed: bool) -> void:
	if _language_lock:
		return

	_language_lock = true

	if pressed:
		# ✅ 选中中文 -> 关闭英文
		english_button.button_pressed = false
		_set_language("zh")
		print("🌏 已切换为中文")
	else:
		# ❌ 取消中文 -> 自动开启英文
		english_button.button_pressed = true
		_set_language("en")
		print("🌎 自动切换为英文（因关闭中文）")

	_language_lock = false


# ===============================
# 英文按钮逻辑
# ===============================
func _on_english_toggled(pressed: bool) -> void:
	if _language_lock:
		return

	_language_lock = true

	if pressed:
		# ✅ 选中英文 -> 关闭中文
		chinese_button.button_pressed = false
		_set_language("en")
		print("🌎 已切换为英文")
	else:
		# ❌ 取消英文 -> 自动开启中文
		chinese_button.button_pressed = true
		_set_language("zh")
		print("🌏 自动切换为中文（因关闭英文）")

	_language_lock = false



# ✅ 设置语言主逻辑
func _set_language(lang_code: String) -> void:
	TranslationServer.set_locale(lang_code)
	print("✅ 当前语言代码:", lang_code)
	print(tr("文本设置"))
	ResMgr.set_language(lang_code)  # ✅ 通知资源管理器更新
	_update_ui_texts(lang_code)
	_save_language(lang_code)
	for node in get_tree().root.get_children():
		if node.has_method("_update_ui_texts"):
			node.call("_update_ui_texts", lang_code)
			print("🔁 主菜单已同步更新语言 →", lang_code)
			break

func _save_language(lang_code: String):
	var cfg = ConfigFile.new()
	cfg.set_value("settings", "language", lang_code)
	cfg.save("user://config.cfg")

func _load_language() -> String:
	var cfg = ConfigFile.new()
	if cfg.load("user://config.cfg") == OK:
		return cfg.get_value("settings", "language", "zh")
	return "zh"
	
# ✅ 手动更新所有界面文字（结构化版本）
func _update_ui_texts(lang_code: String) -> void:
	# 顶部 Tab 名称（按顺序）
	$Panel/TabContainer.set_tab_title(0, tr("文本设置"))
	$Panel/TabContainer.set_tab_title(1, tr("界面设置"))
	$Panel/TabContainer.set_tab_title(2, tr("声音设置"))

	print("🈶 已更新界面文字至语言:", lang_code, " 当前翻译：", TranslationServer.get_locale())

	# ===========================
	# 文本设置部分
	# ===========================
	var text_setting = $Panel/TabContainer/文本设置/ScrollContainer/Language/button
	text_setting.get_node("Chinese").text = tr("中文")
	text_setting.get_node("English").text = tr("English")

	# ===========================
	# 界面设置部分
	# ===========================
	var interface_setting = $Panel/TabContainer/界面设置/ScrollContainer/Interface/button
	interface_setting.get_node("CGShow").text = tr("CG显示")
	interface_setting.get_node("BGMname").text = tr("背景音乐名")
	interface_setting.get_node("fullScreen").text = tr("全屏模式")
	interface_setting.get_node("windows").text = tr("画面窗口化")

	# ===========================
	# 声音设置部分
	# ===========================
	var sound_setting = $Panel/TabContainer/声音设置/ScrollContainer/Music
	# 全局音量部分
	sound_setting.get_node("GlobalSound/Global").text = tr("全局音量")

	# 底部三个按钮
	var sound_buttons = sound_setting.get_node("button")
	sound_buttons.get_node("CharacterVoice").text = tr("人物语音启用")
	sound_buttons.get_node("SoundEffects").text = tr("音效启用")
	sound_buttons.get_node("BGM").text = tr("BGM启用")

	# ===========================
	# 返回按钮
	# ===========================
	$Panel/BackButton.text = tr("返回")



# ===================================
# 🔊 音量控制
# ===================================
func _on_main_sound_changed(value: float) -> void:
	global_label.text = "%d%%" % value
	_update_master_volume(value)
	_save_master_volume(value)  # 保存当前音量

func _update_master_volume(value: float) -> void:
	var db = _value_to_db(value)
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, db)
	AudioServer.set_bus_mute(bus, value <= 0)
	print("🔊 主音量:", value, "% (", db, "dB )")

func _value_to_db(value: float) -> float:
	if value <= 0:
		return -80.0
	return lerp(-30.0, 0.0, value / 100.0)

# ===================================
# 🖥️ 窗口控制
# ===================================
func _init_window_mode_buttons():
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_button.button_pressed = is_fullscreen
	window_button.button_pressed = not is_fullscreen

	fullscreen_button.toggled.connect(_on_fullscreen_toggled)
	window_button.toggled.connect(_on_window_toggled)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		window_button.button_pressed = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		print("✅ 切换到全屏模式")
	else:
		if not window_button.button_pressed:
			window_button.button_pressed = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			print("✅ 切换到窗口模式")

func _on_window_toggled(pressed: bool) -> void:
	if pressed:
		fullscreen_button.button_pressed = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

		var screen_size: Vector2i = DisplayServer.screen_get_size()
		var window_size: Vector2i = (screen_size * 0.765).floor()
		DisplayServer.window_set_size(window_size)
		DisplayServer.window_set_position(screen_size / 2 - window_size / 2)
		print("✅ 切换到窗口模式（80% 屏幕）")
	else:
		if not fullscreen_button.button_pressed:
			fullscreen_button.button_pressed = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			print("✅ 切换到全屏模式")

func _save_master_volume(value: float) -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://config.cfg") != OK:
		cfg = ConfigFile.new()
	cfg.set_value("settings", "master_volume", value)
	cfg.save("user://config.cfg")

func _load_master_volume() -> float:
	var cfg = ConfigFile.new()
	if cfg.load("user://config.cfg") == OK:
		return cfg.get_value("settings", "master_volume", 80.0)
	return 80.0

# 当 BGM 开关被点击
func _on_bgm_toggled(pressed: bool) -> void:
	_update_bgm_state(pressed)
	_save_bgm_enabled(pressed)

# 实际执行播放 / 停止
func _update_bgm_state(enabled: bool) -> void:
	SdMgr.set_bgm_enabled(enabled)
	print("🎵 BGM 状态:", enabled)


func _save_bgm_enabled(enabled: bool) -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://config.cfg") != OK:
		cfg = ConfigFile.new()
	cfg.set_value("settings", "bgm_enabled", enabled)
	cfg.save("user://config.cfg")

func _load_bgm_enabled() -> bool:
	var cfg = ConfigFile.new()
	if cfg.load("user://config.cfg") == OK:
		return cfg.get_value("settings", "bgm_enabled", true)
	return true

func _save_bgm_name_visible(enabled: bool) -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://config.cfg") != OK:
		cfg = ConfigFile.new()
	cfg.set_value("settings", "bgm_name_visible", enabled)
	cfg.save("user://config.cfg")

func _load_bgm_name_visible() -> bool:
	var cfg = ConfigFile.new()
	if cfg.load("user://config.cfg") == OK:
		return cfg.get_value("settings", "bgm_name_visible", true)
	return true

func _on_bgm_name_toggled(pressed: bool) -> void:
	_update_bgm_name_visible(pressed)
	_save_bgm_name_visible(pressed)

func _update_bgm_name_visible(visible: bool) -> void:
	var start_scene = get_tree().root.find_child("Start", true, false)
	if not start_scene:
		print("⚠️ 未找到 Start 场景，无法更新 BGMName 显示")
		return

	if start_scene.has_node("BGMName"):
		var label = start_scene.get_node("BGMName")
		label.visible = visible
		print("🎵 BGM 名称显示已设为:", visible)
