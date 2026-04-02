extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

var input_direction: Vector2
var right_left: String = "right"
var current_health: int
var is_dead: bool = false
var is_invulnerable: bool = false
# NORMAL VARIABLES
var input_direction
var right_left = "right"
var hit = false
var dead = false

const SPEED = 450
const RUN_SPEED = 600
const MAX_HEALTH = 5
const INVULNERABILITY_TIME = 0.6

@onready var animate = $Character
# ONREADY VARAIBLES
@onready var shooter = $Shooter
@onready var animate = $Character/AnimationPlayer

func _ready() -> void:
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

func hurt() -> void:
	take_damage(1)

func take_damage(amount: int = 1) -> void:
	if is_dead or is_invulnerable:
		return

	current_health -= amount
	current_health = max(current_health, 0)
	health_changed.emit(current_health, MAX_HEALTH)

	var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
	if game_manager != null and game_manager.has_method("register_player_damage"):
		game_manager.register_player_damage(amount)

	if current_health <= 0:
		die()
		return

	is_invulnerable = true
	animate.play("hurt")
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout

	if not is_dead:
		is_invulnerable = false

func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_invulnerable = true
	velocity = Vector2.ZERO
	animate.play("death")
	died.emit()

func animations() -> void:
	if is_dead:
		return
func hurt():
	GameManager.health -= 1
	print(GameManager.health)
	hit = true
	if GameManager.health == 0:
		print("Ded")
		death()

func death():
	dead = true
	self.set_process_input(false)
	self.set_physics_process(false)
	animate.play("death")

	if right_left == "left":
		$Character.flip_h = false
	else:
		$Character.flip_h = true

	if velocity == Vector2.ZERO:
		animate.play("default")
	else:
		animate.play("walk_run")
	
	if !dead and !hit:
		if velocity.x == 0 and velocity.y == 0:
			animate.play("default")
		elif velocity.x != 0 or velocity.y != 0:
			animate.play("run")
			
	elif !dead and hit:
		animate.play("hurt")
		self.set_process_input(false)
		self.set_physics_process(false)
		await get_tree().create_timer(1).timeout
		self.set_process_input(true)
		self.set_physics_process(true)
		hit = false
		
func _ready():
	GameManager.player = self

func _physics_process(_delta: float) -> void:
	get_input()
	direction()
	animations()
	move_and_slide()
