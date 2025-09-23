extends Control

@onready var vbox = $VBoxContainer

signal option_selected(index: int, text: String)

# 动态设置选项
func set_options(options: Array):
	var buttons = vbox.get_children()

	# 设置按钮文本 & 显示状态
	for i in range(buttons.size()):
		if i < options.size():
			buttons[i].text = str(options[i])
			buttons[i].show()
		else:
			buttons[i].hide()

	# 绑定点击事件（先断开旧的）
	for i in range(min(buttons.size(), options.size())):
		var callable = Callable(self, "_on_button_pressed").bind(i, options[i])
		if buttons[i].is_connected("pressed", callable):
			buttons[i].disconnect("pressed", callable)
		buttons[i].connect("pressed", callable)

# 按钮点击时触发
func _on_button_pressed(index: int, text: String):
	hide()  # 选择完隐藏
	emit_signal("option_selected", index, text)  # 发信号
