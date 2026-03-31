extends Node2D

# CONSTANTS
const bullet = preload("res://scenes/bullet.tscn")

# NORMAL VARIABLES
var time_between = 0.25
var can_shoot = true

# ONREADY VARIABLES
@onready var gun = $RotationOffset/Sprite2D
@onready var rotationOffset = $RotationOffset
@onready var shootPos = $RotationOffset/ShootPosition

func shoot():
	var new_bullet = bullet.instantiate()
	new_bullet.global_position = shootPos.global_position
	new_bullet.global_rotation = shootPos.global_rotation
	get_parent().add_child(new_bullet)
	
func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _ready() -> void:
	$ShootTimer.wait_time = time_between
	
func _physics_process(delta: float) -> void:
	rotationOffset.rotation = lerp_angle(rotationOffset.rotation, (get_global_mouse_position() - global_position).angle(), 6.5*delta)
	gun.position = Vector2(-2, 2).rotated(-rotationOffset.rotation)
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		can_shoot = false
		$ShootTimer.start()
