extends Node

const ENEMY_QUICK = preload("res://scenes/enemyquick.tscn")
const ENEMY_TANK  = preload("res://scenes/enemytank.tscn")

@export var time_between_spawns: float = 0.6
@export var time_between_waves: float = 2.0
@export var base_enemies_per_wave: int = 3
@export var additional_enemies_per_wave: int = 2
@export var boss_wave: int = 5

var wave: int = 0
var score: int = 0
var enemies_alive: int = 0
var enemies_spawned_this_wave: int = 0
var enemies_to_spawn_this_wave: int = 0
var game_over: bool = false
var waiting_for_next_wave: bool = false
var boss_started: bool = false

# Hidden adaptive AI tracking
var shots_fired: int = 0
var shots_hit: int = 0
var damage_taken: int = 0
var time_alive: float = 0.0
var current_encounter_name: String = "Balanced"
var current_ai_state: String = "Normal"

@onready var main = get_tree().current_scene
@onready var player = main.get_node("Player")
@onready var enemy_container = main.get_node("Enemies")
@onready var spawn_points_parent = main.get_node("SpawnPoints")
@onready var hud = main.get_node("HUD")


var spawn_points: Array[Marker2D] = []

func _ready() -> void:
	randomize()

	for child in spawn_points_parent.get_children():
		if child is Marker2D:
			spawn_points.append(child)

	if spawn_points.is_empty():
		push_error("GameManager: No Marker2D spawn points found under SpawnPoints.")
		return

	if player.has_signal("died"):
		player.died.connect(_on_player_died)

	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)

	await get_tree().process_frame

	update_hud()
	start_next_wave()

func _process(delta: float) -> void:
	if game_over:
		return

	time_alive += delta
	update_hud_runtime()

func start_next_wave() -> void:
	if game_over:
		return

	if wave >= boss_wave and not boss_started:
		start_boss()
		return

	waiting_for_next_wave = false
	wave += 1
	enemies_spawned_this_wave = 0
	enemies_alive = 0

	choose_encounter_type()

	var base_count := base_enemies_per_wave + ((wave - 1) * additional_enemies_per_wave)
	enemies_to_spawn_this_wave = max(1, int(round(base_count * get_difficulty_multiplier())))

	update_hud()
	print("Starting Wave ", wave, " | Enemies: ", enemies_to_spawn_this_wave, " | Encounter: ", current_encounter_name, " | AI: ", current_ai_state)

	spawn_wave()

func spawn_wave() -> void:
	for _i in range(enemies_to_spawn_this_wave):
		if game_over:
			return

		spawn_enemy()
		await get_tree().create_timer(time_between_spawns).timeout

func spawn_enemy() -> void:
	var enemy_scene
	var skill = get_skill_score()

	if skill < 3.0:
		enemy_scene = ENEMY_QUICK
	elif skill < 8.0:
		enemy_scene = ENEMY_QUICK if randf() < 0.7 else ENEMY_TANK
	else:
		enemy_scene = ENEMY_QUICK if randf() < 0.5 else ENEMY_TANK

	var enemy = enemy_scene.instantiate()
	var spawn_point = spawn_points[randi() % spawn_points.size()]

	enemy.global_position = spawn_point.global_position
	enemy_container.add_child(enemy)

	if enemy.has_method("set_target"):
		enemy.set_target(player)

	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

	enemies_spawned_this_wave += 1
	enemies_alive += 1
	print(enemy_scene.resource_path)

func choose_encounter_type() -> void:
	var encounter_type := randi() % 3

	match encounter_type:
		0:
			current_encounter_name = "Swarm"
			time_between_spawns = 0.3
		1:
			current_encounter_name = "Pressure"
			time_between_spawns = 0.45
		_:
			current_encounter_name = "Balanced"
			time_between_spawns = 0.6

func get_accuracy() -> float:
	if shots_fired == 0:
		return 0.0
	return float(shots_hit) / float(shots_fired)

func get_skill_score() -> float:
	if shots_fired == 0:
		return 0.0
	
	var accuracy = float(shots_hit) / shots_fired
	
	# Normalize score so it doesn't dominate (tune divisor later)
	var normalized_score = float(score) / 100.0
	
	return (accuracy * 5.0) \
		+ (time_alive * 0.02) \
		+ (normalized_score * 1.5) \
		- (damage_taken * 0.5)

func get_difficulty_multiplier() -> float:
	var skill := get_skill_score()

	if skill < 3.0:
		current_ai_state = "Easing"
		return 0.8
	elif skill < 8.0:
		current_ai_state = "Normal"
		return 1.0
	else:
		current_ai_state = "Increasing"
		return 1.3

func register_shot_fired() -> void:
	shots_fired += 1

func register_shot_hit() -> void:
	shots_hit += 1
	score += 10
	update_hud()

func register_player_damage(amount: int = 1) -> void:
	damage_taken += amount

func _on_enemy_died() -> void:
	enemies_alive -= 1
	update_hud()

	print("Score: ", score, " | Enemies Left: ", enemies_alive)

	if enemies_alive <= 0 and enemies_spawned_this_wave >= enemies_to_spawn_this_wave and not waiting_for_next_wave:
		waiting_for_next_wave = true
		print("Wave ", wave, " cleared.")
		await get_tree().create_timer(time_between_waves).timeout
		start_next_wave()

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	hud.update_health(current_health, max_health)

func _on_player_died() -> void:
	if game_over:
		return

	game_over = true
	hud.show_game_over(wave - 1, score, get_accuracy())
	print_run_summary()


func start_boss() -> void:
	boss_started = true
	current_encounter_name = "Boss"
	current_ai_state = "Counter Strategy"
	print("Boss Fight Starting")
	print("For Phase 1, this is a placeholder boss trigger. You can replace it with a boss spawn next.")

func print_run_summary() -> void:
	print("===== RUN SUMMARY =====")
	print("Wave Reached: ", wave)
	print("Score: ", score)
	print("Shots Fired: ", shots_fired)
	print("Shots Hit: ", shots_hit)
	print("Accuracy: ", "%.2f%%" % (get_accuracy() * 100.0))
	print("Damage Taken: ", damage_taken)
	print("Time Alive: ", "%.2f" % time_alive, " seconds")
	print("Skill Score: ", "%.2f" % get_skill_score())
	print("AI State: ", current_ai_state)
	print("Encounter: ", current_encounter_name)
	print("=======================")

func update_hud() -> void:
	hud.update_score(score)
	hud.update_wave(wave)

func update_hud_runtime() -> void:
	pass
	
