
#inheritance
extends CharacterBody3D

#all of my constants and variables are below

var speed = 0.0
const WALK_SPEED = 8.0
const SPRINT_SPEED = 12.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.004
const HIT_STAGGER = 8.0

# Bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

# FOV variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Signal
signal player_hit

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

# Bullets
var bullet = load("res://Scenes/Bullet.tscn")
var instance

# Variables for crouch state
var crouch_speed = 4.0  # Reduced speed when crouching
var normal_speed = WALK_SPEED  # Initialize normal speed with WALK_SPEED
var is_crouching = false
var normal_height = 2.0  # Normal height of the player's collision shape
var crouch_height = 1.0  # Height when crouching
var crouch_transition_speed = 5.0  # Smooth transition speed between crouching and standing




# Nodes
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var gun_anim = $Head/Camera3D/Rifle/AnimationPlayer
@onready var gun_barrel = $Head/Camera3D/Rifle/RayCast3D
@onready var gun_anim2 = $Head/Camera3D/Rifle2/AnimationPlayer
@onready var gun_barrel2 = $Head/Camera3D/Rifle2/RayCast3D
@onready var collision_shape = $CollisionShape3D

#makes it so the mouse is not being showed and it stuck in the middle of the screen
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#controls the sensitivity of the controls and makes it so the player can't look to far left and right and up and down
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


#below is the the physics processer and controls most movement related stuff
func _physics_process(delta):
	# Add gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jumping.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY
	
	# Handle sprinting, walking and crouching speeds.
	if Input.is_action_pressed("sprint") and not is_crouching:
		speed = SPRINT_SPEED
	else:
		speed = crouch_speed if is_crouching else normal_speed  

	# Checks to see if the crouch button is pushed and if it is then it will initiate the crouch, if it isn't then the crouch will end
	if Input.is_action_pressed("crouch"):
		_start_crouch(delta)
	else:
		_stop_crouch(delta)

	# Get input direction and handle movement.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

#the code below uses linear interpolation to smooth out changes in velocity
	if is_on_floor():
		if direction != Vector3(0, 0, 0):
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 15.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 15.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	# Head bob.
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	# FOV change while moving.
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	# Shooting
	if Input.is_action_pressed("shoot"):
	# Check if the first gun's animation is not playing
		if !gun_anim.is_playing():
			gun_anim.play("Shoot")  # Play the "Shoot" animation on gun_anim
			instance = bullet.instantiate()  # Create a new instance of the bullet
			instance.position = gun_barrel.global_position  # Set bullet position to the first gun barrel's position
			instance.transform.basis = gun_barrel.global_transform.basis  # Match bullet orientation with the gun barrel's
			get_parent().add_child(instance)  # Add the bullet instance to the scene as a child of the parent node

	# Check if the second gun's animation is not playing
		if !gun_anim2.is_playing():
			gun_anim2.play("Shoot")  # Play the "Shoot" animation on gun_anim2
			instance = bullet.instantiate()  # Create another bullet instance
			instance.position = gun_barrel2.global_position  # Set bullet position to the second gun barrel's position
			instance.transform.basis = gun_barrel2.global_transform.basis  # Match bullet orientation with the gun barrel
			get_parent().add_child(instance)  # Add this bullet instance to the scene


	move_and_slide()

# Function to handle crouching.
func _start_crouch(delta):
	if not is_crouching:
		is_crouching = true
	# Smoothly reduce height while crouching.
	collision_shape.shape.height = lerp(collision_shape.shape.height, crouch_height, crouch_transition_speed * delta)

# Function to stop crouching.
func _stop_crouch(delta):
	if is_crouching:
		is_crouching = false
	# Smoothly reset height to normal.
	collision_shape.shape.height = lerp(collision_shape.shape.height, normal_height, crouch_transition_speed * delta)

# Headbob effect.
func _headbob(time) -> Vector3:
	var pos = Vector3(0, 0, 0)
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

#this emits a player hit signal which can trigger a reaction, 3rd line cretes a knockback when the player is hit
func hit(dir):
	emit_signal("player_hit")
	velocity += dir * HIT_STAGGER
