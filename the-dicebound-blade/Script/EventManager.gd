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
			print(1)
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
		"show_name":
			if ui_root and ui_root.has_node("talk_ui"):
				var talk_ui = ui_root.get_node("talk_ui")
				var name_label_path = "NinePatchRect/NameLabel"
				if talk_ui.has_node(name_label_path):
					var name_label = talk_ui.get_node(name_label_path)
					name_label.text = "%s:" % target
					name_label.show()
		"hide_name":
			if ui_root and ui_root.has_node("talk_ui"):
				var talk_ui = ui_root.get_node("talk_ui")
				var name_label_path = "NinePatchRect/NameLabel"
				if talk_ui.has_node(name_label_path):
					talk_ui.get_node(name_label_path).hide()
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
	if not char_root:
		return

	# 如果已有同名节点，先移除
	if char_root.has_node(name):
		print("⚠️ 已存在角色节点:", name, " → 先移除旧节点")
		char_root.get_node(name).queue_free()

	var path = ResMgr.get_character(name)
	print("⚙️ 生成角色:", name, "路径:", path)
	if path != "":
		var scene = load(path) as PackedScene
		var char_node = scene.instantiate()
		char_node.position = pos
		char_node.name = name
		char_node.add_to_group("characters")
		char_root.add_child(char_node)
		print("✅ 已生成角色节点:", char_node.name)
	else:
		push_error("❌ 找不到角色资源: %s" % name)

func _remove_character(char_root: Node, name: String) -> void:
	if not char_root:
		return

	for node in char_root.get_children():
		# 情况 1：根节点本身就是角色名
		if node.name == name:
			node.queue_free()
			print("🗑️ 已删除角色节点:", name)
			return

		# 情况 2：角色被包裹在子节点（例如 @Node2D@45/Junker）
		for sub in node.get_children():
			if sub.name == name:
				node.queue_free()  # 删除整个父节点（一起清掉）
				print("🗑️ 已删除子节点角色:", name)
				return

func _shake_character(name: String, amount: float = 10.0, d1: float = 0.05, d2: float = 0.1) -> void:
	var target: Node2D = null

	for node in get_tree().get_nodes_in_group("characters"):
		# 1) 直接匹配或包含（兼容自动追加实例号的名字）
		if node.name == name or name in node.name:
			target = node
			break

		# 2) 子节点匹配（例如 @Node2D@45 / Junker）
		for child in node.get_children():
			if child is Node and (child.name == name or name in child.name):
				target = node   # 抖动父节点，让整个人物动
				break
		if target:
			break

	if not target:
		push_warning("⚠️ 未找到角色用于 shake: %s" % name)
		return

	var x := target.position.x
	var tween := create_tween()
	tween.tween_property(target, "position:x", x + amount, d1)
	tween.tween_property(target, "position:x", x - amount, d2)
	tween.tween_property(target, "position:x", x, d1)

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

	# ⚡ 等待一帧，确保 queue_free 完成
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
