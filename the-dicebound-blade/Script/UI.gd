extends Node2D


var dialogues = []
var dialogue_index = 0
var name_label: Label = null  # 新增，用于显示说话人名字


var full_text = ""
var current_text = ""
var typing = false
var typing_speed = 0.03
var typing_index = 0
var is_waiting_choice = false  # 是否在等玩家选择
var dc_value=0 #当前dc value

var setting_ui: Control = null
var dialogue_box = null   # 实例化的对话框
var option_box= null      #实例化的选项框
var label = null          # RichTextLabel
signal dialogue_event(event_data: Dictionary)# 新增信号
var current_scene_name = ""  # 记录当前对话脚本名

func _ready():
	ensure_setting()

# =============== 加载 JSON 对话 ===============
func load_dialogues(path: String, start_index: int = 0):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		dialogues = JSON.parse_string(content)
		if dialogues == null:
			push_error("JSON 解析失败: %s" % path)
			dialogues = []
		else:
			for key in ResMgr.dialogues.keys():
				if ResMgr.dialogues[key] == path:
					current_scene_name = key
					break
	dialogue_index = start_index
	
func replay_state_until(index: int):
	# 防御性判断
	if dialogues.size() == 0 or index <= 0:
		return

	for i in range(index):
		var entry = dialogues[i]
		if entry.has("event"):
			if typeof(entry["event"]) == TYPE_DICTIONARY:
				_replay_if_state_event(entry["event"])
			elif typeof(entry["event"]) == TYPE_ARRAY:
				for ev in entry["event"]:
					if typeof(ev) == TYPE_DICTIONARY:
						_replay_if_state_event(ev)
						
func _replay_if_state_event(event: Dictionary):
	var action = event.get("action", "")
	match action:
		"set_background", "spawn_character", "hide_talk_ui", "show_talk_ui":
			EventMgr.handle_event(event)
		_: # 忽略其他类型（如 text, play_sound, move_camera 等）
			pass

# =============== 确保对话框存在 ===============
func ensure_dialogue_box():
	if dialogue_box != null and is_instance_valid(dialogue_box):
		return  # 已经存在并且有效

	# 先去树里找是否有 talk_ui 节点
	var ui_root = get_tree().current_scene.get_node("UI")

	# 否则实例化新的
	var path = ResMgr.get_ui("talk_ui")  # 通过资源管理器拿路径
	if path != "":
		var scene = load(path) as PackedScene
		if scene == null:
			push_error("加载 talk_ui 失败: %s" % path)
			return

		dialogue_box = scene.instantiate()
		dialogue_box.name = "talk_ui"  # 保证下次能找到
		ui_root.add_child(dialogue_box)

		# 找文本节点
		label = dialogue_box.get_node("NinePatchRect/RichTextLabel") as RichTextLabel
		name_label = dialogue_box.get_node("NinePatchRect/NameLabel") as Label
	else:
		push_error("找不到 talk_ui 场景资源")

			
# =============== 确保选择框存在 ===============
func ensure_option_box():
	if option_box != null:
		return  # 已经存在，不用重复创建

	var path := ResMgr.get_ui("Option_ui")  # 从资源管理器获取路径
	if path == "":
		push_error("找不到 OptionUI 场景资源")
		return

	var scene := load(path)
	if scene == null or not (scene is PackedScene):
		push_error("option_ui 资源无效或不是 PackedScene")
		return

	# 实例化 UI 场景
	option_box = scene.instantiate()
	# 找到 UI 根节点
	var ui_root := get_tree().current_scene.get_node("UI")
	if ui_root == null:
		push_error("当前场景中缺少 UI 节点")
		return

	# 把选项挂到 UI 上
	ui_root.add_child(option_box)
	option_box.hide()
	# 获取 VBoxContainer
	var vbox: VBoxContainer = option_box.get_node("VBoxContainer") as VBoxContainer
	if vbox == null:
		push_error("未找到 VBoxContainer 节点")
		return

	# 获取所有按钮
	var buttons := []
	for child in vbox.get_children():
		if child is Button:
			buttons.append(child)

	if buttons.size() == 0:
		push_warning("OptionUI 中没有找到任何按钮")
	else:
		print("成功加载 OptionUI，按钮数量: ", buttons.size())



# =============== 打字机效果 ===============
func _process(delta):
	_typing()

func _typing():
	if typing and label:
		if typing_index < full_text.length():
			typing_index += 1
			current_text = full_text.substr(0, typing_index)
			label.text = current_text
		else:
			typing = false

# =============== 显示下一句 ===============
func show_next_line():
	ensure_dialogue_box()
	ensure_option_box()
	
	if dialogue_index < dialogues.size():
		dialogue_box.show()

		var entry = dialogues[dialogue_index]
		dialogue_index += 1
# 显示说话人名字
		if name_label != null:
			if entry.has("speaker"):
				name_label.text = str(entry["speaker"])+":"
				name_label.show()
			else:
				name_label.text = ""
				name_label.hide()

		# 事件执行
		if entry.has("event"):
			if typeof(entry["event"]) == TYPE_DICTIONARY:
				EventMgr.handle_event(entry["event"])
			elif typeof(entry["event"]) == TYPE_ARRAY:
				for ev in entry["event"]:
					if typeof(ev) == TYPE_DICTIONARY:
						EventMgr.handle_event(ev)

		# 打字机文本
		if entry.has("text"):
			full_text = entry["text"]
			typing_index = 0
			current_text = ""
			label.text = ""
			typing = true
		else:
			full_text = ""
			current_text = ""
			label.text = ""
			typing = false
	else:
		if dialogue_box:
			dialogue_box.hide()
			dialogue_box = null
			label = null

			

