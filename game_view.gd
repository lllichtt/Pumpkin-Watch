extends Control

@onready var pumpkin = $pumpkinlayer/тыковка1
@onready var pumpkin2 = $pumpkinlayer/тыковка2
@onready var pumpkin3 = $pumpkinlayer/тыковка3
@onready var camera_feed = $camerafeed
@onready var glitch_overlay = $glitchoverlay
@onready var glitch_material = glitch_overlay.material as ShaderMaterial
@onready var spray_button = $SprayButton
@onready var spray_flash = $SprayFlash
@onready var game_over_screen = $"../GameOverScreen"
@onready var main_menu = $"../MainMenu"
@onready var victory_screen = $"../VictoryScreen"
@onready var night_clock = $NightClock

var night_timer = 0.0
var night_duration = 360.0
var night_finished = false

var spray_cooldown = 20.0
var spray_timer = 0.0

var normal_pumpkin = preload("res://assets/sprites/pumpkin.png")
var evil_pumpkin = preload("res://assets/sprites/jack_o_lantern.png")

var camera_positions = [
	# Камера 1
	[Vector2(524, 182), Vector2(262, 291), Vector2(146, 303)],
	# Камера 2
	[Vector2(448, 251), Vector2(68, 272), Vector2(272, 258)],
	# Камера 3
	[Vector2(407, 218), Vector2(105, 147), Vector2(437, 321)],
	# Камера 4
	[Vector2(68, 233), Vector2(470, 304), Vector2(289, 325)],
	# Камера 5
	[Vector2(113, 179), Vector2(340, 250), Vector2(500, 320)]
]

var occupied_positions = [
	[false, false, false],
	[false, false, false],
	[false, false, false],
	[false, false, false],
	[false, false, false]
]

var pumpkin_scale_1 = Vector2(0.7, 0.8)
var pumpkin_scale_2 = Vector2(1.0, 1.1)
var pumpkin_scale_3 = Vector2(1.4, 1.5)

var current_camera = 4
var selected_button = null

var cameras = [
	preload("res://assets/backgrounds/01street.png"),
	preload("res://assets/backgrounds/02graveyard.png"),
	preload("res://assets/backgrounds/03pumpkin_patch.png"),
	preload("res://assets/backgrounds/04scarecrow_cornfield.png"),
	preload("res://assets/backgrounds/05witch_clearing.png")
]

var pumpkin_route = [4, 3, 1, 0]

func _ready():
	$"../cameramap/Cam01Button".pressed.connect(
		change_camera.bind(0, $"../cameramap/Cam01Button")
	)
	$"../cameramap/Cam02Button".pressed.connect(
		change_camera.bind(1, $"../cameramap/Cam02Button")
	)
	$"../cameramap/Cam03Button".pressed.connect(
		change_camera.bind(2, $"../cameramap/Cam03Button")
	)
	$"../cameramap/Cam04Button".pressed.connect(
		change_camera.bind(3, $"../cameramap/Cam04Button")
	)
	$"../cameramap/Cam05Button".pressed.connect(
		change_camera.bind(4, $"../cameramap/Cam05Button")
	)

	glitch_overlay.visible = true
	glitch_material.set_shader_parameter("noise_strength", 0.08)
	glitch_material.set_shader_parameter("glitch_strength", 0.15)

	for camera_index in range(5):
		for stage_index in range(3):
			occupied_positions[camera_index][stage_index] = false

	setup_pumpkin(pumpkin, 4, 0, 5.0)
	setup_pumpkin(pumpkin2, 1, 0, randf_range(7.0, 12.0))
	setup_pumpkin(pumpkin3, 3, 0, randf_range(10.0, 15.0))

	camera_feed.texture = cameras[current_camera]
	update_pumpkin_visibility()
	
	main_menu.visible = true
	game_over_screen.visible = false
	victory_screen.visible = false

	get_tree().paused = true

func setup_pumpkin(pumpkin_node, camera_index, stage_index, initial_timer):
	pumpkin_node.pumpkin_camera = camera_index
	pumpkin_node.home_camera = camera_index
	pumpkin_node.stage = stage_index
	pumpkin_node.position = camera_positions[camera_index][stage_index]
	pumpkin_node.texture = normal_pumpkin

	if stage_index == 0:
		pumpkin_node.scale = pumpkin_scale_1
	elif stage_index == 1:
		pumpkin_node.scale = pumpkin_scale_2
	else:
		pumpkin_node.scale = pumpkin_scale_3
	occupied_positions[camera_index][stage_index] = true
	pumpkin_node.start_behavior(initial_timer)

func change_camera(camera_index, button):
	if selected_button != null:
		selected_button.modulate = Color.WHITE

	current_camera = camera_index
	camera_feed.texture = cameras[current_camera]

	selected_button = button
	selected_button.modulate = Color.GREEN

	update_pumpkin_visibility()
	spray_button.visible = (current_camera == 2)

func update_pumpkin_visibility():
	pumpkin.visible = (pumpkin.pumpkin_camera == current_camera)
	pumpkin2.visible = (pumpkin2.pumpkin_camera == current_camera)
	pumpkin3.visible = (pumpkin3.pumpkin_camera == current_camera)

