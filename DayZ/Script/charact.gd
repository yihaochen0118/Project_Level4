extends Node2D

var characters := {}
# 角色预设位置

func spawn_character(name: String, pos: Vector2 = Vector2.ZERO):
	var path = ResMgr.get_character(name)
	if path == "":
		push_error("ResMgr 中没有角色: %s" % name)
		return null

	var scene = load(path) as PackedScene
	var char_node = scene.instantiate()

	add_child(char_node)
	char_node.position = pos
	char_node.name = name
	char_node.add_to_group("characters")

	characters[name] = char_node
	return char_node

func remove_character(name: String):
	if characters.has(name):
		var node = characters[name]
		if is_instance_valid(node):
			node.queue_free()
		characters.erase(name)

func get_character(name: String) -> Node:
	return characters.get(name, null)

# 🔥 所有动作写在这里
func play_action(name: String, action: String, args: Array = []):
	match action:
		"spawn_character":
			# args[0] = 出场位置 (Vector2)，默认 (0, 0)
			var pos = args[0] if args.size() > 0 else Vector2(0, 0)
			spawn_character(name, pos)

		"shake":
			shake(name)

		"move_in_left":
			# args[0] = 目标位置 (Vector2)，args[1] = 时间，默认 (0, 0), 0.5
			var pos = args[0] if args.size() > 0 else Vector2(0, 0)
			var duration = args[1] if args.size() > 1 else 0.5
			move_in_from_left(name, pos, duration)

		"remove_character":
			remove_character(name)
		_:
			push_warning("未知动作: %s" % action)



func move_in_from_left(name: String, target_pos: Vector2, duration := 0.5):
	var char_node = get_character(name)
	if not char_node:
		return
	var tween = create_tween()
	char_node.modulate.a = 0.0
	char_node.position = Vector2(-200, target_pos.y)
	tween.tween_property(char_node, "modulate:a", 1.0, duration)
	tween.parallel().tween_property(char_node, "position", target_pos, duration)

func shake(name: String):
	var char_node = get_character(name)
	if not char_node:
		return
	var tween = create_tween()
	var x = char_node.position.x
	tween.tween_property(char_node, "position:x", x + 10, 0.05)
	tween.tween_property(char_node, "position:x", x - 10, 0.1)
	tween.tween_property(char_node, "position:x", x, 0.05)
