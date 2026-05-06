extends Node2D

const ENEMY_QUICK = preload("res://scenes/enemyquick.tscn")
const ENEMY_TANK  = preload("res://scenes/enemytank.tscn")
const ENEMY_ROGUE = preload("res://scenes/enemyrogue.tscn")

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

# Adaptive AI tracking
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
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	randomize()

	for child in spawn_points_parent.get_children():
		if child is Marker2D:
			spawn_points.append(child)

	if spawn_points.is_empty():
		push_error("No spawn points found.")
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
	
	if Input.is_action_just_pressed("shoot"):
		register_shot_fired()
	
	won()


# =========================
# WAVE SYSTEM
# =========================

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

	var base_count := base_enemies_per_wave + ((wave - 1) * additional_enemies_per_wave)
	var difficulty := get_difficulty_multiplier()

	# Skill → more enemies
	enemies_to_spawn_this_wave = int(base_count * difficulty + (wave * 0.5))

	spawn_wave()
	update_hud()


func spawn_wave() -> void:
	for _i in range(enemies_to_spawn_this_wave):
		if game_over:
			return

		spawn_enemy()
		update_hud()

		# Skill → faster spawn
		var delay = time_between_spawns / get_difficulty_multiplier()
		await get_tree().create_timer(delay).timeout


# =========================
# ENEMY SPAWN (random types)
# =========================

func spawn_enemy() -> void:
	var r = randf()
	var enemy_scene

	if r < 0.6:
		enemy_scene = ENEMY_QUICK
	elif r < 0.85:
		enemy_scene = ENEMY_TANK
	else:
		enemy_scene = ENEMY_ROGUE

	var enemy = enemy_scene.instantiate()
	var spawn_point = spawn_points[randi() % spawn_points.size()]

	enemy.global_position = spawn_point.global_position
	enemy_container.add_child(enemy)

	if enemy.has_method("set_target"):
		enemy.set_target(player)

	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

	enemies_alive += 1
	update_hud()

# =========================
# SKILL SYSTEM
# =========================

func get_accuracy() -> float:
	if shots_fired == 0:
		return 0.5
	else:
		GameManager.accuracy = float(shots_hit) / float(shots_fired)
		return float(shots_hit) / float(shots_fired)


func get_skill_score() -> float:
	var accuracy = get_accuracy()
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

# =========================
# EVENTS
# =========================

func register_shot_fired() -> void:
	shots_fired += 1

func register_shot_hit() -> void:
	shots_hit += 1
	score += 10
	GameManager.score = score
	update_hud()

func register_player_damage(amount: int = 1) -> void:
	damage_taken += amount

func _on_enemy_died() -> void:
	enemies_alive -= 1
	
	register_shot_hit()
	
	if enemies_alive <= 0 and not waiting_for_next_wave:
		waiting_for_next_wave = true
		await get_tree().create_timer(time_between_waves).timeout
		start_next_wave()

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	hud.update_health(current_health, max_health)

func _on_player_died() -> void:
	game_over = true
	await get_tree().create_timer(3).timeout
	hud.show_game_over(wave - 1, score, get_accuracy())

func start_boss() -> void:
	boss_started = true

func update_hud() -> void:
	hud.update_score(score)
	hud.update_wave(wave)
	hud.update_enemies(enemies_alive)

func won():
	if wave == 5 and enemies_alive == 0:
		await get_tree().create_timer(3).timeout
		get_tree().change_scene_to_file("res://scenes/you_won.tscn")
