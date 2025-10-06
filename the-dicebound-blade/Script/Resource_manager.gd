extends Node
class_name ResourceManager
var dialogues = {}
func _ready():
	autoLoad_Dialogue("res://TextScript")

# 背景场景路径
var backgrounds = {
	"tavern": "res://Scenes/Background/tavern.tscn",
	"battle": "res://Scenes/Background/battle.tscn",
	"mainPage": "res://Scenes/Background/mainPage.tscn"
}

# 角色场景路径
var characters = {
	"Alicia": "res://Scenes/Characters/Alicia.tscn",
	"Man": "res://Scenes/Characters/Man.tscn",
}

var ui = {
	"Dice_CardChoose": "res://Scenes/ui/Dice_CardChoose.tscn",
	"talk_ui": "res://Scenes/ui/talk_ui.tscn",
	"Option_ui":"res://Scenes/ui/Option_ui.tscn",
	"PlayerStatu":"res://Scenes/ui/PlayerStatu.tscn",
	"Setting":"res://Scenes/ui/Setting.tscn",
	"loadUi":"res://Scenes/ui/loadUi.tscn"
}

func autoLoad_Dialogue(base_path: String):
	var dir = DirAccess.open(base_path)
	if not dir:
		push_error("无法打开目录: %s" % base_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			# 递归进入子目录
			if file_name != "." and file_name != "..":
				autoLoad_Dialogue(base_path + "/" + file_name)
		else:
			# 只加载 .json 文件
			if file_name.ends_with(".json"):
				var scene_key = file_name.replace(".json", "")
				var full_path = base_path + "/" + file_name
				dialogues[scene_key] = full_path
				print("加载对话: %s → %s" % [scene_key, full_path])
		file_name = dir.get_next()


# 获取背景
func get_background(name: String) -> String:
	return backgrounds.get(name, "")

# 获取角色
func get_character(name: String) -> String:
	return characters.get(name, "")

func get_ui(name: String) -> String:
	return ui.get(name, "")
	
func get_dialogue(scene_name: String) -> String:
	if dialogues.has(scene_name):
		return dialogues[scene_name]
	return ""
