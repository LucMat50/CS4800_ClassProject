extends CharacterBody2D

# SIGNALS
signal died

# NORMAL VARIABLES
var direction: Vector2
var player_node: CharacterBody2D = null
var is_dead: bool = false
var current_health: int

# ONREADY VARIABLES
@onready var animate = $Sprite2D/AnimationPlayer

@export var speed: float = 300
@export var max_health: int = 3
@export var damage: int = 1


func _ready() -> void:
	add_to_group("Enemy")
	animate.play("chase")

	current_health = max_health

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
	velocity = velocity.lerp(direction * speed, 8.5 * delta)
	
	if velocity.x < 0:
		$Sprite2D.flip_h = true
	elif velocity.x > 0:
		$Sprite2D.flip_h = false
	
	move_and_slide()

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
	print("Enemy took damage:", amount, "Current HP:", current_health)	
		
func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	died.emit()
	animate.play("death")

func animations():
	if !is_dead:
		animate.play("chase")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		queue_free()
