extends Node2D

# CONSTANTS
var SPEED = 500
# NORMAL VARIABLES
var movement_vector = Vector2(0, -1)

# ONREADY VARIABLES
@onready var bullet = $Sprite2D

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta
