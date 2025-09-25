# PlayerData.gd (单例，挂在 Autoload 里)
extends Node
signal stats_changed

var stats = {
	"strength": 2,   # 力量 +2
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
