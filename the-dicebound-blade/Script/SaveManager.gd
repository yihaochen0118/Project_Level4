extends Node

# 存档路径（统一放入 save 文件夹）
var save_path := "user://save/slot_%d.save"

# ================= 保存游戏 =================
func save_game(slot: int, data: Dictionary) -> void:
	# ✅ 确保存档文件夹存在
	if not DirAccess.dir_exists_absolute("user://save"):
		DirAccess.make_dir_absolute("user://save")

	var path := save_path % slot
	var abs_path := ProjectSettings.globalize_path(path)
	print("💾 保存存档: ", abs_path)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
	else:
		push_error("❌ 无法打开存档文件: " + path)


# ================= 读取游戏 =================
func load_game(slot: int) -> Dictionary:
	var path := save_path % slot
	if not FileAccess.file_exists(path):
		print("⚠️ 存档不存在: ", path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("❌ 无法打开存档文件: " + path)
		return {}

	var content := file.get_as_text()
	file.close()

	var result: Variant = JSON.parse_string(content)
	return result if typeof(result) == TYPE_DICTIONARY else {}


# ================= 删除单个存档 =================
func clear_game(slot: int) -> void:
	var path := save_path % slot
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(abs_path)
		print("🗑️ 删除存档: ", abs_path, " -> 错误码: ", err)
	else:
		print("⚠️ 要删除的存档不存在: ", abs_path)


# ================= 删除所有存档 =================
func clear_all() -> void:
	var dir := DirAccess.open("user://save")
	if dir == null:
		print("⚠️ 存档目录不存在，无需清空")
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".save"):
			var abs_path := ProjectSettings.globalize_path("user://save/" + file_name)
			var err := DirAccess.remove_absolute(abs_path)
			print("🧹 删除存档: ", abs_path, " -> 错误码: ", err)
		file_name = dir.get_next()
	dir.list_dir_end()


# ================= ✅ 核心功能：恢复游戏（含状态回放） =================
func restore_game(data: Dictionary) -> void:
	if data.size() == 0:
		push_warning("⚠️ 空存档，无法恢复")
		return

	# 1️⃣ 恢复玩家属性
	PlayerData.load_from_dict(data)

	# 2️⃣ 切换主场景
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
	await get_tree().create_timer(0.1).timeout  # 等待场景加载完成

	# 3️⃣ 获取当前场景根节点
	var root = get_tree().current_scene
	if not root:
		push_error("❌ 无法获取当前场景（main.tscn 可能没加载完）")
		return

	# 4️⃣ 清理旧角色立绘（以免残留）
	if root.has_node("Charact"):
		for c in root.get_node("Charact").get_children():
			c.queue_free()

	# 5️⃣ 恢复 UI 状态（章节名 + 对话索引）
	if root.has_node("UI"):
		var ui_root = root.get_node("UI")
		ui_root.current_scene_name = data.get("chapter", "")
		ui_root.dialogue_index = data.get("dialogue_index", 0)
		var start_index = data.get("dialogue_index", 0)

		# ✅ 加载章节脚本
		var dialogue_path = ResMgr.get_dialogue(ui_root.current_scene_name)
		if dialogue_path == "":
			push_error("⚠️ 找不到对话文件: " + ui_root.current_scene_name)
			return

		ui_root.load_dialogues(dialogue_path, 0)

		# ✅ 关键部分：回放事件到当前行
		ui_root.replay_state_until(start_index)

		# ✅ 恢复到当前行并显示
		ui_root.dialogue_index = start_index
		ui_root.show_next_line()

		print("✅ 对话恢复到第 %d 行（章节 %s）" % [start_index, ui_root.current_scene_name])
	else:
		push_error("⚠️ 当前场景缺少 UI 节点")
