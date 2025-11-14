#@tool
extends CharacterBody3D

@export_category("speed")
@export_range(0.1, 15, 0.1, "or_greater") var move_speed := 1.0
@export var mouse_sense := 0.005

@export_category("Bodies")
@export var body_containers: Node3D
@export var universe: Universe

var bodies: Array
var look_rotation := Vector2.ZERO 
var mouse_captured := true
var velocity_from_gravity := Vector3.ZERO
var velocity_from_movement := Vector3.ZERO
var main_body : HeavenlyBody
var should_add_gravity := true

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var col: CollisionShape3D = $CollisionShape3D
@onready var cam: Node3D = $Cam
@onready var head: Node3D = $Cam/Head
@onready var camera_3d: Camera3D = $Cam/Head/Camera3D

func _ready() -> void:
	look_rotation.y = cam.rotation.y
	look_rotation.x = head.rotation.x
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	bodies = body_containers.get_children()
	
func _unhandled_input(event: InputEvent) -> void:
	if universe.viewing_from != Universe.Camera.PLAYER:
		return
	if event is InputEventMouseMotion and mouse_captured:
		rotate_look(event.relative)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_physical_key_pressed(KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false

func _physics_process(_delta: float) -> void:
	handle_movement()
	if universe.play:
		var strongest_force := Vector3.ZERO
		for body in bodies:
			var sqr_dist = position.distance_squared_to(body.position)
			var dir = position.direction_to(body.position)
			var force: Vector3 = dir * Universe.G * body.mass / sqr_dist # force = acc cuz mass cancel
			if force.length_squared() > strongest_force.length_squared():
				strongest_force = force
				main_body = body

		if strongest_force.length_squared() > 1 or main_body.position.distance_squared_to(position) < pow(main_body.radius * 1.5, 2):
			if velocity_from_gravity.length_squared() < 10:
				velocity_from_gravity += strongest_force
			
			var gravity_up = -strongest_force.normalized()
			basis = align_up(basis, gravity_up)
			
		else:
			velocity_from_gravity = Vector3.ZERO
			var gravity_up = position.direction_to(universe.space_ship.position)
			basis = align_up(basis, gravity_up)
	velocity = velocity_from_gravity + velocity_from_movement + universe.space_ship.velocity
	move_and_slide()
	
func handle_movement():
	if universe.viewing_from != Universe.Camera.PLAYER:
		return

	
	var y = Input.get_axis("down", "up")
	
	velocity_from_movement.y = y * move_speed

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity_from_movement.x = direction.x * move_speed
		velocity_from_movement.z = direction.z * move_speed
	else:
		velocity_from_movement.x = move_toward(velocity_from_movement.x, 0, move_speed)
		velocity_from_movement.z = move_toward(velocity_from_movement.z, 0, move_speed)

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * mouse_sense
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	
	look_rotation.y -= rot_input.x * mouse_sense

	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func align_up(node_basis: Basis, normal: Vector3) -> Basis:
	var result := Basis()
	var s = node_basis.get_scale().abs()
	
	result.x = normal.cross(node_basis.z)
	result.y = normal
	result.z = node_basis.x.cross(normal)
	
	result = result.orthonormalized()
	result.x *= s.x
	result.y *= s.y
	result.z *= s.z
	return result
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
