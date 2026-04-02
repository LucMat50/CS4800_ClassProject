extends Node2D

# CONSTANTS
const bullet = preload("res://scenes/bullet.tscn")

# NORMAL VARIABLES
var time_between = 0.1
var can_shoot = true

# ONREADY VARIABLES
@onready var shootPos = $RotationOffset/ShootPosition

func _ready() -> void:
	$ShootTimer.wait_time = time_between
	
func _process(_delta: float) -> void:
	if GameManager.player.dead == false:
		look_at(get_global_mouse_position())
		
		rotation_degrees = wrap(rotation_degrees, 0, 360)
		if rotation_degrees > 90 and rotation_degrees < 270:
			scale.y = -1
		else:
			scale.y = 1
	
		if Input.is_action_just_pressed("shoot") and can_shoot:
			shoot()
			can_shoot = false
			$ShootTimer.start()

func shoot():
	var new_bullet = bullet.instantiate()
	get_tree().root.add_child(new_bullet)
	new_bullet.global_position = shootPos.global_position
	new_bullet.global_rotation = shootPos.global_rotation
	
func _on_shoot_timer_timeout() -> void:
	can_shoot = true
