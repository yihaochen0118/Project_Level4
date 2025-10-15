extends Control

@onready var back_button = $Panel/BackButton
@onready var main_sound_slider = $Panel/TabContainer/声音设置/ScrollContainer/Music/GlobalSound/MainSound
@onready var global_label = $Panel/TabContainer/声音设置/ScrollContainer/Music/GlobalSound/GlobalShow

@onready var fullscreen_button = $Panel/TabContainer/界面设置/ScrollContainer/Interface/button/fullScreen
@onready var window_button = $Panel/TabContainer/界面设置/ScrollContainer/Interface/button/windows

@onready var chinese_button = $Panel/TabContainer/文本设置/ScrollContainer/Language/button/Chinese
@onready var english_button = $Panel/TabContainer/文本设置/ScrollContainer/Language/button/English

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

	main_sound_slider.min_value = 0
	main_sound_slider.max_value = 100
	main_sound_slider.step = 1
	main_sound_slider.value = 80
	main_sound_slider.value_changed.connect(_on_main_sound_changed)
	_update_master_volume(main_sound_slider.value)

	_init_window_mode_buttons()
	back_button.pressed.connect(_on_back_pressed)
	set_process_input(true)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back_pressed()

func _on_back_pressed():
	print("⬅️ 返回主菜单（关闭设置界面）")
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
	$Panel/TabContainer.set_tab_title(3, tr("快捷键设置"))
	$Panel/TabContainer.set_tab_title(4, tr("其他设置"))

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
