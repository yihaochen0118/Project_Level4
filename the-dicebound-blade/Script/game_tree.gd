extends Control
# GameTree.gd —— 手动摆点 + 解锁灰/亮 + 悬停提示 + 滚动定位

@export var marks_path: NodePath = ^"Marks"          # 你放点的父节点
@export var unlocked_modulate: Color = Color(1,1,1,1) # 原色
@export var locked_modulate: Color   = Color(0.6,0.6,0.6,0.55) # 变灰
@export var hover_offset: Vector2 = Vector2(16, 16)   # 提示相对鼠标偏移
@export var auto_refresh_on_player_change := true     # 监听 PlayerData 的变化自动刷新

@onready var marks: Control = get_node(marks_path)

var hint_popup: PopupPanel
var hint_label: RichTextLabel
var hint_image: TextureRect        # ← 新增

func _ready() -> void:
	_make_popup()
	_connect_mark_events()
	refresh()

	# （可选）当 PlayerData 发出变化时自动刷新
	if auto_refresh_on_player_change and PlayerData.has_signal("stats_changed"):
		PlayerData.stats_changed.connect(refresh)

# -------------------------------------------------------------------
# 对外：刷新所有点的灰/亮，并重新绑定悬停提示
# -------------------------------------------------------------------
func refresh() -> void:
	if not is_instance_valid(marks):
		return
	for c in marks.get_children():
		if c is Control:
			# 解绑旧信号，避免重复
			if c.is_connected("mouse_entered", Callable(self, "_on_hover_enter")):
				c.disconnect("mouse_entered", Callable(self, "_on_hover_enter"))
			if c.is_connected("mouse_exited", Callable(self, "_on_hover_exit")):
				c.disconnect("mouse_exited", Callable(self, "_on_hover_exit"))

			# 设置灰/亮
			var unlocked := _is_unlocked_for(c)
			c.modulate = unlocked_modulate if unlocked else locked_modulate

			# 绑定悬停
			c.mouse_entered.connect(_on_hover_enter.bind(c))
			c.mouse_exited.connect(_on_hover_exit)

# （可选）滚动到某个节点（node meta 或节点名）
func focus_to(id: String, center := true) -> void:
	var target_ctrl := _find_mark_by_id(id)
	if not target_ctrl:
		return
	var view := _find_scroll_container()
	if not view:
		return
	# 计算目标在本节点坐标系的位置（本脚本挂在内容容器上）
	var p := target_ctrl.global_position - global_position
	var view_size := view.get_viewport_rect().size
	var focus_pos := Vector2(p.x, p.y)
	if center:
		focus_pos -= view_size * 0.5
	# 只滚动纵向
	view.scroll_vertical = int(max(0.0, focus_pos.y))

# -------------------------------------------------------------------
# 内部：判断是否解锁（永久进度）
# -------------------------------------------------------------------
func _is_unlocked_for(ctrl: Control) -> bool:
	var id := ""
	if ctrl.has_meta("node"):
		id = String(ctrl.get_meta("node"))
	else:
		id = String(ctrl.name)

	# 允许手动强制
	if ctrl.has_meta("unlocked"):
		return bool(ctrl.get_meta("unlocked"))
	# 走永久解锁进度
	if PlayerData.has_method("is_node_unlocked"):
		return PlayerData.is_node_unlocked(id)
	return false

# -------------------------------------------------------------------
# 悬停弹窗
# -------------------------------------------------------------------
func _make_popup() -> void:
	hint_popup = PopupPanel.new()
	hint_popup.name = "HintPopup"
	hint_popup.visible = false
	hint_popup.transient = true  # 点击别处自动隐藏
	add_child(hint_popup)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(260, 0)
	vb.add_theme_constant_override("separation", 6)
	hint_popup.add_child(vb)

	# 文本
	hint_label = RichTextLabel.new()
	hint_label.bbcode_enabled = true
	hint_label.fit_content = true
	hint_label.scroll_active = false
	vb.add_child(hint_label)
		# === 新增：图片区域 ===
	hint_image = TextureRect.new()
	hint_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hint_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hint_image.custom_minimum_size = Vector2(1, 1)
	hint_image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hint_image.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	hint_image.visible = false
	vb.add_child(hint_image)


func _on_hover_enter(ctrl: Control) -> void:
	# 1) 节点ID
	var id := ""
	if ctrl.has_meta("node"):
		id = String(ctrl.get_meta("node"))
	else:
		id = String(ctrl.name)

	# 2) 解锁状态
	var unlocked := _is_unlocked_for(ctrl)

	# 3) 按状态取提示文本
	var hint := ""
	if unlocked:
		if ctrl.has_meta("hint_unlocked"):
			hint = tr(String(ctrl.get_meta("hint_unlocked")))
		else:
			hint = tr("已解锁：暂无额外说明")
	else:
		if ctrl.has_meta("hint_locked"):
			hint = tr(String(ctrl.get_meta("hint_locked")))
		else:
			hint = tr("未解锁：暂无解锁条件说明")

	# 4) 头部文字
	var head := ""
	if unlocked:
		head = "[color=gold]" + tr("Unlocked") + "[/color]\n"
	else:
		head = "[color=gray]" + tr("Locked") + "[/color]\n"

	# 5) 更新文本内容
	hint_label.bbcode_enabled = true
	hint_label.text = head + hint

	# 6) 加载可选图片
	var tex: Texture2D = null
	if ctrl.has_meta("hint_image"):
		var v = ctrl.get_meta("hint_image")
		if v is Texture2D:
			tex = v
		elif v is String:
			var path := String(v)
			if path != "" and ResourceLoader.exists(path):
				tex = load(path) as Texture2D

	if tex != null:
		hint_image.texture = tex
		hint_image.visible = true
		var target_size := Vector2(196, 108)  # 默认小图标
		if ctrl.has_meta("hint_image_size"):
			var sz = ctrl.get_meta("hint_image_size")
			if sz is Vector2:
				target_size = sz
		hint_image.custom_minimum_size = target_size
	else:
		hint_image.texture = null
		hint_image.visible = false

	# 7) 弹出提示
	var gp := get_viewport().get_mouse_position() + hover_offset
	hint_popup.set_position(gp)
	hint_popup.popup()



func _on_hover_exit() -> void:
	if hint_popup:
		hint_popup.hide()

# -------------------------------------------------------------------
# 初次绑定（方便你在编辑器里新增节点后运行即可）
# -------------------------------------------------------------------
func _connect_mark_events() -> void:
	if not is_instance_valid(marks):
		return
	for c in marks.get_children():
		if c is Control:
			if not c.is_connected("mouse_entered", Callable(self, "_on_hover_enter")):
				c.mouse_entered.connect(_on_hover_enter.bind(c))
			if not c.is_connected("mouse_exited", Callable(self, "_on_hover_exit")):
				c.mouse_exited.connect(_on_hover_exit)

# -------------------------------------------------------------------
# 工具函数
# -------------------------------------------------------------------
func _find_mark_by_id(id: String) -> Control:
	for c in marks.get_children():
		if c is Control:
			var nid := ""
			if c.has_meta("node"):
				nid = String(c.get_meta("node"))
			else:
				nid = String(c.name)
			if nid == id:
				return c
	return null

func _find_scroll_container() -> ScrollContainer:
	# 向上找第一个 ScrollContainer
	var p: Node = self
	while p:
		if p is ScrollContainer:
			return p
		p = p.get_parent()
	return null
