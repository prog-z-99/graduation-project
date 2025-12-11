extends CharacterBody3D
## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we freefly?
@export var freefly_speed : float = 25.0
## Movement variables
@export var air_accel: float = 3.0
## Acceleration.
@export var ground_accel : float = 15.0
## Dash speed
@export var dashSpeed : float = 15
## Dash duration
@export var dashDur : float = 0.5
## Dash counter
@export var dashCount : int = 2
## Wallrun timeout
@export var wallrunTimeout : float = 0.2

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to dash
@export var input_dash : String = "dash"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
## dashing state
var dashing : bool = false

var move_dir := Vector3.ZERO
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
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _handleGroundPhysics() -> void:
	if move_dir:
		velocity.x = move_speed * move_dir.x
		velocity.z = move_speed * move_dir.z
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	
func handleAirPhysics() -> void:
	has_gravity = true
	
func wallrun() -> void:
	wallNormal = get_slide_collision(0).get_normal()
	await get_tree().create_timer(wallrunTimeout).timeout
	has_gravity = false
	velocity.y = 0
	print_debug(wallNormal)

func dash() -> void:
	dashCount = dashCount - 1
	dashing = true
	velocity.y = 0
	has_gravity = false
	velocity.x = dashSpeed * move_dir.x
	velocity.z = dashSpeed * move_dir.z
	#TODO: figure out how to add last input dashing? or just forward dashing when no other inputs are given.
	#if move_dir.x == (0.0) && move_dir.y ==(0,0):
	await get_tree().create_timer(dashDur).timeout
	velocity.x = move_toward(velocity.x, move_speed * move_dir.x, 1)
	velocity.z = move_toward(velocity.z, move_speed * move_dir.z, 1)
	dashing = false
	dashCount = 2
	has_gravity = true


func _physics_process(delta: float) -> void:
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	move_speed = base_speed

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var lerpState
		if is_on_floor():
			lerpState = ground_accel
		else: lerpState = air_accel
		move_dir = lerp(move_dir, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*lerpState)
		
	else:
		velocity.x = 0
		velocity.y = 0
	
	# Use velocity to actually move
	#if is_on_floor():
	if Input.is_action_just_pressed(input_dash) && dashCount > 0:
		dash()
		
	if dashing: 
		pass
	elif Input.is_action_pressed(input_forward) && not is_on_floor() && is_on_wall():
		wallrun()
	elif not is_on_floor():
		handleAirPhysics();
		_handleGroundPhysics();
	else: _handleGroundPhysics();
	
	#else _handleAirPhysics():
	move_and_slide()


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-90), deg_to_rad(90))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


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
