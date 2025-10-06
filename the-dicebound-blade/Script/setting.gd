extends Control

@onready var save_buttons = $Panel/TabContainer/Save/ScrollContainer/VBoxContainer.get_children()
@onready var load_buttons = $Panel/TabContainer/Load/ScrollContainer/VBoxContainer.get_children()
@onready var quit_button = $Panel/QuitButton
@onready var panel = $Panel
@onready var settingButton = $Setting
@onready var close_button = $Panel/CloseButton
@onready var clear_button = $Panel/ClearButton
@onready var confirm_dialog = $Panel/ConfirmDialog
@onready var back_to_menu_button = $Panel/BackToMenuButton  # 新增

var pending_action: String = ""  # "save" / "load" / "clear"
var pending_slot: int = -1

func _ready():
	_refresh_save_buttons()
	_refresh_load_buttons()
	panel.hide()

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

func _on_button_pressed():
	panel.visible = not panel.visible
	settingButton.visible = not settingButton.visible
	if panel.visible:
		clear_ui()

func _on_close_pressed():
	panel.hide()
	restore_ui()
	settingButton.visible = true

func _on_quit_pressed():
	pending_action = "quit"
	confirm_dialog.dialog_text = "确定要退出游戏吗？"
	confirm_dialog.popup_centered()

func _on_clear_pressed():
	pending_action = "clear"
	confirm_dialog.dialog_text = "确定要清除所有存档吗？"
	confirm_dialog.popup_centered()

func _on_save_pressed(slot: int):
	pending_action = "save"
	pending_slot = slot
	confirm_dialog.dialog_text = "确定要覆盖存档槽 %d 吗？" % slot
	confirm_dialog.popup_centered()

func _on_load_pressed(slot: int):
	pending_action = "load"
	pending_slot = slot
	confirm_dialog.dialog_text = "确定要读取存档槽 %d 吗？" % slot
	confirm_dialog.popup_centered()

func _on_back_to_menu_pressed():
	pending_action = "back_to_menu"
	confirm_dialog.dialog_text = "确定要返回主菜单吗？\n（当前进度将不会保留）"
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
		return
	var data = {
		"chapter": ui_root.current_scene_name,
		"dialogue_index": max(ui_root.dialogue_index - 1, 0),
		"hp": PlayerData.hp,
		"stats": PlayerData.stats,
		"choices": PlayerData.choice_history,  # ✅ 新增
		"time": Time.get_datetime_string_from_system()
	}
	SaveMgr.save_game(slot, data)
	print("✅ 存档到槽 %d" % slot)
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
	for i in range(save_buttons.size()):
		var data = SaveMgr.load_game(i)
		if data.size() > 0:
			save_buttons[i].text = "存档槽 %d\n时间: %s" % [i, data.get("time", "无时间")]
		else:
			save_buttons[i].text = "存档槽 %d\n<空>" % i

func _refresh_load_buttons():
	for i in range(load_buttons.size()):
		var data = SaveMgr.load_game(i)
		if data.size() > 0:
			load_buttons[i].text = "存档槽 %d\n时间: %s" % [i, data.get("time", "无时间")]
			load_buttons[i].show()
		else:
			load_buttons[i].hide()


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
		if panel.visible:
			_on_close_pressed()
