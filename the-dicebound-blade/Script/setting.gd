extends Control

@onready var save_buttons = $Panel/TabContainer/Save/ScrollContainer/VBoxContainer.get_children()
@onready var load_buttons = $Panel/TabContainer/Load/ScrollContainer/VBoxContainer.get_children()
@onready var quit_button = $Panel/QuitButton
@onready var panel = $Panel
@onready var settingButton = $Setting
@onready var close_button = $Panel/CloseButton
@onready var clear_button = $Panel/ClearButton
@onready var confirm_dialog = $Panel/ConfirmDialog

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

func _on_confirmed():
	match pending_action:
		"quit":	
			print("👋 确认退出游戏")
			get_tree().quit()
		"save": _do_save(pending_slot)
		"load": _do_load(pending_slot)
		"clear":
			SaveMgr.clear_all()
			_refresh_save_buttons()
			_refresh_load_buttons()
	pending_action = ""
	pending_slot = -1

func _do_save(slot: int):
	var ui_root = get_tree().current_scene.get_node("UI")
	if not ui_root:
		return
	var data = {
		"chapter": ui_root.current_scene_name,
		"dialogue_index": ui_root.dialogue_index,
		"hp": PlayerData.hp,
		"stats": PlayerData.stats,
		"time": Time.get_datetime_string_from_system()
	}
	SaveMgr.save_game(slot, data)
	print("✅ 存档到槽 %d" % slot)
	_refresh_save_buttons()
	_refresh_load_buttons()

func _do_load(slot: int):
	var rel_path = "user://save_%d.json" % slot
	var abs_path = ProjectSettings.globalize_path(rel_path)
	print("📂 正在读取存档路径: ", abs_path)
	
	var data = SaveMgr.load_game(slot)
	print(data)
	if data.size() == 0:
		print("⚠️ 槽 %d 没有存档" % slot)
		return

	# 还原玩家数据
	PlayerData.load_from_dict(data)
	# ✅ 清理角色节点
	var char_root = get_tree().current_scene.get_node("Charact")
	if char_root:
		for child in char_root.get_children():
			child.queue_free()
		print("🗑️ 已清理角色节点")

	# 再还原 UI 状态
	var ui_root = get_tree().current_scene.get_node("UI")
	if ui_root:
		ui_root.current_scene_name = data.get("chapter", "")
		ui_root.dialogue_index = data.get("dialogue_index", 0)
		ui_root.load_dialogues(ResMgr.get_dialogue(ui_root.current_scene_name))
		ui_root.show_next_line()

	print("📂 已读取存档槽 %d" % slot)


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
