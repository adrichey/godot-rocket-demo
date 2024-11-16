extends Control

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var is_transitioning: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_transitioning == false:
		if Input.is_action_pressed("boost"):
			load_game()

		if Input.is_action_just_pressed("quit"):
			quit_game()

func load_game() -> void:
	audio_stream_player.play()

	is_transitioning = true

	# set_process() takes a boolean. if false, it stops the _process function from running.
	# It is useful in this case as it stops player input from affecting the player position after a crash.
	set_process(false)

	# get_tree() gives us access to the SceneTree in code
	# This contains our running scene, the viewport when we launch the game, and is in charge of the game loop
	# Using this Object we can change, restart, and quit levels, pause the game and much more
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(get_tree().change_scene_to_file.bind("res://Level/level.tscn"))

func quit_game() -> void:
	is_transitioning = true
	get_tree().quit()
