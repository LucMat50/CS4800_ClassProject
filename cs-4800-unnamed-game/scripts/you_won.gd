extends Control

# ONREADY VARIABLES
@onready var score = $VBoxContainer/Score
@onready var accuracy = $VBoxContainer/Accuracy

func _ready() -> void:
	$Win.play()
	score.text = "Final Score: %d" % GameManager.score
	accuracy.text = "Overall Accuracy: %.2f%%" % GameManager.accuracy

func _on_retry_pressed() -> void:
	$ButtonChoose.play()
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _on_retry_mouse_entered() -> void:
	$ButtonSelect.play()

func _on_quit_pressed() -> void:
	$ButtonChoose.play()
	await get_tree().create_timer(1).timeout
	get_tree().quit()

func _on_quit_mouse_entered() -> void:
	$ButtonSelect.play()
