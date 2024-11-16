extends RigidBody3D

# By exporting these, we can access them in the inspector when we click on the Scene node
# These values are found under player.gd in the Inspector on the Player node

## How much vertical force to apply when moving
@export_range(750, 2000) var thrust: float = 1000.0

## How much rotational force to apply when moving
@export var torque_thrust: float = 100.0

# We must wait for _ready to be called so that all child nodes are attached to the root node
# So we wait for @onready and store the ExplosionAudio child node in a variable so we can play it later
# You can hold CTRL and drag the ExplosionAudio node into a script to create this declaration for you
# Alternatively you can right-click the node in the SceneTree and select "Copy Node Path"
# Then you paste that after the dollar sign in order to access the node. Subnodes can look like $Node/SuccessAudio
@onready var explosion_audio: AudioStreamPlayer = $ExplosionAudio
@onready var success_audio: AudioStreamPlayer = $SuccessAudio
@onready var rocket_audio: AudioStreamPlayer3D = $RocketAudio
@onready var booster_particles: GPUParticles3D = $Body/BoosterParticles
@onready var booster_particles_left: GPUParticles3D = $Body/BoosterParticlesLeft
@onready var booster_particles_right: GPUParticles3D = $Body/BoosterParticlesRight
@onready var explosion_particles: GPUParticles3D = $ExplosionParticles
@onready var success_particles: GPUParticles3D = $SuccessParticles

var is_transitioning: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("boost"): # boost, rotate_left, rotate_right are mapped in Input Map
		# delta ensures that we are moving at the same amount no matter what machine we are on
		# So we are moving based on the frame interval rather than a fixed interval
		# thrust increases the amount of force being applied to the object
		# apply_central_force(Vector3.UP * delta * thrust) # Apply central force globally. Moves straight up.
		apply_central_force(basis.y * delta * thrust) # Apply central force based on the objects rotation.
		booster_particles.emitting = true
		if rocket_audio.playing == false:
			rocket_audio.play()
	else:
		rocket_audio.stop()
		booster_particles.emitting = false

	if Input.is_action_pressed("rotate_left"):
		booster_particles_right.emitting = true;
		apply_torque(Vector3(0.0, 0.0, torque_thrust * delta))
	else:
		booster_particles_right.emitting = false;

	if Input.is_action_pressed("rotate_right"):
		booster_particles_left.emitting = true;
		apply_torque(Vector3(0.0, 0.0, -torque_thrust * delta))
	else:
		booster_particles_left.emitting = false;
		
	if Input.is_action_just_pressed("quit"):
		print("Quitting the game")
		get_tree().quit()

func _on_body_entered(body: Node) -> void:
	# You must opt-in to using collision on the RigidBody3d node this script is attached to in the editor
	# Select the RigidBody3D node in the Scene. In the Inspector, select Solver -> check Contact Monitor
	# Set the number of objects that will be reported on collision via the Max Contacts Reported property,
	# in our case we have this set to 10
	if is_transitioning == false:
		if "Goal" in body.get_groups():
			complete_level(body.next_level_file_path)

		if "Hazard" in body.get_groups():
			crash_sequence()

func crash_sequence() -> void:
	print("You have crashed, reloading")

	explosion_audio.play()
	explosion_particles.emitting = true

	is_transitioning = true

	# set_process() takes a boolean. if false, it stops the _process function from running.
	# It is useful in this case as it stops player input from affecting the player position after a crash.
	set_process(false)

	# get_tree() gives us access to the SceneTree in code
	# This contains our running scene, the viewport when we launch the game, and is in charge of the game loop
	# Using this Object we can change, restart, and quit levels, pause the game and much more
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(get_tree().reload_current_scene)

func complete_level(next_level_file_path: String) -> void:
	print("You have completed the level!")
	
	success_audio.play()
	success_particles.emitting = true
	
	is_transitioning = true
	set_process(false)

	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(get_tree().change_scene_to_file.bind(next_level_file_path))
