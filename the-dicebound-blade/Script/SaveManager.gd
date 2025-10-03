extends Node

# 存档路径 (注意：用 user://，不要用 res://)
var save_path := "user://slot_%d.save"

# 保存游戏
func save_game(slot: int, data: Dictionary) -> void:
	var path := save_path % slot
	var abs_path := ProjectSettings.globalize_path(path)
	print("💾 保存存档: ", abs_path)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

# 读取游戏
func load_game(slot: int) -> Dictionary:
	var path := save_path % slot
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var content := file.get_as_text()
	file.close()

	var result: Variant = JSON.parse_string(content)
	return result if typeof(result) == TYPE_DICTIONARY else {}

# 删除单个存档
func clear_game(slot: int) -> void:
	var path := save_path % slot
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(abs_path)
		print("🗑️ 删除存档: ", abs_path, " -> 错误码: ", err)

# 删除所有存档
func clear_all() -> void:
	var i := 0
	while true:
		var path := save_path % i
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(path):
			var err := DirAccess.remove_absolute(abs_path)
			print("🗑️ 删除存档: ", abs_path, " -> 错误码: ", err)
			i += 1
		else:
			break
