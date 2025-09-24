extends Node
class_name ResourceManager
var dialogues = {}

func _ready():
	autoLoad_Dialogue()

# 背景场景路径
var backgrounds = {
	"tavern": "res://Scenes/Background/tavern.tscn",
	"battle": "res://Scenes/Background/battle.tscn"
}

# 角色场景路径
var characters = {
	"Aldric": "res://Scenes/Characters/Aldric.tscn",
	"Man": "res://Scenes/Characters/Man.tscn",
}

var ui = {
	"Dice_CardChoose": "res://Scenes/ui/Dice_CardChoose.tscn",
	"talk_ui": "res://Scenes/ui/talk_ui.tscn",
	"Option_ui":"res://Scenes/ui/OptionUI.tscn",
}

func autoLoad_Dialogue():
	var dir = DirAccess.open("res://TextScript")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var scene_key = file_name.replace(".json", "")
				dialogues[scene_key] = "res://TextScript/%s" % file_name
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
