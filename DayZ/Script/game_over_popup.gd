extends Control

@onready var label = $Panel/GameOverLabel
@onready var button = $Panel/BackToMenuButton

func _ready():
	button.pressed.connect(_on_back_pressed)

func show_game_over(text: String):
	label.text = text
	show()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/start.tscn")
