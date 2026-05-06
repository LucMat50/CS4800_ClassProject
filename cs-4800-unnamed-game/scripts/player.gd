extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

# =========================
# VARIABLES
# =========================

var input_direction: Vector2
var current_health: int
var is_dead: bool = false
var is_invulnerable: bool = false

# =========================
# CONSTANTS
# =========================

const SPEED = 360
const RUN_SPEED = 500
const MAX_HEALTH = 5
const INVULNERABILITY_TIME = 0.6

# =========================
# ONREADY
# =========================

@onready var animate = $Character/AnimationPlayer
@onready var character = $Character
@onready var gun = $Gun
@onready var camera = $Camera2D

# Camera lead
@export var camera_lead_strength: float = 140.0
@export var camera_smooth_speed: float = 6.0

# =========================
# READY
# =========================

func _ready() -> void:
	GameManager.player = self

	add_to_group("Player")

	current_health = MAX_HEALTH

	health_changed.emit(current_health, MAX_HEALTH)

# =========================
# INPUT
# =========================

func get_input() -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	input_direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if Input.is_action_pressed("run"):
		velocity = input_direction * RUN_SPEED
	else:
		velocity = input_direction * SPEED

# =========================
# AIMING
# =========================

func handle_aiming(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()

	# Direction from player to mouse
	var aim_direction = (mouse_pos - global_position).normalized()

	# Rotate gun toward mouse
	gun.rotation = aim_direction.angle()

	# Flip player based on aim direction
	if mouse_pos.x < global_position.x:
		character.flip_h = false
		gun.scale.y = -1
	else:
		character.flip_h = true
		gun.scale.y = 1

	# Camera lead toward mouse
	var local_mouse = mouse_pos - global_position

	var desired_offset = local_mouse.normalized() * min(
		local_mouse.length(),
		camera_lead_strength
	)

	camera.offset = camera.offset.lerp(
		desired_offset,
		camera_smooth_speed * delta
	)

# =========================
# DAMAGE
# =========================

func take_damage(amount: int = 1) -> void:
	if is_dead or is_invulnerable:
		return

	current_health -= amount
	current_health = max(current_health, 0)

	health_changed.emit(current_health, MAX_HEALTH)

	if current_health <= 0:
		die()
		return

	is_invulnerable = true

	set_process_input(false)
	set_physics_process(false)

	animate.play("hurt")

	await get_tree().create_timer(INVULNERABILITY_TIME).timeout

	set_process_input(true)
	set_physics_process(true)

	if not is_dead:
		is_invulnerable = false

# =========================
# DEATH
# =========================

func die() -> void:
	if is_dead:
		return

	is_dead = true

	velocity = Vector2.ZERO

	animate.play("death")

	died.emit()

# =========================
# ANIMATIONS
# =========================

func animations() -> void:
	if is_dead:
		return

	if is_invulnerable:
		return

	if velocity == Vector2.ZERO:
		animate.play("default")
	else:
		animate.play("run")

# =========================
# PHYSICS
# =========================

func _physics_process(delta: float) -> void:
	get_input()

	handle_aiming(delta)

	animations()

	move_and_slide()
