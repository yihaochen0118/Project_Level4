extends "res://Scenes/item/ItemBase.gd"

func _ready():
	item_name = "LuckyCoin20"
	item_type = "equipment"
	description = "The lucky coin left behind by the drunkard appears to be a gambler's way of ensuring good luck."
	effect = {"dice": {"sides": 20, "amount": 2}}
	icon = preload("res://images/else/LuckyCoin.png") 
	