func try_move_pumpkin(pumpkin_node):
	var camera_index = pumpkin_node.pumpkin_camera
	var current_stage = pumpkin_node.stage

	if current_stage < 2:
		var direction = 1

		if current_stage == 1:
			direction = [-1, 1].pick_random()

		var next_stage = current_stage + direction

		if occupied_positions[camera_index][next_stage]:
			return

		occupied_positions[camera_index][current_stage] = false
		occupied_positions[camera_index][next_stage] = true

		pumpkin_node.stage = next_stage
		pumpkin_node.position = camera_positions[camera_index][next_stage]

		if next_stage == 0:
			pumpkin_node.scale = pumpkin_scale_1
		elif next_stage == 1:
			pumpkin_node.scale = pumpkin_scale_2
		else:
			pumpkin_node.scale = pumpkin_scale_3

	else:
		var possible_cameras = []

		match camera_index:
			4: # Camera 5
				possible_cameras = [3, 1]
			3: # Camera 4
				possible_cameras = [2]
			2: # Camera 3
				return
			0: # Camera 1
				possible_cameras = [2]
			1: # Camera 2
				possible_cameras = [3, 0]

		var available_cameras = []

		for target_camera in possible_cameras:
			if not occupied_positions[target_camera][0]:
				available_cameras.append(target_camera)

		if available_cameras.is_empty():
			return

		var next_camera = available_cameras.pick_random()
		var next_stage = 0

		if occupied_positions[next_camera][next_stage]:
			return

		occupied_positions[camera_index][current_stage] = false
		occupied_positions[next_camera][next_stage] = true

		pumpkin_node.pumpkin_camera = next_camera
		pumpkin_node.stage = next_stage
		
		if next_camera == 2:
			pumpkin_node.attack_timer = pumpkin_node.attack_time
		
		pumpkin_node.position = camera_positions[next_camera][next_stage]
		pumpkin_node.scale = pumpkin_scale_1

	update_pumpkin_visibility()

func play_glitch():
	glitch_material.set_shader_parameter("noise_strength", 0.8)
	glitch_material.set_shader_parameter("glitch_strength", 1.0)
	await get_tree().create_timer(0.08).timeout

	glitch_material.set_shader_parameter("noise_strength", 0.05)
	glitch_material.set_shader_parameter("glitch_strength", 0.05)
	await get_tree().create_timer(0.06).timeout

	glitch_material.set_shader_parameter("noise_strength", 0.8)
	glitch_material.set_shader_parameter("glitch_strength", 1.0)
	await get_tree().create_timer(0.08).timeout

	glitch_material.set_shader_parameter("noise_strength", 0.08)
	glitch_material.set_shader_parameter("glitch_strength", 0.15)

func _on_spray_button_pressed():
	if spray_timer > 0.0:
		return
	
	var found_pumpkin = false
	
	for pumpkin_node in [pumpkin, pumpkin2, pumpkin3]:
		if pumpkin_node.pumpkin_camera == 2 and pumpkin_node.is_evil:
			occupied_positions[pumpkin_node.pumpkin_camera][pumpkin_node.stage] = false
			
			pumpkin_node.pumpkin_camera = pumpkin_node.home_camera
			pumpkin_node.stage = 0
			pumpkin_node.position = camera_positions[pumpkin_node.home_camera][0]
			pumpkin_node.scale = pumpkin_scale_1
			
			occupied_positions[pumpkin_node.home_camera][0] = true
			
			pumpkin_node.make_normal()
			found_pumpkin = true
	if found_pumpkin:
		play_spray_animation()
		spray_timer = spray_cooldown
		spray_button.text = "RECHARGING..."
		update_pumpkin_visibility()

func _process(delta):
	if not night_finished and not get_tree().paused:
		night_timer += delta
		var game_minutes = int(night_timer / night_duration * 360)
		var hours = int(game_minutes / 60)
		var minutes = game_minutes % 60

		if hours == 0:
			hours = 12

		night_clock.text = "%d:%02d AM" % [hours, minutes]

		if night_timer >= night_duration:
			win_game()

	if spray_timer > 0.0:
		spray_timer -= delta

		if spray_timer <= 0.0:
			spray_timer = 0.0
			spray_button.text = "SPRAY"

func play_spray_animation():
	spray_flash.visible = true
	spray_flash.color.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(spray_flash, "color:a", 0.45, 0.15)
	tween.tween_property(spray_flash, "color:a", 0.0, 0.4)
	
	tween.finished.connect(func():
		spray_flash.visible = false
	)

func game_over():
	game_over_screen.visible = true
	get_tree().paused = true

func start_game():
	night_timer = 0.0
	night_clock.text = "12:00 AM"
	night_finished = false
	victory_screen.visible = false
	main_menu.visible = false
	game_over_screen.visible = false

	for camera_index in range(5):
		for stage_index in range(3):
			occupied_positions[camera_index][stage_index] = false

	setup_pumpkin(pumpkin, 4, 0, 5.0)
	setup_pumpkin(pumpkin2, 1, 0, randf_range(7.0, 12.0))
	setup_pumpkin(pumpkin3, 3, 0, randf_range(7.0, 12.0))

	spray_timer = 0.0
	spray_button.text = "SPRAY"

	current_camera = 4
	camera_feed.texture = cameras[current_camera]

	update_pumpkin_visibility()
	spray_button.visible = false
	get_tree().paused = false

func _on_start_button_pressed():
	start_game()
	
func return_to_menu():
	get_tree().paused = false

	main_menu.visible = true
	game_over_screen.visible = false
	victory_screen.visible = false

	get_tree().paused = true

func _on_main_menu_button_pressed():
	return_to_menu()

func win_game():
	if night_finished:
		return

	night_finished = true
	victory_screen.visible = true
	get_tree().paused = true

func _on_victory_main_menu_button_pressed():
	return_to_menu()
