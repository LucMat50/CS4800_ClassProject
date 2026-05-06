extends CharacterBody2D

signal died

# =========================
# CORE
# =========================
var player_node: CharacterBody2D
var is_dead := false
var current_health: int

# =========================
# AI STATE
# =========================
enum AIState { ROAM, CHASE, ATTACK, REPOSITION }
var current_state = AIState.ROAM

var has_aggro := false
var aggro_timer := 0.0
@export var aggro_memory_time := 9999.0

# =========================
# ROAM
# =========================
var roam_target: Vector2
var roam_timer := 0.0
@export var roam_interval := 2.0

# =========================
# STUCK
# =========================
var stuck_timer := 0.0
var last_position: Vector2

# =========================
# NODES
# =========================
@onready var sprite = $Sprite2D
@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var animation = $Sprite2D/AnimationPlayer

# =========================
# STATS
# =========================
@export var speed := 200
@export var max_health := 3
@export var damage := 1
@export var vision_range := 200.0
@export var stop_distance := 20.0


func _ready():
	add_to_group("Enemy")
	current_health = max_health
	player_node = get_tree().get_first_node_in_group("Player")

	last_position = global_position
	roam_target = get_random_nav_point()

	nav_agent.radius = 5.0
	nav_agent.target_desired_distance = 4.0
	nav_agent.path_desired_distance = 4.0
	nav_agent.avoidance_enabled = true
	nav_agent.max_speed = speed


func _physics_process(delta):
	if is_dead or player_node == null:
		return

	handle_stuck(delta)

	update_ai_state()

	var target = get_ai_target()
	nav_agent.target_position = get_safe_target_position(target)

	move_along_path()


# =========================
# AI STATE LOGIC
# =========================
func update_ai_state():
	var distance = global_position.distance_to(player_node.global_position)
	var can_see = distance <= vision_range and can_see_player()

	if can_see:
		has_aggro = true
		aggro_timer = aggro_memory_time
	elif has_aggro:
		aggro_timer -= get_physics_process_delta_time()
		if aggro_timer <= 0:
			has_aggro = false

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

			elif get_player_skill() >= 8:
				current_state = AIState.REPOSITION

		AIState.REPOSITION:
			if distance > stop_distance * 2:
				current_state = AIState.CHASE


# =========================
# TARGETING
# =========================
func get_ai_target() -> Vector2:
	var skill = get_player_skill()

	match current_state:
		AIState.ROAM:
			return handle_roam()

		AIState.CHASE:
			if skill < 5:
				return player_node.global_position
			elif skill < 8:
				return player_node.global_position + player_node.velocity * 0.3
			else:
				return get_flank_position()

		AIState.ATTACK:
			return global_position

		AIState.REPOSITION:
			return get_flank_position()

	return global_position


func get_flank_position():
	var player_pos = player_node.global_position
	var player_vel = player_node.velocity

	var move_dir = player_vel
	if move_dir.length() == 0:
		move_dir = player_pos - global_position

	move_dir = move_dir.normalized()
	var perpendicular = Vector2(-move_dir.y, move_dir.x)
	var side = 1 if randf() < 0.5 else -1

	return player_pos + perpendicular * 100 * side


# =========================
# ROAM
# =========================
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

# =========================
# MOVEMENT
# =========================
func move_along_path():
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var next_point = nav_agent.get_next_path_position()
	var to_point = next_point - global_position
	var distance_to_player = global_position.distance_to(player_node.global_position)

	# STOP PUSHING PLAYER
	if has_aggro and distance_to_player <= stop_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if to_point.length() < 4:
		nav_agent.target_position = get_safe_target_position(nav_agent.target_position)
		return

	velocity = to_point.normalized() * speed
	chase_animation()
	move_and_slide()

	sprite.flip_h = velocity.x < 0


# =========================
# HELPERS
# =========================
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


func get_player_skill():
	var gm = get_tree().current_scene
	if gm.has_method("get_skill_score"):
		return gm.get_skill_score()
	return 0.0


# =========================
# DAMAGE
# =========================
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
	died.emit()
	$Die.play()
	animation.play("death")

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
