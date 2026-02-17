extends Control

@onready var save_buttons = $Panel/TabContainer/Save/ScrollContainer/VBoxContainer.get_children()
@onready var load_buttons = $Panel/TabContainer/Load/ScrollContainer/VBoxContainer.get_children()
@onready var quit_button = $Panel/QuitButton
@onready var panel = $Panel
@onready var settingButton = $Setting
@onready var close_button = $Panel/CloseButton
@onready var clear_button = $Panel/ClearButton
@onready var confirm_dialog: ConfirmationDialog = $Panel/ConfirmDialog
# ====== 文本设置 ======
@onready var chinese_button = $Panel/TabContainer/Language/ScrollContainer/Language/button/Chinese
@onready var english_button = $Panel/TabContainer/Language/ScrollContainer/Language/button/English
var _language_lock := false

# ====== 声音设置 ======
@onready var main_sound_slider = $Panel/TabContainer/Music/ScrollContainer/Music/GlobalSound/MainSound
@onready var global_label = $Panel/TabContainer/Music/ScrollContainer/Music/GlobalSound/GlobalShow
@onready var bgm_toggle = $Panel/TabContainer/Music/ScrollContainer/Music/button/BGM
# ====== 音频文字 ======
@onready var global_title = $Panel/TabContainer/Music/ScrollContainer/Music/GlobalSound/Global
@onready var sound_effects_label = $Panel/TabContainer/Music/ScrollContainer/Music/button/SoundEffects
@onready var character_voice_label = $Panel/TabContainer/Music/ScrollContainer/Music/button/CharacterVoice
@onready var bgm_label = $Panel/TabContainer/Music/ScrollContainer/Music/button/BGM



@onready var back_to_menu_button = $Panel/BackToMenuButton  # 新增

var _option_was_visible := false  # 用来记录 OptionUI 打开前的状态
var pending_action: String = ""  # "save" / "load" / "clear"
var pending_slot: int = -1

