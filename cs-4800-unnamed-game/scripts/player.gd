extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

# VARIABLES
var input_direction: Vector2
var right_left: String = "right"
var current_health: int
var is_dead: bool = false
var is_invulnerable: bool = false

# CAMERA VARIABLES
@onready var cam: Camera2D = $Camera2D

@export var cam_follow_speed: float = 6.0
@export var cam_lookahead_distance: float = 130.0
@export var cam_lookahead_smoothing: float = 5.0

var cam_lookahead: Vector2 = Vector2.ZERO

# CONSTANTS
const SPEED = 300
const RUN_SPEED = 500
const MAX_HEALTH = 5
const INVULNERABILITY_TIME = 0.7

# ONREADY
@onready var animate = $Character/AnimationPlayer

func _ready() -> void:
	GameManager.player = self
	add_to_group("Player")
	current_health = MAX_HEALTH
	health_changed.emit(current_health, MAX_HEALTH)

func get_input() -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if Input.is_action_pressed("run"):
		velocity = input_direction * RUN_SPEED
	else:
		velocity = input_direction * SPEED

func direction() -> void:
	if velocity.x < 0:
		right_left = "left"
	elif velocity.x > 0:
		right_left = "right"

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
	self.set_process_input(false)
	self.set_physics_process(false)
	$Hit.play()
	animate.play("hurt")
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	self.set_process_input(true)
	self.set_physics_process(true)

	if not is_dead:
		is_invulnerable = false

func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	$Dead.play()
	animate.play("death")
	died.emit()

func animations() -> void:
	if !is_dead and !is_invulnerable:
		if right_left == "left":
			$Character.flip_h = false
			$Gun.position = Vector2(-36, -2)
		else:
			$Character.flip_h = true
			$Gun.position = Vector2(36, 2)

		if velocity == Vector2.ZERO:
			animate.play("default")
		else:
			animate.play("run")

func _physics_process(delta: float) -> void:
	get_input()
	direction()
	animations()
	move_and_slide()

	update_camera(delta)   # 🔥 CAMERA UPDATE


# =========================
# 🔥 CAMERA SYSTEM
# =========================

func update_camera(delta: float) -> void:
	var target_lookahead = Vector2.ZERO

	# 🔥 Movement-based lookahead
	if velocity.length() > 2:
		target_lookahead = velocity.normalized() * cam_lookahead_distance

	# 🔥 OPTIONAL: Aim bias (helps with shooting visibility)
	var mouse_dir = (get_global_mouse_position() - global_position)
	if mouse_dir.length() > 0:
		target_lookahead += mouse_dir.normalized() * 40

	# 🔥 Smooth transition
	cam_lookahead = cam_lookahead.lerp(target_lookahead, delta * cam_lookahead_smoothing)

	# 🔥 Apply offset (relative to player)
	cam.position = cam.position.lerp(cam_lookahead, delta * cam_follow_speed)
