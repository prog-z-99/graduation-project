extends CharacterBody3D

enum States { IDLE, DASH, WALLRUN, FREEFLY }
var state: States = States.IDLE

## Can we move around?
@export var can_move: bool = true
## Are we affected by gravity?
@export var has_gravity: bool = true
## Can we press to jump?
@export var can_jump: bool = true
## Can we press to enter freefly mode (noclip)?
@export var can_freefly: bool = false
@export var camera_mode: bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed: float = 0.002
## Normal speed.
@export var base_speed: float = 7.0
## Speed of jump.
@export var jump_velocity: float = 4.5
@export var jump_count: int = 2
@export var max_jump_count: int = 2
## Max fall speed
@export var terminal_velocity: float = -10
## How fast do we freefly?
@export var freefly_speed: float = 25.0
## Movement variables
@export var air_accel: float = 3.0
## Acceleration.
@export var ground_accel: float = 15.0
## Dash speed
@export var dashSpeed: float = 15
## Dash duration
@export var dashDur: float = 0.5
## Dash counter
@export var dashCount: int = 2
@export var maxDashCount: int = 2
## Wallrun timeout
@export var wallrunTimeout: float = 0.2

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left: String = "ui_left"
## Name of Input Action to move Right.
@export var input_right: String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward: String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back: String = "ui_down"
## Name of Input Action to dash
@export var input_dash: String = "dash"
## Name of Input Action to Jump.
@export var input_jump: String = "ui_accept"
## Name of Input Action to toggle freefly mode.
@export var input_freefly: String = "freefly"
## Name of Input Action to toggle camera mode
@export var input_toggle_camera_mode: String = "toggle_camera"
@export var camera: Camera3D

var mouse_captured: bool = false
var look_rotation: Vector2
var move_speed: float = 0.0

var move_dir := Vector3.ZERO
var wishDir := Vector3.ZERO
var last_move_dir := Vector3(1, 0, 0)
var wallNormal := Vector3.ZERO
## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider


func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x


func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()

	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)

	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not state == States.FREEFLY:
			enable_freefly()
		else:
			disable_freefly()
	if Input.is_action_just_pressed("toggle_camera"):
		camera.position = Vector3(0, 0, 0) if camera_mode else Vector3(0, 0, 4)
		camera_mode = !camera_mode


func handlePhysics() -> void:
	if move_dir:
		velocity.x = move_speed * move_dir.x
		velocity.z = move_speed * move_dir.z


func _handleGroundPhysics() -> void:
	dashCount = maxDashCount
	jump_count = max_jump_count
	if !move_dir:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)


func handleAirPhysics() -> void:
	has_gravity = true


func jump() -> void:
	velocity.y = jump_velocity
	jump_count -= 1


func wallrun() -> void:
	var wallNormal = get_slide_collision(0).get_normal()
	var rightVector = wallNormal.cross(Vector3i(0, 1, 0))
	var cameraVector = Vector3(sin(rotation.y), 0, cos(rotation.y))
	move_dir = rightVector if cameraVector.dot(rightVector) < 0 else wallNormal.cross(Vector3i(0, -1, 0))
	#await get_tree().create_timer(wallrunTimeout).timeout
	has_gravity = false
	velocity.y = 0
	if Input.is_action_just_pressed(input_jump):
		velocity.y = jump_velocity
		velocity.x = wallNormal.x * jump_velocity
		velocity.z = wallNormal.z * jump_velocity


func dash() -> void:
	dashCount -= 1
	velocity.y = 0
	has_gravity = false

	if (wishDir.length() < 1):
		wishDir = (transform.basis * Vector3(0, 0, -1)).normalized()

	print_debug(wishDir)
	velocity.x = dashSpeed * wishDir.x
	velocity.z = dashSpeed * wishDir.z
	state = States.DASH
	#TODO: figure out how to add last input dashing? or just forward dashing when no other inputs are given.
	#if move_dir.x == (0.0) && move_dir.y ==(0,0):
	await get_tree().create_timer(dashDur).timeout
	velocity.x = move_toward(velocity.x, move_speed * move_dir.x, 1)
	velocity.z = move_toward(velocity.z, move_speed * move_dir.z, 1)
	state = States.IDLE
	has_gravity = true


func _physics_process(delta: float) -> void:
	# If freeflying, handle freefly and nothing else
	if can_freefly and state == States.FREEFLY:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return

	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			var new_velocity = velocity + get_gravity() * delta
			if (new_velocity.y < terminal_velocity):
				velocity = Vector3(new_velocity.x, terminal_velocity, new_velocity.z)
			else:
				velocity = new_velocity

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and (is_on_floor() or not is_on_wall()):
			jump()

	move_speed = base_speed

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		wishDir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var lerpState
		if is_on_floor():
			lerpState = ground_accel
		else:
			lerpState = air_accel
		move_dir = lerp(move_dir, wishDir, delta * lerpState)

	else:
		velocity.x = 0
		velocity.y = 0

	# Use velocity to actually move
	#if is_on_floor():

	match state:
		States.WALLRUN:
			wallrun()
		States.IDLE:
			if not is_on_floor():
				handleAirPhysics()
			else:
				_handleGroundPhysics()
			handlePhysics()
			if Input.is_action_just_pressed(input_dash) && dashCount > 0:
				dash()
		States.DASH:
			pass

	#else _handleAirPhysics():
	move_and_slide()


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input: Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-90), deg_to_rad(90))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	state = States.FREEFLY
	velocity = Vector3.ZERO


func disable_freefly():
	collider.disabled = false
	state = States.IDLE


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	#if can_move and not InputMap.has_action(input_dash):
	#push_error("Dashing disabled. No InputAction found for input_dash: " + input_dash)
	#can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
