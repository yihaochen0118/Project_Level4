extends Control

@onready var hbox = $VBoxContainer

func _ready():
	_update_equipment_buttons()
	PlayerData.item_changed.connect(_update_equipment_buttons)

func _update_equipment_buttons():
	var items = PlayerData.inventory.keys()
	for i in range(hbox.get_child_count()):
		var btn = hbox.get_child(i)
		if i < items.size():
			var item_name = items[i]
			#btn.text = item_name
			btn.disabled = false
			btn.show()
			if btn.pressed.is_connected(_on_item_pressed):
				btn.pressed.disconnect(_on_item_pressed)
			btn.pressed.connect(_on_item_pressed.bind(item_name))
		else:
			btn.text = ""
			btn.disabled = true
			btn.hide()
	print("🎒 当前背包内容:", PlayerData.inventory)

func _on_item_pressed(item_name: String):
	print("🎯 使用装备: ", item_name)
	PlayerData.use_item(item_name)
