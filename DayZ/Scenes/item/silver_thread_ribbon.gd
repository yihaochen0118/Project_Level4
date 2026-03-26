extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "silver_thread_ribbon"
	item_type = "equipment"
	description = "The silver hairband that Alicia left behind without her noticing. Holding it in your hand makes your heart beat slower.  charisma+2"
	effect = {"charisma": 2}
	icon = preload("res://images/else/silver_thread_ribbon.png")
