extends Sprite2D

var is_evil = false
var stage = 0
var pumpkin_camera = 4
var home_camera = 4

var state_timer = 0.0
var evil_timer = 5.0
var move_timer = 0.0
var waiting_to_move = false

var attack_timer = 0.0
var attack_time = 15.0

var normal_texture = preload("res://assets/sprites/pumpkin.png")
var evil_texture = preload("res://assets/sprites/jack_o_lantern.png")

@onready var game_view = get_parent().get_parent()

func start_behavior(initial_timer):
	texture = normal_texture
	is_evil = false
	evil_timer = initial_timer
	state_timer = 0.0
	move_timer = 0.0
	waiting_to_move = false

func make_evil():
	texture = evil_texture
	is_evil = true
	state_timer = randf_range(14.0, 20.0)
	move_timer = randf_range(3.5, 6.0)
	waiting_to_move = true

func make_normal():
	texture = normal_texture
	is_evil = false

	attack_timer = 0.0

	evil_timer = randf_range(5.0, 9.0)
	state_timer = randf_range(3.0, 6.0)

	waiting_to_move = false

func _process(delta):
	if not is_evil:
		evil_timer -= delta
		if evil_timer <= 0.0:
			make_evil()
	else:
		if pumpkin_camera == 2:
			attack_timer -= delta

			if attack_timer <= 0.0:
				attack_timer = 0.0
				game_view.game_over()
				return
		state_timer -= delta
		if waiting_to_move:
			move_timer -= delta
			if move_timer <= 0.0:
				waiting_to_move = false
				game_view.try_move_pumpkin(self)
				game_view.play_glitch()
				if is_evil:
					waiting_to_move = true
					move_timer = randf_range(2.5, 4.0)
		if state_timer <= 0.0:
			make_normal()
