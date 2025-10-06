extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var load_button = $VBoxContainer/LoadButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	load_button.pressed.connect(_on_load_pressed)

func _on_start_pressed():
	print("🎮 开始游戏！")
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_load_pressed():
	print("📂 打开读取存档界面")

	# ✅ 通过 ResourceManager 加载（推荐方式）
	var path = ResMgr.get_ui("loadUi")
	if path == "":
		push_error("⚠️ 未在 ResMgr 中登记 load_ui 路径")
		return

	var scene = load(path) as PackedScene
	if scene == null:
		push_error("⚠️ 加载 load_ui.tscn 失败")
		return

	# ✅ 实例化并添加到当前场景树
	var load_ui = scene.instantiate()
	add_child(load_ui)
