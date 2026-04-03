extends CanvasLayer

@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/WaveLabel
@onready var game_over_label: Label = $GameOverLabel

func _ready() -> void:
	if game_over_label != null:
		game_over_label.visible = false

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

func show_game_over() -> void:
	if game_over_label == null:
		return
	game_over_label.visible = true
