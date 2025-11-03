# PlayerData.gd （Autoload 单例，全局角色数据）
extends Node

signal stats_changed
signal hp_changed(new_hp: int, max_hp: int)

var choice_history: Array = []
var flags: Dictionary = {}
var dice_max_uses = {6:5, 8:4, 10:3, 12:2, 20:1}
var dice_uses = dice_max_uses.duplicate(true)
var unlocked_nodes: Dictionary = {}   # {"1.3": true, "BadEnding1": true, ...}

var hp: int = 100
var max_hp: int = 100

func _ready():
	load_progress()   # 启动时读取一次永久进度（不受存档影响）
	
# 六大能力值（基于 D&D 风格）
var stats = {
	"strength": 2,      # 力量（Strength）：近战、威慑、体能对抗
	"dexterity": 4,     # 敏捷（Dexterity）：潜行、闪避、远程攻击
	"constitution": 3,  # 体质（Constitution）：耐力、生命力、抵抗力
	"intelligence": 5,  # 智力（Intelligence）：分析、调查、知识
	"wisdom": 2,        # 感知（Wisdom）：察觉、洞察、判断
	"charisma": 3       # 魅力（Charisma）：交涉、表演、说服
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

func reset_dice_uses():
	dice_uses = dice_max_uses.duplicate(true)
	print("🎲 已重置骰子使用次数:", dice_uses)
# --------------------
# 存档加载（支持部分覆盖）
# --------------------
func load_from_dict(data: Dictionary):
	hp = data.get("hp", 100)
	max_hp = max(hp, max_hp)
	stats = data.get("stats", stats)
	choice_history = data.get("choices", [])
	flags = data.get("flags", {})

	# 🎲 新增：加载骰子次数
	if data.has("dice_uses"):
		dice_uses.clear()
		for k in data["dice_uses"].keys():
			dice_uses[int(k)] = data["dice_uses"][k]

	if data.has("dice_max_uses"):
		dice_max_uses.clear()
		for k in data["dice_max_uses"].keys():
			dice_max_uses[int(k)] = data["dice_max_uses"][k]

	emit_signal("stats_changed")
	emit_signal("hp_changed", hp, max_hp)

func reset_all():
	reset_dice_uses()
	hp = max_hp
	flags.clear()
	choice_history.clear()
	print("🔄 已完全重置玩家数据")

# ✅ 设置 flag 值
func set_flag(flag_name: String, value: bool = true):
	flags[flag_name] = value
	print("🏳️ 设置Flag：%s = %s" % [flag_name, str(value)])

# ✅ 读取 flag 值（默认为 false）
func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

# ✅ 清除一个 flag（例如剧情重置时）
func clear_flag(flag_name: String):
	if flags.has(flag_name):
		flags.erase(flag_name)
		print("🧹 已清除Flag：%s" % flag_name)

func add_dice_uses(sides: int, amount: int = 1):
	if not dice_uses.has(sides):
		push_warning("⚠️ 未知的骰子类型: D%d" % sides)
		return
	
	dice_uses[sides] += amount
	print("🎲 D%d 使用次数增加 %d → 当前次数: %d" % [sides, amount, dice_uses[sides]])

	emit_signal("stats_changed")  # 如果你有UI更新监听
# 供外部调用：解锁 / 查询
func unlock_node(id: String) -> void:
	if id == "": return
	unlocked_nodes[id] = true
	_save_progress()
	emit_signal("stats_changed")  # 让UI有机会刷新（可选）

func is_node_unlocked(id: String) -> bool:
	return unlocked_nodes.get(id, false)

# 永久保存到 user://progress.cfg
func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_nodes", unlocked_nodes.keys())
	cfg.save("user://progress.cfg")

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://progress.cfg") == OK:
		var arr: Array = cfg.get_value("progress", "unlocked_nodes", [])
		unlocked_nodes.clear()
		for id in arr:
			unlocked_nodes[str(id)] = true

# （可选）单独提供清理永久进度的API，reset_all不要动它
func clear_progress() -> void:
	unlocked_nodes.clear()
	_save_progress()
