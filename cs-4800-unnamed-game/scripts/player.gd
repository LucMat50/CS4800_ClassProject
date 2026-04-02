extends CharacterBody2D

# NORMAL VARIABLES
var input_direction
var right_left = "right"
var hit = false
var dead = false

# CONSTANT VARIABLES
const SPEED = 450
const RUN_SPEED = 600

# ONREADY VARAIBLES
@onready var shooter = $Shooter
@onready var animate = $Character/AnimationPlayer

# SCENES


func get_input():
	input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if Input.is_action_pressed("run"):
		velocity = input_direction * RUN_SPEED
	else: 
		velocity = input_direction * SPEED

func direction():
	if velocity.x < 0:
		right_left = "left"
		
	elif velocity.x > 0:
		right_left = "right"

func hurt():
	GameManager.health -= 1
	print(GameManager.health)
	hit = true
	if GameManager.health == 0:
		print("Ded")
		death()

func death():
	dead = true
	self.set_process_input(false)
	self.set_physics_process(false)
	animate.play("death")

func animations():
	if right_left == "left":
		$Character.flip_h = false
	else:
		$Character.flip_h = true
	
	if !dead and !hit:
		if velocity.x == 0 and velocity.y == 0:
			animate.play("default")
		elif velocity.x != 0 or velocity.y != 0:
			animate.play("run")
			
	elif !dead and hit:
		animate.play("hurt")
		self.set_process_input(false)
		self.set_physics_process(false)
		await get_tree().create_timer(1).timeout
		self.set_process_input(true)
		self.set_physics_process(true)
		hit = false
		

func _ready():
	GameManager.player = self

func _physics_process(_delta: float) -> void:
	direction()
	animations()
	get_input()
	move_and_slide()
