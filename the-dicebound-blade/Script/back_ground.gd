extends Node2D

var current_bg: Node = null  # 当前加载的背景

func set_background(bg_name: String):
	# 先卸载旧背景
	if current_bg:
		current_bg.queue_free()
		current_bg = null

	# 通过资源管理器获取路径
	var path = ResMgr.get_background(bg_name)  # 如果你把 resource_manager.gd 加到 AutoLoad，名字叫 ResMgr
	if path != "":
		var scene = load(path) as PackedScene
		current_bg = scene.instantiate()
		add_child(current_bg)
	else:
		push_warning("背景场景不存在: %s" % bg_name)