func spawn_choice_ui(options: Array, callback: Callable):
	# 确保 UI 根节点存在
	var ui_root = get_tree().current_scene.get_node("UI")
	if not ui_root:
		push_error("未找到 UI 根节点")
		return null

	# 通过资源管理器获取 choice_ui 场景路径
	var path = ResMgr.get_ui("choice_ui")
	if path == "":
		push_error("找不到 choice_ui 场景资源")
		return null

	var scene = load(path) as PackedScene
	var choice_ui = scene.instantiate()

	# 挂到 UI 根节点
	ui_root.add_child(choice_ui)

	# 初始化选项（choice_ui.gd 需要实现 set_options）
	if choice_ui.has_method("set_options"):
		choice_ui.set_options(options, callback)
	else:
		push_warning("choice_ui 未实现 set_options 方法")

	return choice_ui
# ================== 供 optionUi 调用 ================== 这才是当玩家选择完后的外部链接
func on_option_selected(index: int, text: String, dc: int, check: String):
	dc_value = dc
	print("玩家选择了: %s (索引 %d, DC=%d, 检定=%s)" % [text, index, dc, check])
	is_waiting_choice = false

	# ✅ 记录选择历史
	PlayerData.choice_history.append({
		"scene": current_scene_name,
		"index": index,
		"text": text,
		"time": Time.get_datetime_string_from_system()
	})

	result_success(index, dc, check)


# 判断是否成功
func result_success(index: int, dc: int, check: String = ""):
	if dc == 0:
		var branch_name = "%s.%d" % [current_scene_name, index + 1]
		EventMgr._change_scene(branch_name)
		return

	# ⚡ 分离出去，保持 result_success 简洁
	perform_check(index, dc, check)


# 处理骰子检定逻辑
func perform_check(index: int, dc: int, check: String):
	roll_dice(func(sides: int, result: int):
		var modifier = PlayerData.get_stat(check)
		var total = result + modifier

		var success = 0
		if total >= dc:
			success = 1

		var outcome_text = "失败"
		if success == 1:
			outcome_text = "成功"

		print("骰子结果: d%d=%d + %d (%s修正) = %d vs DC %d → %s" %
			[sides, result, modifier, check, total, dc, outcome_text])

		var branch_name = "%s.%d.%d" % [current_scene_name, index + 1, success]
		EventMgr._change_scene(branch_name)
	, check)


# 内部函数：切换对话脚本
func _change_scene(scene_name: String):
	var path = ResMgr.get_dialogue(scene_name)
	if path != "":
		load_dialogues(path)
		show_next_line()
	else:
		push_error("找不到对话脚本: %s" % scene_name)
  
func roll_dice(callback: Callable, check: String = ""):
	var ui_root = get_tree().current_scene.get_node("UI")
	if not ui_root:
		push_error("未找到 UI 节点")
		return

	var path = ResMgr.get_ui("Dice_CardChoose")
	if path == "":
		push_error("找不到 Dice_CardChoose 场景资源")
		return

	var scene = load(path) as PackedScene
	if scene == null:
		push_error("Dice_CardChoose 资源加载失败: %s" % path)
		return

	var dice_ui = scene.instantiate()
	ui_root.add_child(dice_ui)

	# ⚡ 把 check 传进去
	dice_ui.check = check
	print(check)
	dice_ui._fix_rightPanel(dc_value)

	# 绑定选择后的回调
	dice_ui.dice_chosen.connect(func(sides: int, result: int):
		dice_ui._result_feedback(sides, result, check)  # 显示时带上修正
		if callback != null:
			callback.call(sides, result)
	)
	
func ensure_setting():
	if setting_ui and is_instance_valid(setting_ui):
		return  # 已经加载过

	# 通过资源管理器获取路径（假设你在 ResMgr 里登记过 Setting）
	var path = ResMgr.get_ui("Setting")
	if path == "":
		push_error("找不到 Setting.tscn")
		return

	var scene = load(path) as PackedScene
	if scene == null:
		push_error("加载 Setting 失败: %s" % path)
		return

	# 实例化 Setting.tscn
	setting_ui = scene.instantiate()
	setting_ui.name = "Setting"
	add_child(setting_ui)

func handle_input():
	# 如果在等选择，禁用继续
	if is_waiting_choice:
		return  

	# 如果 Setting 面板可见，禁用剧情点击
	if setting_ui and setting_ui.has_node("Panel") and setting_ui.get_node("Panel").visible:
		return  

	# ⚡ 如果鼠标正好点在一个 Control（按钮等）上 → 不要推进剧情
	var hovered = get_viewport().gui_get_hovered_control()
	if hovered and hovered is Button:
		return  

	if typing:
		label.text = full_text
		typing = false
	else:
		show_next_line()
		
func _set_dialogue_index(value):
	dialogue_index = value
	PlayerData.dialogue_index = value  # 让 PlayerData 也记录下来



		
# =============== 事件处理 ===============
# talkUI.gd
func handle_event(event):
	EventMgr.handle_event(event)
