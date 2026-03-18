extends CharacterBody2D
const SPEED = 450
const RUN_SPEED = 600

func get_input():
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_pressed("run"):
		velocity = input_direction * RUN_SPEED
	else: 
		velocity = input_direction * SPEED
	
func _physics_process(_delta: float) -> void:
	get_input()
	move_and_slide()
