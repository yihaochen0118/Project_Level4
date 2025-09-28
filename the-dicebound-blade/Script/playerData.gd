# PlayerData.gd (单例，挂在 Autoload 里)
extends Node
signal stats_changed
signal hp_changed(new_hp: int, max_hp: int)

var hp: int = 100
var max_hp: int = 100

var stats = {
	"strength": 5,   # 力量 +5
	"dexterity": 2,  # 敏捷 +1
	"constitution": 4, # 体质 +3
	"charisma": 6 #魅力 6
}


func set_stat(stat: String, value: int):
	stats[stat] = value
	emit_signal("stats_changed")

func add_stat(stat: String, amount: int):
	stats[stat] += amount
	emit_signal("stats_changed")

func get_stat(stat: String) -> int:
	return stats.get(stat, 0)
	
func change_hp(amount: int):
	hp = clamp(hp + amount, 0, max_hp)
	print("当前 HP: %d / %d" % [hp, max_hp])
	emit_signal("hp_changed", hp, max_hp)
