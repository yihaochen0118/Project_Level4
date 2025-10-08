# PlayerData.gd （Autoload 单例，全局角色数据）
extends Node

signal stats_changed
signal hp_changed(new_hp: int, max_hp: int)

var choice_history: Array = []

var hp: int = 100
var max_hp: int = 100

# 六大能力值（基于 D&D 风格）
var stats = {
	"strength": 2,      # 力量（Strength）：近战、威慑、体能对抗
	"dexterity": 2,     # 敏捷（Dexterity）：潜行、闪避、远程攻击
	"constitution": 3,  # 体质（Constitution）：耐力、生命力、抵抗力
	"intelligence": 3,  # 智力（Intelligence）：分析、调查、知识
	"wisdom": 2,        # 感知（Wisdom）：察觉、洞察、判断
	"charisma": 1       # 魅力（Charisma）：交涉、表演、说服
}

# --------------------
# 基础属性操作函数
# --------------------

func set_stat(stat: String, value: int):
	if not stats.has(stat):
		push_error("未知属性名：%s" % stat)
		return
	stats[stat] = value
	emit_signal("stats_changed")


func add_stat(stat: String, amount: int):
	if not stats.has(stat):
		push_error("未知属性名：%s" % stat)
		return
	stats[stat] += amount
	emit_signal("stats_changed")


func get_stat(stat: String) -> int:
	return stats.get(stat, 0)


# --------------------
# HP（生命值）控制
# --------------------
func change_hp(amount: int):
	hp = clamp(hp + amount, 0, max_hp)
	print("当前 HP: %d / %d" % [hp, max_hp])
	emit_signal("hp_changed", hp, max_hp)


# --------------------
# 存档加载（支持部分覆盖）
# --------------------
func load_from_dict(data: Dictionary):
	hp = data.get("hp", 100)
	max_hp = max(hp, max_hp)
	stats = data.get("stats", stats)
	choice_history = data.get("choices", [])
	emit_signal("stats_changed")
	emit_signal("hp_changed", hp, max_hp)
