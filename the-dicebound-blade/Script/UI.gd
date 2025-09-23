extends Node2D

var dialogues = []
var dialogue_index = 0

var full_text = ""
var current_text = ""
var typing = false
var typing_speed = 0.03
var typing_index = 0
var is_waiting_choice = false  # 是否在等玩家选择

var dialogue_box = null   # 实例化的对话框
var option_box= null      #实例化的选项框
var label = null          # RichTextLabel
signal dialogue_event(event_data: Dictionary)   # 新增信号
var current_scene_name = ""  # 记录当前对话脚本名

func _ready():
	pass

# =============== 加载 JSON 对话 ===============
func load_dialogues(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		dialogues = JSON.parse_string(content)
		if dialogues == null:
			push_error("JSON 解析失败: %s" % path)
			dialogues = []
		else:
			# 保存场景名（去掉路径）
			for key in ResMgr.dialogues.keys():
				if ResMgr.dialogues[key] == path:
					current_scene_name = key
					break
	dialogue_index = 0

# =============== 确保对话框存在 ===============
func ensure_dialogue_box():
	if dialogue_box == null:
		var path = ResMgr.get_ui("talk_ui")  # 通过资源管理器拿路径
		if path != "":
			var scene = load(path) as PackedScene
			dialogue_box = scene.instantiate()
			var ui_root = get_tree().current_scene.get_node("UI")
			ui_root.add_child(dialogue_box)

			# 找文本节点
			label = dialogue_box.get_node("NinePatchRect/RichTextLabel") as RichTextLabel
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

		# 如果有事件，执行事件（事件就是这一行的内容，不会跳过）
		if entry.has("event"):
			if typeof(entry["event"]) == TYPE_DICTIONARY:
				EventMgr.handle_event(entry["event"])
			elif typeof(entry["event"]) == TYPE_ARRAY:
				for ev in entry["event"]:
					if typeof(ev) == TYPE_DICTIONARY:
						EventMgr.handle_event(ev)

		# 如果有文字，就进入打字机效果
		if entry.has("text"):
			full_text = entry["text"]
			typing_index = 0
			current_text = ""
			label.text = ""
			typing = true
		else:
			# 没有文字的事件行：显示完直接等下一次点击
			full_text = ""
			current_text = ""
			label.text = ""
			typing = false
	else:
		# 脚本结束
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
# ================== 供 ChoiceUi 调用 ================== 这才是当玩家选择完后的外部链接
func on_option_selected(index: int, text: String):
	print("玩家选择了: %s (索引 %d)" % [text, index])
	is_waiting_choice = false

	# 拼接分支名
	var branch_name = "%s.%d" % [current_scene_name, index + 1]

	# 尝试加载分支
	_change_scene(branch_name)

# 内部函数：切换对话脚本
func _change_scene(scene_name: String):
	var path = ResMgr.get_dialogue(scene_name)
	if path != "":
		load_dialogues(path)
		show_next_line()
	else:
		push_error("找不到对话脚本: %s" % scene_name)
		
# UI 接口：处理输入（供 main.gd 调用）
func handle_input():
	if is_waiting_choice:
		return  # 如果在等选项，禁用继续
	if typing:
		label.text = full_text
		typing = false
	else:
		show_next_line()
		
# =============== 事件处理 ===============
# talkUI.gd
func handle_event(event):
	EventMgr.handle_event(event)