func _ready():
	_refresh_save_buttons()
	_refresh_load_buttons()
	print("User data path: ", ProjectSettings.globalize_path("user://"))
	panel.hide()
	var ok_btn := confirm_dialog.get_ok_button()
	var cancel_btn := confirm_dialog.get_cancel_button()
	var parent := ok_btn.get_parent()
	if parent:
		parent.move_child(cancel_btn, 1) # Cancel 放到最左
		parent.move_child(ok_btn, 0)     # OK 放到右边（保险起见）
	settingButton.pressed.connect(_on_button_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_button.pressed.connect(_on_close_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)  # ✅ 新增
	confirm_dialog.confirmed.connect(_on_confirmed)

	for i in range(save_buttons.size()):
		var btn = save_buttons[i]
		btn.pressed.connect(func(): _on_save_pressed(i))

	for i in range(load_buttons.size()):
		var btn = load_buttons[i]
		btn.pressed.connect(func(): _on_load_pressed(i))
	_update_ui_texts()
	_load_game_tree()
	_init_language_settings()
	_init_audio_settings()

	
func _load_game_tree():
	var holder = $Panel/TabContainer/GameTree/GameTreeHolder
	var path = ResMgr.get_background("GameTree")  # 这里用 ResourceManager 的路径
	if path == "":
		push_warning("⚠️ GameTree 场景路径为空")
		return
	var scene = load(path) as PackedScene
	if scene == null:
		push_error("❌ 无法加载 GameTree 场景: %s" % path)
		return

	var instance = scene.instantiate()
	holder.add_child(instance)
	print("✅ GameTree 已加载至设置界面")

func _on_button_pressed():
	panel.visible = not panel.visible
	settingButton.visible = not settingButton.visible

	var is_open = panel.visible
	if is_open:
		clear_ui()
		_set_option_active(false)  # 🚫 禁用 OptionUI 输入
	else:
		restore_ui()
		_set_option_active(true)   # ✅ 恢复 OptionUI 输入

func _on_close_pressed():
	panel.hide()
	restore_ui()
	_set_option_active(true)
	settingButton.visible = true

func _on_quit_pressed():
	pending_action = "quit"
	confirm_dialog.dialog_text = tr("确定要退出游戏吗？")
	confirm_dialog.popup_centered()

func _on_clear_pressed():
	pending_action = "clear"
	confirm_dialog.dialog_text = tr("确定要清除所有存档吗？")
	confirm_dialog.popup_centered()

func _on_save_pressed(slot: int):
	pending_action = "save"
	pending_slot = slot
	confirm_dialog.dialog_text = tr("确定要覆盖存档槽 %d 吗？") % slot
	confirm_dialog.popup_centered()

func _on_load_pressed(slot: int):
	pending_action = "load"
	pending_slot = slot
	confirm_dialog.dialog_text = tr("确定要读取存档槽 %d 吗？") % slot
	confirm_dialog.popup_centered()

func _on_back_to_menu_pressed():
	pending_action = "back_to_menu"
	confirm_dialog.dialog_text = tr("确定要返回主菜单吗？\\n当前进度将不会保留")
	confirm_dialog.popup_centered()

func _on_confirmed():
	match pending_action:
		"quit":
			print("👋 确认退出游戏")
			get_tree().quit()
		"save":
			_do_save(pending_slot)
		"load":
			_do_load(pending_slot)
		"clear":
			SaveMgr.clear_all()
			_refresh_save_buttons()
			_refresh_load_buttons()
		"back_to_menu":
			_back_to_menu()  # ✅ 新增
	pending_action = ""
	pending_slot = -1

func _back_to_menu():
	print("🏠 返回主菜单")
	get_tree().change_scene_to_file("res://Scenes/start.tscn")


func _do_save(slot: int):
	var ui_root = get_tree().current_scene.get_node("UI")
	if not ui_root:
		push_warning("⚠️ 无法获取 UI 根节点，存档失败")
		return

	# ✅ 记录 UI 的原始显示状态
	var setting_was_visible := false

	# ✅ 隐藏 Setting
	if ui_root.has_node("Setting"):
		setting_was_visible = ui_root.get_node("Setting").visible
		ui_root.get_node("Setting").hide()

	# ✅ 等待一帧，确保隐藏生效
	await get_tree().process_frame
	await get_tree().process_frame

	# ✅ 截图保存
	var screenshot_path = SaveMgr.capture_screenshot(slot)

	# ✅ 截图完成后恢复 UI
	if ui_root.has_node("Setting") and setting_was_visible:
		ui_root.get_node("Setting").show()

	# ✅ 存档数据
	var data = {
		"chapter": ui_root.current_scene_name,
		"dialogue_index": max(ui_root.dialogue_index - 1, 0),
		"hp": PlayerData.hp,
		"stats": PlayerData.stats,
		"choices": PlayerData.choice_history,
		"screenshot": screenshot_path,
		"time": Time.get_datetime_string_from_system(),
		"flags": PlayerData.flags,

		# 🎲 新增：保存骰子使用次数
		"dice_uses": PlayerData.dice_uses,
		"dice_max_uses": PlayerData.dice_max_uses,
		"inventory": PlayerData.inventory,
	}

	SaveMgr.save_game(slot, data)

	print("✅ 存档到槽 %d（含骰子次数）" % slot)
	_refresh_save_buttons()
	_refresh_load_buttons()





func _do_load(slot: int):
	print("📂 从槽 %d 读取存档" % slot)
	var data = SaveMgr.load_game(slot)
	if data.size() == 0:
		print("⚠️ 槽 %d 没有存档" % slot)
		return
	await SaveMgr.restore_game(data)


func _refresh_save_buttons():
	_refresh_slot_buttons("save")

func _refresh_load_buttons():
	_refresh_slot_buttons("load")


# =====================================
# ✅ 通用函数：生成存档槽按钮
# =====================================
func _refresh_slot_buttons(mode: String):
	var vbox_path = "Panel/TabContainer/%s/ScrollContainer/VBoxContainer" % (mode.capitalize())
	var vbox = get_node(vbox_path)

	for c in vbox.get_children():
		c.queue_free()

	for i in range(9):
		var data = SaveMgr.load_game(i)
		var button = TextureButton.new()
		button.custom_minimum_size = Vector2(400, 225)
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		# ✅ 如果是 load 模式，空槽直接跳过
		if mode == "load" and data.size() == 0:
			continue

		# ✅ 设置截图 / 默认图片
		if data.has("screenshot") and FileAccess.file_exists(data["screenshot"]):
			var img = Image.new()
			img.load(data["screenshot"])
			var tex = ImageTexture.create_from_image(img)
			button.texture_normal = tex
		else:
			button.texture_normal = preload("res://icon.svg")  # 或 res://assets/default_slot.png

		# ✅ 槽编号
		var slot_label = Label.new()
		slot_label.text = "%s %d" % [tr("存档槽"), i]
		slot_label.add_theme_font_size_override("font_size", 20)
		slot_label.add_theme_color_override("font_color", Color.WHITE)
		slot_label.add_theme_constant_override("outline_size", 3)
		slot_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		slot_label.position = Vector2(10, 10)
		button.add_child(slot_label)


		# ✅ 时间显示（仅有存档时）
		if data.size() > 0:
			var time_label = Label.new()
			time_label.text = data.get("time", "无时间")
			time_label.add_theme_font_size_override("font_size", 16)
			time_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			time_label.add_theme_constant_override("outline_size", 3)
			time_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			time_label.position = Vector2(10, 190)
			button.add_child(time_label)

		# ✅ 点击事件
		button.pressed.connect(func():
			pending_action = mode
			pending_slot = i
			if mode == "save":
				confirm_dialog.dialog_text = tr("确定要覆盖存档槽 %d 吗？") % i
			else:
				confirm_dialog.dialog_text = tr("确定要读取存档槽 %d 吗？") % i
			confirm_dialog.popup_centered()
		)

		vbox.add_child(button)
		UiAnimator.apply_button_effects(button)
# ===========================================================
# ✅ 控制 OptionUI 的输入激活 / 禁用
# ===========================================================
func _set_option_active(state: bool) -> void:
	var ui_root = get_tree().current_scene.get_node("UI")
	if not ui_root:
		return
	if not ui_root.has_node("OptionUI"):
		return

	var option_ui = ui_root.get_node("OptionUI")

	if not state:
		# 打开 Setting → 记录当前状态再隐藏
		_option_was_visible = option_ui.visible
		if option_ui.visible:
			option_ui.hide()
			print("🚫 OptionUI 已隐藏（原本可见）")
	else:
		# 关闭 Setting → 仅当原本是显示时才恢复
		if _option_was_visible:
			option_ui.show()
			print("✅ OptionUI 已恢复显示")
		else:
			print("⚙️ OptionUI 原本隐藏，保持隐藏")

func _update_ui_texts() -> void:

	# ===================================
	# 🧭 顶部 Tab 标题
	# ===================================
	var tabs = $Panel/TabContainer
	tabs.set_tab_title(0, tr("保存"))
	tabs.set_tab_title(1, tr("读取"))
	tabs.set_tab_title(2, tr("游戏树"))
	tabs.set_tab_title(3, tr("文本设置"))
	tabs.set_tab_title(4, tr("声音设置"))

	print("🈶 SettingMain 已更新语言 →", TranslationServer.get_locale())

	# ===================================
	# 🌏 文本设置
	# ===================================
	var lang_root = $Panel/TabContainer/Language/ScrollContainer/Language/button
	lang_root.get_node("Chinese").text = tr("中文")
	lang_root.get_node("English").text = tr("English")

	# ===================================
	# 🔊 声音设置
	# ===================================
	var sound_root = $Panel/TabContainer/Music/ScrollContainer/Music

	# --- 全局音量 ---
	sound_root.get_node("GlobalSound/Global").text = tr("全局音量")

	# --- 按钮区域 ---
	var sound_buttons = sound_root.get_node("button")
	sound_buttons.get_node("SoundEffects").text = tr("音效启用")
	sound_buttons.get_node("CharacterVoice").text = tr("人物语音启用")
	sound_buttons.get_node("BGM").text = tr("BGM启用")

	# ===================================
	# 🗂 右上角按钮
	# ===================================
	$Panel/ClearButton.text = tr("清除所有存档")
	$Panel/BackToMenuButton.text = tr("返回主菜单")
	$Panel/CloseButton.text = tr("关闭页面")
	$Panel/QuitButton.text = tr("退出游戏")


	# 确认对话框的标题
	if $Panel.has_node("ConfirmDialog"):
		$Panel/ConfirmDialog.dialog_text = tr("确定执行此操作吗？")

	print("✅ Setting UI 已根据语言更新 ->", TranslationServer.get_locale())
	
	
	
func clear_ui():
	var ui_root = get_tree().current_scene.get_node("UI")
	if ui_root and ui_root.has_node("PlayerStatu"):
		ui_root.get_node("PlayerStatu").hide()

func restore_ui():
	var ui_root = get_tree().current_scene.get_node("UI")
	if ui_root and ui_root.has_node("PlayerStatu"):
		ui_root.get_node("PlayerStatu").show()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# 如果 Setting 面板当前是打开的
		if panel.visible:
			_on_close_pressed()
			return
		if not panel.visible:
			_on_button_pressed()
			return
func _init_language_settings() -> void:
	var saved_lang := _load_language()
	TranslationServer.set_locale(saved_lang)
	ResMgr.set_language(saved_lang)

	_language_lock = true
	chinese_button.button_pressed = (saved_lang != "en")
	english_button.button_pressed = (saved_lang == "en")
	_language_lock = false

	chinese_button.toggled.connect(_on_chinese_toggled)
	english_button.toggled.connect(_on_english_toggled)

	_update_ui_texts()  # 刷新 SettingMain 自己的 Tab 标题等


func _on_chinese_toggled(pressed: bool) -> void:
	if _language_lock:
		return
	_language_lock = true

	if pressed:
		english_button.button_pressed = false
		_set_language("zh")
	else:
		english_button.button_pressed = true
		_set_language("en")

	_language_lock = false


func _on_english_toggled(pressed: bool) -> void:
	if _language_lock:
		return
	_language_lock = true

	if pressed:
		chinese_button.button_pressed = false
		_set_language("en")
	else:
		chinese_button.button_pressed = true
		_set_language("zh")

	_language_lock = false


func _set_language(lang_code: String) -> void:
	TranslationServer.set_locale(lang_code)
	ResMgr.set_language(lang_code)
	_save_language(lang_code)

	# 更新 SettingMain 自己的 UI
	_update_ui_texts()

	# 如果你希望当前场景里其它 UI 也跟着变（talk_ui、option_ui等）
	var ui_root := get_tree().current_scene.get_node_or_null("UI")
	if ui_root:
		for child in ui_root.get_children():
			if child.has_method("_update_ui_texts"):
				var m := child.get_method_list().filter(func(x): return x.name == "_update_ui_texts")
				if m.size() > 0 and m[0].args.size() == 0:
					child.call("_update_ui_texts")
				else:
					child.call("_update_ui_texts", lang_code)

func _init_audio_settings() -> void:
	# --- 主音量 ---
	var saved_volume := _load_master_volume()
	main_sound_slider.min_value = 0
	main_sound_slider.max_value = 100
	main_sound_slider.step = 1
	main_sound_slider.value = saved_volume
	global_label.text = "%d%%" % int(saved_volume)
	_apply_master_volume(saved_volume)

	main_sound_slider.value_changed.connect(_on_main_sound_changed)

	# --- BGM 开关 ---
	var bgm_enabled := _load_bgm_enabled()
	bgm_toggle.button_pressed = bgm_enabled
	_apply_bgm_enabled(bgm_enabled)
	bgm_toggle.toggled.connect(_on_bgm_toggled)


func _on_main_sound_changed(value: float) -> void:
	global_label.text = "%d%%" % int(value)
	_apply_master_volume(value)
	_save_master_volume(value)


func _apply_master_volume(value: float) -> void:
	var db := _value_to_db(value)
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, db)
	AudioServer.set_bus_mute(bus, value <= 0)


