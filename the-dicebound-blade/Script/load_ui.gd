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

	var dir = DirAccess.open("user://save")
	if dir == null:
		print("⚠️ 没有找到存档目录 user://save")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".save"):
			var button = TextureButton.new()
			button.custom_minimum_size = Vector2(400, 225)  # 固定大小（16:9）
			button.stretch_mode = TextureButton.STRETCH_SCALE
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

			var slot_index = int(file_name.replace("slot_", "").replace(".save", ""))
			var data = SaveMgr.load_game(slot_index)

			# ✅ 设置截图或默认图片
			if data.has("screenshot") and FileAccess.file_exists(data["screenshot"]):
				var img = Image.new()
				img.load(data["screenshot"])
				var tex = ImageTexture.create_from_image(img)
				button.texture_normal = tex
			else:
				button.texture_normal = preload("res://icon.svg")

			# ✅ 槽编号标签（左上角）
			var slot_label = Label.new()
			slot_label.text = "存档槽 %d" % slot_index
			slot_label.add_theme_color_override("font_color", Color.WHITE)
			slot_label.add_theme_font_size_override("font_size", 20)
			slot_label.position = Vector2(10, 10)
			slot_label.add_theme_constant_override("outline_size", 3)
			slot_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			button.add_child(slot_label)

			# ✅ 时间标签（右下角）
			var time_label = Label.new()
			time_label.text = data.get("time", "未知时间")
			time_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			time_label.add_theme_font_size_override("font_size", 16)
			time_label.position = Vector2(10, 190)
			time_label.add_theme_constant_override("outline_size", 3)
			time_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			button.add_child(time_label)

			# ✅ 点击事件
			button.pressed.connect(func():
				_on_save_selected("user://save/" + file_name)
			)

			# ✅ ✨ 添加动效（从单例 UIAnimator）
			UiAnimator.apply_button_effects(button)

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
