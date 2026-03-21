extends CharacterBody2D

# NORMAL VARIABLES
var chase = false
var direction

# CONSTANT VARIABLES
const SPEED = 400

# ONREADY VARIABLES
@onready var player_node: CharacterBody2D = get_parent().get_node("Player")

func _physics_process(delta: float) -> void:
	direction = (player_node.global_position - global_position).normalized()
	velocity = lerp(velocity, direction * SPEED, 8.5 * delta)
	move_and_slide()

#func _on_area_2d_body_entered(body: Node2D) -> void:
#	if body == player_node:
#		get_tree().call_deferred("reload_current_scene")

#func _on_enter_area_body_entered(body: Node2D) -> void:
#	if body == player_node:
#		chase = true

#func _on_exit_area_body_exited(body: Node2D) -> void:
#	if body == player_node:
#		chase = false
