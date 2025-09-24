extends Control

signal dice_chosen(sides: int, result: int)

@onready var btn_d6: Button = $card/DICE/D6
@onready var btn_d8: Button = $card/DICE/D8
@onready var btn_d10: Button = $card/DICE/D10
@onready var btn_d12: Button = $card/DICE/D12
@onready var btn_d20: Button = $card/DICE/D20
@onready var result_label: Label = $card/ResultLabel
@onready var card_container: Control = $card/DICE   # 按钮所在的容器

func _ready():
	if btn_d6: btn_d6.pressed.connect(func(): _roll_dice(6))
	if btn_d8: btn_d8.pressed.connect(func(): _roll_dice(8))
	if btn_d10: btn_d10.pressed.connect(func(): _roll_dice(10))
	if btn_d12: btn_d12.pressed.connect(func(): _roll_dice(12))
	if btn_d20: btn_d20.pressed.connect(func(): _roll_dice(20))

func _roll_dice(sides: int):
	var result = randi_range(1, sides)

	# 立即隐藏卡牌按钮
	card_container.hide()

	# 显示结果
	_result_feedback(sides,result)

	# 发信号（告诉外部结果）
	emit_signal("dice_chosen", sides, result)

	# 两秒后隐藏结果并移除整个节点
	await get_tree().create_timer(2.0).timeout
	result_label.hide()
	queue_free()
	
func _result_feedback(sides:int,result:int):
	result_label.text = "你投出了 %d (D%d)" % [result, sides]
	result_label.show()
