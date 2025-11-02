extends CharacterBody3D


@export_category("Player Controls")
@export var move_speed := 250.0
@export var vertical_move := 100.0
@export var mouse_sense := 0.005

@onready var head: Node3D = $Head
@onready var cam: Camera3D = $Head/Cam

var look_rotation := Vector2.ZERO
var mouse_captured := true

func _ready() -> void:
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		rotate_look(event.relative)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_physical_key_pressed(KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false

func _physics_process(_delta: float) -> void:

	if Input.is_action_pressed("up"):
		velocity.y = vertical_move
	if Input.is_action_pressed("down"):
		velocity.y = -vertical_move
	if !Input.is_action_pressed("up") and !Input.is_action_pressed("down"):
		velocity.y = move_toward(velocity.y, 0, move_speed)
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	move_and_slide()

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * mouse_sense
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	
	look_rotation.y -= rot_input.x * mouse_sense
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)
	
