extends CharacterBody2D

signal died

var player_node: CharacterBody2D = null
var game_manager: Node = null
var is_dead: bool = false
var current_health: int

@onready var animate = $Sprite2D/AnimationPlayer
@onready var sprite = $Sprite2D

@export var speed: float = 300
@export var max_health: int = 3
@export var damage: int = 1


func _ready() -> void:
	add_to_group("Enemy")
	current_health = max_health
	animate.play("chase")

	player_node = get_tree().get_first_node_in_group("Player")
	game_manager = get_tree().current_scene


func set_target(target: CharacterBody2D) -> void:
	player_node = target


func _physics_process(delta: float) -> void:
	if is_dead or player_node == null:
		return

	var target = get_target_position()
	var direction = (target - global_position).normalized()

	velocity = velocity.lerp(direction * speed, 5.0 * delta)

	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

	move_and_slide()


# 🔥 ADAPTIVE AI
func get_target_position() -> Vector2:
	if player_node == null:
		return global_position

	var skill = 0.0
	if game_manager != null and game_manager.has_method("get_skill_score"):
		skill = game_manager.get_skill_score()

	if skill < 3.0:
		return player_node.global_position
	elif skill < 8.0:
		return player_node.global_position + (player_node.velocity * 0.4)
	else:
		var vel = player_node.velocity

		if vel.length() == 0:
			vel = Vector2.RIGHT
		else:
			vel = vel.normalized()

		var perpendicular = Vector2(-vel.y, vel.x)

		return player_node.global_position \
			+ (vel * 80) \
			+ (perpendicular * 60 * (1 if randf() < 0.5 else -1))


# 🔥 DAMAGE PLAYER (FIX)
func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_dead:
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
	animate.play("death")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		queue_free()
