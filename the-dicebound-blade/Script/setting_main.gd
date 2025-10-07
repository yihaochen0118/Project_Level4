extends Control

@onready var back_button = $Panel/BackButton
# 🎚️ 主音量滑条与标签
@onready var main_sound_slider = $Panel/TabContainer/声音设置/ScrollContainer/Music/GlobalSound/MainSound
@onready var global_label = $Panel/TabContainer/声音设置/ScrollContainer/Music/GlobalSound/GlobalShow

# 🖥️ 界面设置中的两个按钮
@onready var fullscreen_button = $Panel/TabContainer/界面设置/ScrollContainer/Interface/button/fullScreen
@onready var window_button = $Panel/TabContainer/界面设置/ScrollContainer/Interface/button/windows

@onready var chinese_button = $Panel/TabContainer/文本设置/ScrollContainer/Language/button/Chinese
@onready var english_button = $Panel/TabContainer/文本设置/ScrollContainer/Language/button/English

func _ready():
	chinese_button.button_pressed = true
	english_button.button_pressed = false

	# ✅ 信号绑定（互斥逻辑）
	chinese_button.toggled.connect(_on_chinese_toggled)
	english_button.toggled.connect(_on_english_toggled)

	print("🌐 当前语言: 中文（默认）")
	# ✅ 初始化音量滑条
	main_sound_slider.min_value = 0
	main_sound_slider.max_value = 100
	main_sound_slider.step = 1
	main_sound_slider.value = 80
	main_sound_slider.value_changed.connect(_on_main_sound_changed)
	_update_master_volume(main_sound_slider.value)

	# ✅ 初始化全屏 / 窗口按钮
	_init_window_mode_buttons()
	
	back_button.pressed.connect(_on_back_pressed)
	# ✅ 捕获 ESC 按键
	set_process_input(true)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back_pressed()

func _on_back_pressed():
	print("⬅️ 返回主菜单（关闭设置界面）")
	queue_free()  # ✅ 销毁当前界面节点

func _on_chinese_toggled(pressed: bool) -> void:
	if pressed:
		english_button.button_pressed = false
		_set_language("zh_CN")
		print("🌏 已切换为中文")


func _on_english_toggled(pressed: bool) -> void:
	if pressed:
		chinese_button.button_pressed = false
		_set_language("en_US")
		print("🌎 已切换为英文")


# ✅ 切换语言函数（预留给 TranslationServer 或 UI 更新）
func _set_language(lang_code: String) -> void:
	# 如果你之后添加翻译文件，可以在这里切换：
	# TranslationServer.set_locale(lang_code)
	print("✅ 当前语言代码:", lang_code)

# ===============================
# 🔊 音量控制
# ===============================
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


# ===============================
# 🖥️ 窗口 / 全屏控制
# ===============================
func _init_window_mode_buttons():
	# 获取当前窗口模式
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	fullscreen_button.button_pressed = is_fullscreen
	window_button.button_pressed = not is_fullscreen

	# 绑定信号
	fullscreen_button.toggled.connect(_on_fullscreen_toggled)
	window_button.toggled.connect(_on_window_toggled)

	if is_fullscreen:
		print("🖥️ 当前模式: 全屏")
	else:
		print("🖥️ 当前模式: 窗口")


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		# 设置为全屏并取消窗口按钮
		window_button.button_pressed = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		print("✅ 切换到全屏模式")
	else:
		# 如果用户取消全屏但没按窗口按钮，则保持原状态
		if not window_button.button_pressed:
			window_button.button_pressed = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			print("✅ 切换到窗口模式")


func _on_window_toggled(pressed: bool) -> void:
	if pressed:
		fullscreen_button.button_pressed = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("✅ 切换到窗口模式")
	else:
		if not fullscreen_button.button_pressed:
			fullscreen_button.button_pressed = true
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			print("✅ 切换到全屏模式")
