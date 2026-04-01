extends CharacterBody2D

# NORMAL VARIABLES
var motion = Vector2()
var direction

# CONSTANT VARIABLES
const SPEED = 300

# ONREADY VARIABLES
@onready var player_node: CharacterBody2D = get_parent().get_node("Player")

func _physics_process(delta: float) -> void:
	position += (player_node.global_position - global_position) / 50
	direction = (player_node.global_position - global_position).normalized()
	velocity = lerp(velocity, direction * SPEED, 8.5 * delta)
	look_at(player_node.global_position)
	
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
	
	move_and_collide(motion)

#func _on_area_2d_body_entered(body: Node2D) -> void:
#	if body == player_node:
#		get_tree().call_deferred("reload_current_scene")

#func _on_enter_area_body_entered(body: Node2D) -> void:
#	if body == player_node:
#		chase = true

#func _on_exit_area_body_exited(body: Node2D) -> void:
#	if body == player_node:
#		chase = false
