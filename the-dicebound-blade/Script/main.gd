extends Node

@onready var backGround = $backGround
@onready var UI = $UI
@onready var charact = $Charact

func _ready():
	# 游戏开始，加载 tavern 背景，第一幕对话
	UI.connect("dialogue_event", Callable(self, "_on_dialogue_event"))
	load_scene("tavern", "scene1.0")
	init_player_info()
	

func load_scene(bg_name: String, dialogue_name: String):
	# 1. 设置背景
	var bg_scene = ResMgr.get_background(bg_name)
	if bg_scene:
		backGround.set_background(bg_name)

	# 2. 设置对话
	var dialogue_path = ResMgr.get_dialogue(dialogue_name)
	if dialogue_path:
		UI.load_dialogues(dialogue_path)
		UI.show_next_line()

func _on_dialogue_event(event_data: Dictionary):
	# 交给 charact.gd 或其他管理器处理
	if event_data.has("action") and event_data.has("target"):
		charact.play_action(event_data["target"], event_data["action"], event_data.get("args", []))

# 全局输入监听
func _input(event):
	# 鼠标左键
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		UI.handle_input()

	# 空格键
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		UI.handle_input()

func init_player_info():
	if not UI.has_node("PlayerStatu"):
		var path = ResMgr.get_ui("PlayerStatu")
		if path != "":
			var scene = load(path) as PackedScene
			var ps = scene.instantiate()
			ps.name = "PlayerStatu"
			UI.add_child(ps)

			# 刷新一次属性显示
			if ps.has_method("update_stats"):
				ps.update_stats()
