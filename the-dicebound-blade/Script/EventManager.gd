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

		# ========== 分支判定 ==========
		"if_flag":
			var flag_name = event.get("flag", "")
			var expected = event.get("value", true)
			var target_scene = event.get("target", "")
			if flag_name == "" or target_scene == "":
				push_warning("⚠️ if_flag 缺少 flag 或 target 字段")
				return

			var result = PlayerData.get_flag(flag_name)
			if result == expected:
				print("✅ Flag 成立: %s=%s → 跳转 %s" % [flag_name, str(expected), target_scene])
				_change_scene(target_scene)
			else:
				print("🚫 Flag 不成立: %s=%s" % [flag_name, str(result)])

		"_else_flag":
			var flag_name = event.get("flag", "")
			var target_scene = event.get("target", "")
			if flag_name == "" or target_scene == "":
				push_warning("⚠️ else_flag 缺少 flag 或 target 字段")
				return

			var result = PlayerData.get_flag(flag_name)
			if not result:
				print("🔄 Flag 不成立 → 跳转 %s" % target_scene)
				_change_scene(target_scene)
				
		"set_flag":
			var flag_name = event.get("flag", "")
			var value = event.get("value", true)
			if flag_name != "":
				PlayerData.flags[flag_name] = value
				print("🏳️ 设置Flag: %s = %s" % [flag_name, str(value)])
		"unlock":
			_unlock(event)

		# ========== 场景切换 ==========
		"change_scene":
			_change_scene(target)
			
		"add_dice":
			_handle_add_dice(event)
			
		"add_item":
			_handle_add_item(event)
		"game_over":
			_handle_game_over(event)
		"chapter_change":
			PlayerData.set_chapter(str(target))
		_:
			push_warning("未知事件: %s" % action)
	


# ========== 内部函数 ==========
func _spawn_character(char_root: Node, name: String, pos: Vector2) -> void:
	if not char_root:
		return
	if char_root.has_node(name):
		char_root.get_node(name).queue_free()
	var path = ResMgr.get_character(name)
	if path != "":
		var scene = load(path) as PackedScene
		var char_node = scene.instantiate()
		char_node.position = pos
		char_node.name = name
		char_node.add_to_group("characters")
		char_root.add_child(char_node)
	else:
		push_error("❌ 找不到角色资源: %s" % name)

func _remove_character(char_root: Node, name: String) -> void:
	if not char_root:
		return
	for node in char_root.get_children():
		if node.name == name:
			node.queue_free()
			return
		for sub in node.get_children():
			if sub.name == name:
				node.queue_free()
				return

func _shake_character(name: String, amount: float = 10.0, d1: float = 0.05, d2: float = 0.1) -> void:
	var target: Node2D = null
	for node in get_tree().get_nodes_in_group("characters"):
		if node.name == name or name in node.name:
			target = node
			break
		for child in node.get_children():
			if child is Node and (child.name == name or name in child.name):
				target = node
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
	# ✅ 获取对话文件路径
	var path = ResMgr.get_dialogue(scene_name)
	if path == "":
		push_error("找不到对话脚本: %s" % scene_name)
		return

	# ✅ 获取当前场景根节点
	var root = get_tree().current_scene
	if not root:
		push_error("❌ 当前没有加载任何场景")
		return

	# ✅ 清空所有角色立绘
	if root.has_node("Charact"):
		var char_root = root.get_node("Charact")
		for node in char_root.get_children():
			node.queue_free()
		print("🗑️ 切换到 %s 前清空所有立绘" % scene_name)

	# ✅ 获取 UI 节点
	var ui = root.get_node("UI") if root.has_node("UI") else null
	if not ui:
		push_error("⚠️ 当前场景缺少 UI 节点")
		return

	# ✅ 更新当前对话名（存到 UI.gd 里的 current_scene_name）
	ui.current_scene_name = scene_name

	# ✅ 加载新剧情
	ui.load_dialogues(path)
	ui.show_next_line()


# ========== 新增：选项记录 + 分支判断 ==========
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
		var callable = Callable(ui_root, "on_option_selected")
		if option_ui.is_connected("option_selected", callable):
			option_ui.disconnect("option_selected", callable)
		option_ui.connect("option_selected", callable)
	ui_root.is_waiting_choice = true


# ✅ 如果剧情分支要判断之前的flag
func _check_flag_condition(ui_root: Node, event: Dictionary) -> void:
	if not ui_root:
		return
	var flag_name = event.get("flag", "")
	var expected = event.get("equals", true)
	var actual = false
	if PlayerData.has_method("get_flag"):
		actual = PlayerData.get_flag(flag_name)
	else:
		actual = flag_name in PlayerData.choice_history
	ui_root.skip_next_line = (actual != expected)


func _else_flag(ui_root: Node) -> void:
	if not ui_root:
		return
	# 如果上一行被跳过，则现在执行
	if ui_root.has("skip_next_line") and ui_root.skip_next_line:
		ui_root.skip_next_line = false
	else:
		ui_root.skip_next_line = true

func _handle_add_dice(event: Dictionary):
	var sides = event.get("sides", 6)
	var amount = event.get("amount", 1)
	
	PlayerData.add_dice_uses(sides, amount)
	
	print("🪄 事件触发：为 D%d 增加 %d 次使用次数" % [sides, amount])
	
func _unlock(event: Dictionary) -> void:
	var target_id := str(event.get("target",""))
	if target_id == "":
		push_warning("⚠️ unlock 缺少 target")
		return

	# ✅ 写入永久解锁进度（独立于 flags / 存档）
	PlayerData.unlock_node(target_id)
	print("🌟 永久解锁节点: ", target_id)

	# ✅ 如果设置里 GameTree 打开，刷新一下
	var root = get_tree().current_scene
	if not root: return
	var ui_root = root.get_node("UI") if root.has_node("UI") else null
	if ui_root and ui_root.has_node("Setting/Panel/TabContainer/GameTree/GameTreeHolder"):
		var gt = ui_root.get_node("Setting/Panel/TabContainer/GameTree/GameTreeHolder")
		if gt and gt.has_method("refresh"):
			gt.refresh()

func _handle_add_item(event: Dictionary) -> void:
	var item_name = event.get("target", "")
	var amount = event.get("amount", 1)

	if item_name == "":
		push_warning("⚠️ get_item 缺少 target 字段")
		return

	if not ResMgr.items.has(item_name):
		push_warning("⚠️ 未找到物品资源: %s" % item_name)
		return

	PlayerData.add_item(item_name, amount)

func _handle_game_over(event: Dictionary) -> void:
	var message: String = str(event.get("message", "游戏结束"))

	var root = get_tree().current_scene
	if not root:
		return

	var ui_root = root.get_node("UI") if root.has_node("UI") else null
	if not ui_root:
		return

	# 加载 Popup 场景
	var path = ResMgr.get_ui("GameOverPopup")
	if path == "":
		push_error("未注册 GameOverPopup")
		return

	var scene = load(path) as PackedScene
	var popup = scene.instantiate()
	ui_root.add_child(popup)

	if popup.has_method("show_game_over"):
		popup.show_game_over(message)
	ui_root.is_waiting_choice = true
