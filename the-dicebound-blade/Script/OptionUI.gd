extends Control
@onready var vbox = $VBoxContainer

signal option_selected(index: int, text: String, dc: int)

func set_options(options: Array):
	var buttons = vbox.get_children()

	for i in range(buttons.size()):
		if i < options.size():
			var option_data = options[i]   # { "text": "...", "dc": 12 }
			buttons[i].text = option_data["text"]
			buttons[i].show()

			# 清理旧连接
			for c in buttons[i].get_signal_connection_list("pressed"):
				buttons[i].disconnect("pressed", c.callable)

			# 绑定新连接
			var callable = Callable(self, "_on_button_pressed").bind(
	i, 
	option_data["text"], 
	option_data.get("dc", 0), 
	option_data.get("check", "") 
)
			buttons[i].connect("pressed", callable)
		else:
			buttons[i].hide()

func _on_button_pressed(index: int, text: String, dc: int, check: String):
	hide()
	emit_signal("option_selected", index, text, dc, check)
