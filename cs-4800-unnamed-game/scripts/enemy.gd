extends CharacterBody2D

signal died

var direction: Vector2
var player_node: CharacterBody2D = null
var is_dead: bool = false

const SPEED = 300

func _ready() -> void:
	add_to_group("Enemy")

	if player_node == null:
		player_node = get_tree().get_first_node_in_group("Player") as CharacterBody2D

func set_target(target: CharacterBody2D) -> void:
	player_node = target

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if player_node == null:
		return

	direction = (player_node.global_position - global_position).normalized()
	velocity = velocity.lerp(direction * SPEED, 8.5 * delta)
	move_and_slide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_dead:
		return

	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(1)

func die() -> void:
	if is_dead:
		return

	is_dead = true
	died.emit()
	queue_free()
