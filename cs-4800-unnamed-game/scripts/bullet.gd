extends Node2D

# CONSTANTS
var SPEED = 500

# NORMAL VARIABLES
var movement_vector = Vector2(0, -1)

# ONREADY VARIABLES
@onready var bullet = $Sprite2D
@onready var ray = $RayCast2D

func _physics_process(delta: float) -> void:
	position += transform.x * SPEED * delta
	var move_amount = SPEED * delta
	ray.target_position = Vector2(move_amount + 2, 0)
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var collider = ray.get_collider()
		enemy_hit(collider)
	else:
		position += transform.x * SPEED * delta
	

func enemy_hit(body: Node2D):
	print("enemy hit")
	print(rotation)
	if body.is_in_group("Enemy"):
		body.queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
