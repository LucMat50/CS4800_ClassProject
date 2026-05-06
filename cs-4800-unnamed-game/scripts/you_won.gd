extends Control

# ONREADY VARIABLES
@onready var score = $VBoxContainer/Score
@onready var accuracy = $VBoxContainer/Accuracy

func _ready() -> void:
	score.text = "Final Score: %d" % GameManager.score
	accuracy.text = "Overall Accuracy: %.2f%%" % GameManager.accuracy

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
