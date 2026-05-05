extends CharacterBody2D

signal died

var player_node: CharacterBody2D
var is_dead := false
var current_health: int

# AI
enum AIState { ROAM, CHASE, ATTACK }
var current_state = AIState.ROAM

var has_aggro := false

# ROAM
var roam_target: Vector2
var roam_timer := 0.0
@export var roam_interval := 2.0

# STUCK
var stuck_timer := 0.0
var last_position: Vector2

@onready var sprite = $Sprite2D
@onready var animation = $Sprite2D/AnimationPlayer
@onready var collision = $CollisionShape2D
@onready var nav_agent: NavigationAgent2D = $NavAgent

@export var speed := 320
@export var max_health := 1
@export var damage := 1
@export var vision_range := 200.0
@export var stop_distance := 20.0

# INVIS
@export var invis_cooldown := 4.0
@export var invis_duration := 2.5
@export var reveal_range := 90.0

var invis_timer := 0.0
var invis_active := false


func _ready():
	add_to_group("Enemy")
	current_health = max_health
	player_node = get_tree().get_first_node_in_group("Player")

	last_position = global_position
	roam_target = get_random_nav_point()

	invis_timer = randf_range(1.0, invis_cooldown)

	nav_agent.radius = 5.0
	nav_agent.target_desired_distance = 4.0
	nav_agent.path_desired_distance = 4.0
	nav_agent.avoidance_enabled = true
	nav_agent.max_speed = speed


func _physics_process(delta):
	if is_dead:
		return

	handle_stuck(delta)

	update_ai_state()

	invis_timer -= delta

	if not invis_active and invis_timer <= 0:
		enter_invis()

	if invis_active:
		if invis_timer <= -invis_duration or global_position.distance_to(player_node.global_position) <= reveal_range:
			exit_invis()

	var target = get_ai_target()
	nav_agent.target_position = get_safe_target_position(target)

	move_along_path()


func update_ai_state():
	var distance = global_position.distance_to(player_node.global_position)
	var can_see = distance <= vision_range and can_see_player()

	if can_see:
		has_aggro = true

	match current_state:
		AIState.ROAM:
			if has_aggro:
				current_state = AIState.CHASE

		AIState.CHASE:
			if distance <= stop_distance:
				current_state = AIState.ATTACK

		AIState.ATTACK:
			if distance > stop_distance * 1.5:
				current_state = AIState.CHASE


func get_ai_target():
	match current_state:
		AIState.ROAM:
			return handle_roam()

		AIState.CHASE:
			return player_node.global_position

		AIState.ATTACK:
			return global_position

	return global_position


func handle_roam():
	roam_timer -= get_physics_process_delta_time()

	if roam_timer <= 0 or nav_agent.is_navigation_finished():
		roam_target = get_random_nav_point()
		roam_timer = roam_interval

	return roam_target


func get_random_nav_point():
	var map = get_world_2d().navigation_map
	var offset = Vector2(randf_range(-500, 500), randf_range(-500, 500))
	return NavigationServer2D.map_get_closest_point(map, global_position + offset)


func move_along_path():
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var next_point = nav_agent.get_next_path_position()
	var to_point = next_point - global_position
	var distance = global_position.distance_to(player_node.global_position)

	if has_aggro and distance <= stop_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var current_speed = speed * (1.25 if invis_active else 1.0)

	velocity = to_point.normalized() * current_speed
	chase_animation()
	move_and_slide()

	if not invis_active:
		sprite.flip_h = velocity.x < 0


func handle_stuck(delta):
	if global_position.distance_to(last_position) < 2:
		stuck_timer += delta
	else:
		stuck_timer = 0

	last_position = global_position

	if stuck_timer > 0.6:
		nav_agent.target_position = get_random_nav_point()
		stuck_timer = 0


func get_safe_target_position(target):
	var map = get_world_2d().navigation_map
	return NavigationServer2D.map_get_closest_point(map, target)


func can_see_player():
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player_node.global_position)
	query.exclude = [self]

	var result = space.intersect_ray(query)
	return result.is_empty() or result.collider == player_node


func enter_invis():
	invis_active = true
	sprite.visible = false
	collision.disabled = true
	invis_timer = 0.0


func exit_invis():
	invis_active = false
	sprite.visible = true
	collision.disabled = false
	invis_timer = randf_range(1.5, invis_cooldown)


func take_damage(amount):
	if is_dead:
		return

	current_health -= amount
	if current_health <= 0:
		die()


func die():
	if is_dead:
		return

	is_dead = true
	animation.play("death")
	died.emit()
	
func chase_animation():
	if !is_dead:
		animation.play("chase")
	
func _on_area_2d_body_entered(body):
	if is_dead:
		return

	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(damage)
		
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		queue_free()
