extends Node

var coins: int = 0
var experience: int = 0
var level: int = 1
var xp_to_next_level: int = 100

signal coins_changed(new_amount)
signal experience_changed(new_amount)
signal level_up(new_level)

func add_coins(amount: int):
	coins += amount
	emit_signal("coins_changed", coins)

func add_experience(amount: int):
	experience += amount
	emit_signal("experience_changed", experience)
	check_level_up()

func check_level_up():
	if experience >= xp_to_next_level:
		experience -= xp_to_next_level
		level += 1
		xp_to_next_level = int(xp_to_next_level * 1.5)  # each level needs more XP
		emit_signal("level_up", level)
