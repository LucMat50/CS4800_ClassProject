extends Node2D

const BULLET_SCENE = preload("res://scenes/bullet.tscn")

@export var time_between: float = 0.1

var can_shoot: bool = true

@onready var shoot_pos = $RotationOffset/ShootPosition
@onready var shoot_timer = $ShootTimer

func _ready() -> void:
	shoot_timer.wait_time = time_between

func _process(_delta: float) -> void:
	look_at(get_global_mouse_position())

	rotation_degrees = wrap(rotation_degrees, 0.0, 360.0)
	if rotation_degrees > 90.0 and rotation_degrees < 270.0:
		scale.y = -1
	else:
		scale.y = 1

	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()
		can_shoot = false
		shoot_timer.start()

func shoot() -> void:
	var new_bullet = BULLET_SCENE.instantiate()
	get_tree().root.add_child(new_bullet)
	new_bullet.global_position = shoot_pos.global_position
	new_bullet.global_rotation = shoot_pos.global_rotation

	var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
	if game_manager != null and game_manager.has_method("register_shot_fired"):
		game_manager.register_shot_fired()

func _on_shoot_timer_timeout() -> void:
	can_shoot = true
