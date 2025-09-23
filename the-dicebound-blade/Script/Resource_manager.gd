extends Node
class_name ResourceManager

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

# 对话脚本路径
var dialogues = {
	"scene1.0": "res://TextScript/scene1.0.json",
	"scene1.0.1": "res://TextScript/scene1.0.1.json",
	"scene1.0.2": "res://TextScript/scene1.0.2.json",
	"scene1.0.3": "res://TextScript/scene1.0.3.json",
	"scene1.1": "res://TextScript/scene1.1.json"
}

# 获取背景
func get_background(name: String) -> String:
	return backgrounds.get(name, "")

# 获取角色
func get_character(name: String) -> String:
	return characters.get(name, "")

func get_ui(name: String) -> String:
	return ui.get(name, "")

# 获取对话脚本
func get_dialogue(name: String) -> String:
	return dialogues.get(name, "")
