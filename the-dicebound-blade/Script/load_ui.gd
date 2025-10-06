extends Control

@onready var save_list = $Panel/ScrollContainer/VBoxContainer
@onready var back_button = $Panel/BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	load_save_slots()

func load_save_slots():
	# 清空旧按钮
	for child in save_list.get_children():
		child.queue_free()

	# 打开存档目录
	var dir = DirAccess.open("user://save")
	if dir == null:
		print("⚠️ 没有找到存档目录 user://save")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".save"):
			var button = Button.new()
			button.text = file_name
			button.custom_minimum_size = Vector2(0, 40)  # 每个按钮高度
			button.pressed.connect(func():
				_on_save_selected("user://save/" + file_name)
			)
			save_list.add_child(button)
		file_name = dir.get_next()
	dir.list_dir_end()

func _on_save_selected(path: String):
	print("🗂️ 读取存档: ", path)
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("❌ 无法打开存档: " + path)
		return

	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		push_error("⚠️ 存档格式错误: " + path)
		return

	await SaveMgr.restore_game(data)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back_pressed()

func _on_back_pressed():
	queue_free()
