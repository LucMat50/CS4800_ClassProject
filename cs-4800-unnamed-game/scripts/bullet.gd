extends Node2D

# NORMAL VARIABLES
var speed = 700

# ONREADY VARIABLES
@onready var bullet = $Sprite2D
@onready var rayCast = $RayCast2D

func _physics_process(delta: float) -> void:
	global_position += Vector2(1, 0).rotated(rotation) * speed * delta
	bullet.position += Vector2(-2, 2).rotated(-rotation)
	if rayCast.is_colliding():
		queue_free()
