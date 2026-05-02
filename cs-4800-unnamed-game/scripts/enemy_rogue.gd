extends CharacterBody2D

signal died

var player_node: CharacterBody2D = null
var is_dead: bool = false
var current_health: int

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

@export var speed: float = 360   # 🔥 faster than tank/quick
@export var max_health: int = 1
@export var damage: int = 1

# 🔥 INVISIBILITY TUNING
@export var invis_cooldown: float = 4.0
@export var invis_duration: float = 2.5
@export var reveal_range: float = 90.0

var invis_timer: float = 0.0
var invis_active: bool = false


func _ready() -> void:
	add_to_group("Enemy")
	current_health = max_health
	player_node = get_tree().get_first_node_in_group("Player")

	invis_timer = invis_cooldown


func _physics_process(delta: float) -> void:
	if is_dead or player_node == null:
		return

	var to_player = player_node.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized()

	# 🔥 TIMER
	invis_timer -= delta

	# 🔥 ENTER INVISIBILITY
	if not invis_active and invis_timer <= 0:
		enter_invis()

	# 🔥 EXIT INVISIBILITY
	if invis_active:
		# reveal if too close OR timer ends
		if invis_timer <= -invis_duration or distance <= reveal_range:
			exit_invis()

	# 🔥 FAST MOVEMENT (always aggressive)
	velocity = direction * speed
	move_and_slide()

	# 🔥 Only flip if visible
	if not invis_active:
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false


# =========================
# 🔥 INVISIBILITY FUNCTIONS
# =========================

func enter_invis():
	invis_active = true

	sprite.visible = false
	collision.disabled = true   # optional: prevents unfair contact

	print("ROGUE → INVISIBLE")


func exit_invis():
	invis_active = false

	sprite.visible = true
	collision.disabled = false

	invis_timer = invis_cooldown

	print("ROGUE → REVEALED")


# =========================
# 🔥 DAMAGE SYSTEM
# =========================

func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_dead or invis_active:
		return

	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(damage)


func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount

	if current_health <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	died.emit()
	queue_free()
