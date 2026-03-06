# PlayerData.gd （Autoload 单例，全局角色数据）
extends Node
const DEFAULT_DICE_MAX_USES := {6:6, 8:3, 10:1, 12:0, 20:0}
signal stats_changed
signal hp_changed(new_hp: int, max_hp: int)
signal item_changed
signal chapter_changed(chapter: String)

var inventory: Dictionary = {}  # {"Sword": 1, "Potion": 3}
var choice_history: Array = []
var flags: Dictionary = {}
var dice_max_uses: Dictionary = DEFAULT_DICE_MAX_USES.duplicate(true)
var dice_uses: Dictionary = DEFAULT_DICE_MAX_USES.duplicate(true)
var unlocked_nodes: Dictionary = {}   # {"1.3": true, "BadEnding1": true, ...}
var chapter: String = "1"

var hp: int = 100
var max_hp: int = 100

func _ready():
	load_progress()   # 启动时读取一次永久进度（不受存档影响）
	
# 六大能力值（基于 D&D 风格）
var stats = {
	"strength": 2,      # 力量（Strength）：近战、威慑、体能对抗
	"constitution": 3,  # 体质（Constitution）：耐力、生命力、抵抗力
	"intelligence": 5,  # 智力（Intelligence）：分析、调查、知识
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
	print(stat)
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

	# 💀 HP归零 → Game Over
	if hp <= 0:
		EventMgr.handle_event({
			"action": "game_over",
			"message": "GAME OVER \nYou collapsed due to the severity of your injuries.。"
		})

func reset_dice_uses():
	dice_uses = DEFAULT_DICE_MAX_USES.duplicate(true)
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
	set_chapter(str(data.get("chapter_num", chapter)))
	# 🎲 新增：加载骰子次数
	if data.has("dice_uses"):
		dice_uses.clear()
		for k in data["dice_uses"].keys():
			dice_uses[int(k)] = data["dice_uses"][k]

	if data.has("dice_max_uses"):
		dice_max_uses.clear()
		for k in data["dice_max_uses"].keys():
			dice_max_uses[int(k)] = data["dice_max_uses"][k]
	
	if data.has("inventory"):
		inventory = data["inventory"].duplicate(true)
		emit_signal("item_changed")

	emit_signal("stats_changed")
	emit_signal("hp_changed", hp, max_hp)

func reset_all():
	reset_dice_uses()
	hp = max_hp
	flags.clear()
	choice_history.clear()
	emit_signal("chapter_changed", "1")

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

func add_item(item_name: String, count: int = 1):
	if inventory.has(item_name):
		inventory[item_name] += count
	else:
		inventory[item_name] = count

	emit_signal("item_changed")
	print("👜 获得物品: %s x%d" % [item_name, count])

# 使用物品
func use_item(item_name: String):
	if not inventory.has(item_name):
		push_warning("⚠️ 没有此物品: %s" % item_name)
		return
	inventory[item_name] -= 1
	if inventory[item_name] <= 0:
		inventory.erase(item_name)
	emit_signal("item_changed")

	# 实例化并执行
	var path = ResMgr.items.get(item_name, "")
	if path == "":
		push_error("❌ 未找到物品资源: %s" % item_name)
		return

	var scene = load(path)
	var item_instance = scene.instantiate()

	# ⚙️ 手动触发 ready 初始化（防止没有 add_child）
	if item_instance.has_method("_ready"):
		item_instance._ready()

	# 执行物品效果
	if item_instance.has_method("use"):
		item_instance.use()

func reset_all_data():
	print("🧹 重置所有玩家数据（新游戏）")

	hp = 100
	max_hp = 100
	stats = {"strength":2,"constitution":3,"intelligence":5,"charisma":3}
	flags.clear()
	choice_history.clear()
	inventory.clear()

	# ❌ 永久解锁不要清
	# unlocked_nodes.clear()

	# ✅ 可选：确保从磁盘再读一遍永久进度（防止内存被别处动过）
	load_progress()

	dice_uses = dice_max_uses.duplicate(true)

	emit_signal("stats_changed")
	emit_signal("hp_changed", hp, max_hp)
	emit_signal("item_changed")
	print("✅ 所有数据已恢复默认状态（永久解锁保留）")

	
func set_chapter(new_chapter: String) -> void:
	if chapter != new_chapter:
		chapter = new_chapter
		print("📘 当前章节更新为: Chapter ", chapter)
		emit_signal("chapter_changed", chapter)
		
