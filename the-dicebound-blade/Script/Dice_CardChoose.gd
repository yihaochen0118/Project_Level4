extends Control

signal dice_chosen(sides: int, result: int)

var check: String = ""
@onready var btn_d6: Button = $card/DICE/D6
@onready var btn_d8: Button = $card/DICE/D8
@onready var btn_d10: Button = $card/DICE/D10
@onready var btn_d12: Button = $card/DICE/D12
@onready var btn_d20: Button = $card/DICE/D20
@onready var Dc_value: Label = $rightPanel/DC
@onready var result_label: Label = $card/ResultLabel
@onready var modification_label = $Modification
@onready var card_container: Control = $card/DICE   # 按钮所在容器
@onready var dim_overlay: ColorRect = $DimOverlay
var original_z_index = {}
var original_position = {}

var dice_sounds = [
	preload("res://images/Sound/dice1.wav"),
	preload("res://images/Sound/dice2.wav"),
	preload("res://images/Sound/dice3.wav")
]
# ==============================
# 🚀 初始化
# ==============================
func _ready():
	# ✅ 不再调用 _stack_dice_cards()，保持手动布局
	_connect_all_buttons()
	_update_dice_buttons()
	# 记录初始 z_index（你在编辑器里设置好的顺序）
	for btn in [btn_d6, btn_d8, btn_d10, btn_d12, btn_d20]:
			if btn:
				original_z_index[btn] = btn.z_index
				original_position[btn] = btn.position
		# 背景淡入
	randomize()
	_fade_dim(true)

# ==============================
# 🎨 动效部分
# ==============================
func _connect_all_buttons():
	_connect_dice_button(btn_d6, 6)
	_connect_dice_button(btn_d8, 8)
	_connect_dice_button(btn_d10, 10)
	_connect_dice_button(btn_d12, 12)
	_connect_dice_button(btn_d20, 20)

func _connect_dice_button(btn: Button, sides: int):
	if not btn:
		return
	btn.pressed.connect(func(): _try_roll(sides))
	btn.mouse_entered.connect(func(): _on_hover(btn))
	btn.mouse_exited.connect(func(): _on_exit(btn))
	btn.button_down.connect(func(): _on_pressed(btn))
	btn.button_up.connect(func(): _on_released(btn))

func _on_hover(btn: Button):
	if btn.disabled: return
	btn.z_index = 999
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15)
	tween.parallel().tween_property(btn, "modulate", Color(1.3, 1.3, 1.3), 0.15)
	# 🔹 上浮效果
	tween.parallel().tween_property(btn, "position", original_position[btn] + Vector2(0, -20), 0.15)

func _on_exit(btn: Button):
	btn.z_index = original_z_index.get(btn, 0)
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1, 1), 0.15)
	tween.parallel().tween_property(btn, "modulate", Color(1, 1, 1), 0.15)
	# 🔹 复原位置（不叠加）
	tween.parallel().tween_property(btn, "position", original_position[btn], 0.15)



func _on_pressed(btn: Button):
	if btn.disabled: return
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)

func _on_released(btn: Button):
	if btn.disabled:
		return
	
	var tween = create_tween()
	
	# 随机选择一个声音
	var random_sound = dice_sounds[randi() % dice_sounds.size()]
	SdMgr.play_sfx(random_sound)
	
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)


# ==============================
# 🎲 骰子逻辑
# ==============================
func _try_roll(sides: int):
	if PlayerData.dice_uses.get(sides, 0) <= 0:
		print("⚠️ D%d 已无可用次数" % sides)
		return

	_roll_dice(sides)
	PlayerData.dice_uses[sides] -= 1
	_update_dice_buttons()


func _update_dice_buttons():
	for sides in PlayerData.dice_uses.keys():
		var btn = _get_btn_by_sides(sides)
		if not btn:
			continue
		var remaining = PlayerData.dice_uses[sides]
		if btn.has_node("CountLabel"):
			btn.get_node("CountLabel").text = "x%d" % remaining
		btn.disabled = remaining <= 0
		btn.modulate = Color(1,1,1) if remaining > 0 else Color(0.5,0.5,0.5,0.6)


func _roll_dice(sides: int):
	var result = randi_range(1, sides)

	# 🎞️ 投掷时跳动动画
	var btn = _get_btn_by_sides(sides)
	if btn:
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.25)

	card_container.hide()

	_result_feedback(sides, result, check)
	emit_signal("dice_chosen", sides, result)

	await get_tree().create_timer(3.0).timeout
	result_label.hide()
	queue_free()


# ==============================
# 🧠 文本反馈
# ==============================
func _result_feedback(sides: int, result: int, check: String = ""):
	var modifier = 0
	if check != "":
		modifier = PlayerData.get_stat(check)
	var total = result + modifier

	if check != "":
		result_label.text = "You rolled %d (D%d) + %d (%s modifier) = %d" % [
			result, sides, modifier, check, total
		]
	else:
		result_label.text = "You rolled %d (D%d)" % [result, sides]

	result_label.show()


func _fix_rightPanel(value: int):
	Dc_value.text = "%d" % value
	_update_modification_label()



func _get_btn_by_sides(sides: int) -> Button:
	match sides:
		6: return btn_d6
		8: return btn_d8
		10: return btn_d10
		12: return btn_d12
		20: return btn_d20
		_: return null
		
func _fade_dim(to_visible: bool):
	if not dim_overlay:
		return
	var tween = create_tween()
	var target_alpha = 0.6 if to_visible else 0.0
	dim_overlay.visible = true
	tween.tween_property(dim_overlay, "color:a", target_alpha, 0.3)
	if not to_visible:
		await tween.finished
		dim_overlay.visible = false
		
func _update_modification_label():
	if check == "" or not PlayerData.stats.has(check):
		modification_label.text = "无属性修正"
	else:
		var value = PlayerData.get_stat(check)
		var sign = "+" if value >= 0 else ""
		modification_label.text = "%s %+d" % [check.capitalize(), value]
