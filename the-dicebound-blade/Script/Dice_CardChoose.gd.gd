extends Control

signal dice_chosen(sides: int, result: int)

@onready var btn_d6: Button = $card/DICE/D6
@onready var btn_d8: Button = $card/DICE/D8
@onready var btn_d10: Button = $card/DICE/D10
@onready var btn_d12: Button = $card/DICE/D12

func _ready():
	# 确保按钮存在再绑定
	if btn_d6: btn_d6.pressed.connect(func(): _roll_dice(6))
	if btn_d8: btn_d8.pressed.connect(func(): _roll_dice(8))
	if btn_d10: btn_d10.pressed.connect(func(): _roll_dice(10))
	if btn_d12: btn_d12.pressed.connect(func(): _roll_dice(12))

func _roll_dice(sides: int):
	var result = randi_range(1, sides)
	print("掷骰子 D%d = %d" % [sides, result])
	emit_signal("dice_chosen", sides, result)
	queue_free()  # 用完销毁
