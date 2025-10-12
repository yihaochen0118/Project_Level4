extends Control

signal dice_chosen(sides: int, result: int)

var check:String =""
@onready var btn_d6: Button = $card/DICE/D6
@onready var btn_d8: Button = $card/DICE/D8
@onready var btn_d10: Button = $card/DICE/D10
@onready var btn_d12: Button = $card/DICE/D12
@onready var btn_d20: Button = $card/DICE/D20
@onready var Dc_value: Label = $rightPanel/DC
@onready var result_label: Label = $card/ResultLabel
@onready var card_container: Control = $card/DICE   # 按钮所在的容器


func _ready():
	if btn_d6: btn_d6.pressed.connect(func(): _try_roll(6))
	if btn_d8: btn_d8.pressed.connect(func(): _try_roll(8))
	if btn_d10: btn_d10.pressed.connect(func(): _try_roll(10))
	if btn_d12: btn_d12.pressed.connect(func(): _try_roll(12))
	if btn_d20: btn_d20.pressed.connect(func(): _try_roll(20))
	_update_dice_buttons()

func _try_roll(sides: int):
	if PlayerData.dice_uses.get(sides, 0) <= 0:
		print("⚠️ D%d 已无可用次数" % sides)
		return

	_roll_dice(sides)
	PlayerData.dice_uses[sides] -= 1
	PlayerData.dice_max_uses[sides] = max(PlayerData.dice_max_uses[sides] - 1, 0)
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
		btn.modulate = Color(1,1,1) if remaining > 0 else Color(0.5,0.5,0.5,0.7)
		
func _roll_dice(sides: int):
	var result = randi_range(1, sides)
	card_container.hide()

	# 显示结果（用自身保存的 check）
	_result_feedback(sides, result, check)

	emit_signal("dice_chosen", sides, result)

	await get_tree().create_timer(3.0).timeout
	
	result_label.hide()
	queue_free()

func _result_feedback(sides: int, result: int, check: String = ""):
	var modifier = 0
	if check != "":
		modifier = PlayerData.get_stat(check)

	var total = result + modifier

	# 拼接提示文本
	if check != "":
		result_label.text = "You rolled %d (D%d) + %d (%s modifier) = %d" % [
			result, sides, modifier, check, total
		]
	else:
		result_label.text = "You rolled %d (D%d)" % [result, sides]

	result_label.show()

	
func _fix_rightPanel(value:int):
	Dc_value.text="%d"% value

func _get_btn_by_sides(sides: int) -> Button:
	match sides:
		6: return btn_d6
		8: return btn_d8
		10: return btn_d10
		12: return btn_d12
		20: return btn_d20
		_: return null
