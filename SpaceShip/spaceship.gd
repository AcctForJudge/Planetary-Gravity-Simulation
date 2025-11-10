#@tool
extends CharacterBody3D

@export_category("speed")
@export_range(0.1, 15, 0.1, "or_greater") var speed := 1.0
@export_range(0.1, 2, 0.1) var rot_speed := 1.0
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
var yaw: float
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var col: CollisionShape3D = $CollisionShape3D
@onready var cam: Node3D = $Cam
@onready var head: Node3D = $Cam/Head

func _ready() -> void:
	yaw = rotation_degrees.y
	look_rotation.y = cam.rotation.y
	look_rotation.x = head.rotation.x
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	bodies = body_containers.get_children()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		rotate_look(event.relative)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_physical_key_pressed(KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	if universe.play:
		var strongest_force := Vector3.ZERO
		for body in bodies:
			var sqr_dist = position.distance_squared_to(body.position)
			var dir = position.direction_to(body.position)
			var force: Vector3 = dir * Universe.G * body.mass / sqr_dist # force = acc cuz mass cancel
			if force.length_squared() > strongest_force.length_squared():
				strongest_force = force
				main_body = body

		if strongest_force.length_squared() > 1:
			if velocity_from_gravity.length_squared() < 10:
				velocity_from_gravity += strongest_force
			
			var gravity_up = -strongest_force.normalized()
			basis = align_up(basis, gravity_up)
			#mesh.basis = b
			#print("dom ",basis)
		else:
			velocity_from_gravity = Vector3.ZERO
			#print(basis)
	#if universe.play and should_add_gravity:
	velocity = velocity_from_gravity + velocity_from_movement
	#else:	
	#velocity = velocity_from_movement
	#printt(velocity_from_gravity, velocity_from_movement)
	move_and_slide()
	
func handle_movement(delta):
	var x = Input.get_axis("left", "right")
	var z = Input.get_axis("backward", "forward")
	var y = Input.get_axis("up", "down")
	
	if x > 0:
		thrust_left()
	elif x < 0:
		thrust_right()
	if y > 0:
		thrust_up()
	elif y < 0:
		thrust_down()
	if z > 0:
		thrust_forwards()
	elif z < 0:
		thrust_backwards()
	velocity_from_movement.x = clamp(velocity_from_movement.x, -100, 100)
	velocity_from_movement.y = clamp(velocity_from_movement.y, -1000, 100)
	velocity_from_movement.z = clamp(velocity_from_movement.z, -100, 100)
	if !(x or y or z):
		velocity_from_movement = lerp(velocity_from_movement, Vector3.ZERO, delta * 2)
	
func thrust_forwards():
	velocity_from_movement += speed * -transform.basis.z
func thrust_backwards():
	velocity_from_movement += speed * transform.basis.z
func thrust_left():
	yaw -= rot_speed
	rotation_degrees.y = lerp(rotation_degrees.y, yaw, rot_speed)
func thrust_right():
	yaw += rot_speed
	rotation_degrees.y = lerp(rotation_degrees.y, yaw, rot_speed)
func thrust_up():
	if velocity_from_gravity.length() > 0:
		velocity_from_movement += velocity_from_gravity.length() * -transform.basis.y
	else:
		velocity_from_movement += speed * -transform.basis.y
func thrust_down():
	velocity_from_movement += speed * transform.basis.y

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * mouse_sense
	#look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	
	look_rotation.y -= rot_input.x * mouse_sense
	look_rotation.y = clamp(look_rotation.y, deg_to_rad(-85), deg_to_rad(85))

	cam.transform.basis = Basis()
	cam.rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func sum(array: Array) -> Vector3:
	var s = Vector3.ZERO
	for i in array:
		s += i
	return s

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
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
