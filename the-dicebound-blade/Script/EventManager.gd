extends Node
class_name EventManager

# 事件入口
func handle_event(event: Dictionary) -> void:
	if not event.has("action"):
		return

	var action = event["action"]
	var target = event.get("target", "")
	var option = event.get("option","")

	var root = get_tree().current_scene
	var bg = root.get_node("backGround") if root.has_node("backGround") else null
	var char_root = root.get_node("Charact") if root.has_node("Charact") else null
	var ui_root = root.get_node("UI") if root.has_node("UI") else null

	match action:
		# ========== 背景 ==========
		"set_background":
			if bg:
				bg.set_background(target)

		# ========== 人物 ==========
		"spawn_character":
			var pos = Vector2(0, 0)
			if event.has("pos") and typeof(event["pos"]) == TYPE_ARRAY and event["pos"].size() >= 2:
				pos = Vector2(event["pos"][0], event["pos"][1])
			_spawn_character(char_root, target, pos)

		"remove_character":
			_remove_character(char_root, target)

		"shake":
			_shake_character(target)
			
		"hp_lost":
			if event.has("amount"):
				PlayerData.change_hp(-event["amount"])

		"hp_gain":
			if event.has("amount"):
				PlayerData.change_hp(event["amount"])
		
		# ========== UI ==========
		"show_talk_ui":
			if ui_root and ui_root.has_node("talk_ui"):
				ui_root.get_node("talk_ui").show()

		"hide_talk_ui":
			if ui_root and ui_root.has_node("talk_ui"):
				ui_root.get_node("talk_ui").hide()
		
		# ====== 选项框 ======
		"show_option_ui":
			_show_option_ui(ui_root, event)

		# ========== 扩展 ==========
		"change_scene":
			_change_scene(target)
		_:
			push_warning("未知事件: %s" % action)


# ========== 内部函数 ==========
func _spawn_character(char_root: Node, name: String, pos: Vector2) -> void:
	if not char_root: return
	var path = ResMgr.get_character(name)
	if path != "":
		var scene = load(path) as PackedScene
		var char_node = scene.instantiate()
		char_node.position = pos
		char_node.name = name
		char_node.add_to_group("characters")
		char_root.add_child(char_node)

func _remove_character(char_root: Node, name: String) -> void:
	if not char_root: return
	for node in char_root.get_children():
		if node.name == name:
			node.queue_free()
			break

func _shake_character(name: String) -> void:
	for node in get_tree().get_nodes_in_group("characters"):
		if node.name == name:
			var tween = create_tween()
			var x = node.position.x
			tween.tween_property(node, "position:x", x + 10, 0.05)
			tween.tween_property(node, "position:x", x - 10, 0.1)
			tween.tween_property(node, "position:x", x, 0.05)

func _change_scene(scene_name: String) -> void:
	var path = ResMgr.get_dialogue(scene_name)
	if path == "":
		push_error("找不到对话脚本: %s" % scene_name)
		return

	var root = get_tree().current_scene
	if root.has_node("Charact"):
		var char_root = root.get_node("Charact")
		for node in char_root.get_children():
			node.queue_free()
		print("🗑️ 切换到 %s 前清空所有立绘" % scene_name)

	var ui = root.get_node("UI") if root.has_node("UI") else null
	if ui:
		ui.load_dialogues(path)
		ui.show_next_line()

		
func _show_option_ui(ui_root: Node, event: Dictionary) -> void:
	if not ui_root or not ui_root.has_node("OptionUI"):
		return

	var option_ui = ui_root.get_node("OptionUI")
	option_ui.show()

	var options = []
	if event.has("options") and typeof(event["options"]) == TYPE_ARRAY:
		options = event["options"]

	if options.size() > 0 and option_ui.has_method("set_options"):
		option_ui.set_options(options)

		# 绑定信号，把 dc 一起传回去
		var callable = Callable(ui_root, "on_option_selected")
		if option_ui.is_connected("option_selected", callable):
			option_ui.disconnect("option_selected", callable)
		option_ui.connect("option_selected", callable)

	ui_root.is_waiting_choice = true
