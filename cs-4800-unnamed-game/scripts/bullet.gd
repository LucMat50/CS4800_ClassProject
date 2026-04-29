extends Node2D

const SPEED = 500.0

@onready var ray = $RayCast2D

func _physics_process(delta: float) -> void:
	global_position += Vector2.RIGHT.rotated(rotation) * SPEED * delta

	ray.target_position = Vector2((SPEED * delta) + 10.0, 0.0)
	ray.force_raycast_update()

	if ray.is_colliding():
		var collider = ray.get_collider()
		enemy_hit(collider)

func enemy_hit(body: Node2D) -> void:
	if body != null and body.is_in_group("Enemy"):
		var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
		if game_manager != null and game_manager.has_method("register_shot_hit"):
			game_manager.register_shot_hit()

		if body.has_method("take_damage"):
			body.take_damage(1)

		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
