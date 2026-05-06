extends CanvasLayer

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/WaveLabel
@onready var game_over_label = $CenterContainer/VBoxContainer/GameOverLabel
@onready var summary_wave_label = $CenterContainer/VBoxContainer/SummaryWaveLabel
@onready var summary_score_label = $CenterContainer/VBoxContainer/SummaryScoreLabel
@onready var summary_accuracy_label = $CenterContainer/VBoxContainer/SummaryAccuracyLabel
@onready var restart_button = $CenterContainer/VBoxContainer/RestartButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton
@onready var colorbg = $ColorRect

func _ready() -> void:
	GameManager.hud = self
	process_mode = Node.PROCESS_MODE_ALWAYS  # important for buttons when paused

	if game_over_label != null:
		game_over_label.visible = false

	if restart_button != null:
		restart_button.visible = false
		restart_button.pressed.connect(_on_restart_pressed)

	if quit_button != null:
		quit_button.visible = false
		quit_button.pressed.connect(_on_quit_pressed)


func update_health(current_health: int, max_health: int) -> void:
	if health_label == null:
		return
	health_label.text = "Health: %d/%d" % [current_health, max_health]


func update_score(new_score: int) -> void:
	if score_label == null:
		return
	score_label.text = "Score: %d" % new_score


func update_wave(new_wave: int) -> void:
	if wave_label == null:
		return
	wave_label.text = "Wave: %d" % new_wave


func show_game_over(wave: int, score: int, accuracy: float) -> void:
	if game_over_label != null:
		game_over_label.visible = true

	summary_wave_label.visible = true
	summary_score_label.visible = true
	summary_accuracy_label.visible = true

	summary_wave_label.text = "Waves Completed: %d" % wave
	summary_score_label.text = "Final Score: %d" % score
	summary_accuracy_label.text = "Overall Accuracy: %.2f%%" % (accuracy * 100.0)

	restart_button.visible = true
	quit_button.visible = true
	colorbg.visible = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	$ButtonChoose.play()
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")  # adjust path if needed


func _on_quit_pressed() -> void:
	get_tree().paused = false
	$ButtonChoose.play()
	await get_tree().create_timer(1).timeout
	get_tree().quit()
