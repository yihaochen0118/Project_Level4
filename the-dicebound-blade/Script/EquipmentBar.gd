extends Control

@onready var hbox = $NinePatchRect/VBoxContainer
@onready var tooltip = $Tooltip
@onready var tooltip_label = $Tooltip/Label

func _ready():
	tooltip.hide()
	_update_equipment_buttons()
	PlayerData.item_changed.connect(_update_equipment_buttons)

func _update_equipment_buttons():
	var items = PlayerData.inventory.keys()

	for btn in hbox.get_children():
		btn.icon = null
		btn.text = ""
		btn.disabled = true
		btn.hide()

		# 🆕 如果有 CountLabel，清空它的文本
		if btn.has_node("CountLabel"):
			btn.get_node("CountLabel").text = ""

	for i in range(min(items.size(), hbox.get_child_count())):
		var btn = hbox.get_child(i)
		var item_name = items[i]
		var path = ResMgr.items.get(item_name, "")
		if path == "":
			continue

		var scene = load(path)
		if scene == null:
			continue

		var item_instance = scene.instantiate()
		if item_instance.has_method("_ready"):
			item_instance._ready()

		btn.disabled = false
		btn.show()

		if item_instance.icon:
			btn.icon = item_instance.icon
			btn.text = ""
		else:
			btn.text = item_name

		# 🆕 更新已有 CountLabel
		var count = PlayerData.inventory.get(item_name, 1)
		if btn.has_node("CountLabel"):
			var label = btn.get_node("CountLabel")
			if count >= 1:
				label.text = "x%d" % count
			else:
				label.text = ""
			label.visible = count >= 1

		# 信号绑定
		if btn.pressed.is_connected(_on_item_pressed):
			btn.pressed.disconnect(_on_item_pressed)
		if btn.mouse_entered.is_connected(_on_button_hover):
			btn.mouse_entered.disconnect(_on_button_hover)
		if btn.mouse_exited.is_connected(_on_button_leave):
			btn.mouse_exited.disconnect(_on_button_leave)

		btn.pressed.connect(_on_item_pressed.bind(item_name))
		btn.mouse_entered.connect(_on_button_hover.bind(item_name))
		btn.mouse_exited.connect(_on_button_leave)




func _on_item_pressed(item_name: String):
	print("🎯 使用装备: ", item_name)
	PlayerData.use_item(item_name)


# 🪶 当鼠标悬停在按钮上时
func _on_button_hover(item_name: String):
	var path = ResMgr.items.get(item_name, "")
	if path == "":
		print("⚠️ 未找到物品路径: ", item_name)
		return

	var scene = load(path)
	if scene == null:
		print("⚠️ 无法加载物品场景: ", path)
		return

	var item_instance = scene.instantiate()

	# ⚙️ 手动触发 _ready，确保 item_name / description 初始化
	if item_instance.has_method("_ready"):
		item_instance._ready()

	# 🔤 使用 tr() 对文本进行翻译
	var name_key = item_instance.item_name if item_instance.item_name != "" else item_name
	var desc_key = item_instance.description if item_instance.description != "" else "NO_DESC"

	var name_text = tr(name_key)
	var desc_text = tr(desc_key)

	# 设置 Tooltip 文本
	tooltip_label.text = "%s\n%s" % [name_text, desc_text]
	tooltip.show()
	set_process_input(true)


# 🚫 鼠标移开
func _on_button_leave():
	tooltip.hide()
	set_process_input(false)


# 🎯 让Tooltip跟随鼠标
func _input(event):
	if event is InputEventMouseMotion and tooltip.visible:
		var tooltip_size = tooltip.size
		var margin = Vector2(-tooltip_size.x - 15, 10)  # ← 左移说明框宽度，往下偏一点
		var new_pos = event.position + margin

		# 防止 Tooltip 超出屏幕边界
		var viewport_size = get_viewport_rect().size

		# 如果超出左边，就往右移
		if new_pos.x < 0:
			new_pos.x = 10
		# 如果超出下边，就往上移
		if new_pos.y + tooltip_size.y > viewport_size.y:
			new_pos.y = viewport_size.y - tooltip_size.y - 10

		tooltip.position = new_pos