func _value_to_db(value: float) -> float:
	if value <= 0:
		return -80.0
	return lerp(-30.0, 0.0, value / 100.0)


func _on_bgm_toggled(pressed: bool) -> void:
	_apply_bgm_enabled(pressed)
	_save_bgm_enabled(pressed)


func _apply_bgm_enabled(enabled: bool) -> void:
	# ✅ 注意：游戏内场景不一定叫 Start，所以别找 Start
	# 你只要找当前场景 UI/音频里的 AudioStreamPlayer
	var bgm_player = get_tree().root.find_child("AudioStreamPlayer", true, false)
	if bgm_player:
		if enabled:
			if not bgm_player.playing:
				bgm_player.play()
		else:
			bgm_player.stop()
func _save_language(lang_code: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://config.cfg") != OK:
		cfg = ConfigFile.new()
	cfg.set_value("settings", "language", lang_code)
	cfg.save("user://config.cfg")

func _load_language() -> String:
	var cfg := ConfigFile.new()
	if cfg.load("user://config.cfg") == OK:
		return cfg.get_value("settings", "language", "zh")
	return "zh"

func _save_master_volume(value: float) -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://config.cfg") != OK:
		cfg = ConfigFile.new()
	cfg.set_value("settings", "master_volume", value)
	cfg.save("user://config.cfg")

func _load_master_volume() -> float:
	var cfg := ConfigFile.new()
	if cfg.load("user://config.cfg") == OK:
		return float(cfg.get_value("settings", "master_volume", 80.0))
	return 80.0

func _save_bgm_enabled(enabled: bool) -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://config.cfg") != OK:
		cfg = ConfigFile.new()
	cfg.set_value("settings", "bgm_enabled", enabled)
	cfg.save("user://config.cfg")

func _load_bgm_enabled() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load("user://config.cfg") == OK:
		return bool(cfg.get_value("settings", "bgm_enabled", true))
	return true
