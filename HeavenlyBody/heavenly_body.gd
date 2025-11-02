@tool
class_name HeavenlyBody
extends MeshInstance3D

@export_category("Body Properties")
@export var mass := 10.0:
	set(value):
		mass = value if value > 0 else 0.0001
		values_changed()
@export var radius := 1.0:
	set(value):
		radius = value if value > 0 else 0.0001
		values_changed()
@export var initial_velocity := Vector3.ZERO:
	set(value):
		initial_velocity = value
		values_changed()

var velocity := Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func update_velocity(all_bodies: Array[HeavenlyBody], delta: float):
	for body in all_bodies:
		if body != self:
			var sqr_dist = position.distance_squared_to(body.position)
			var dir = position.direction_to(body.position)
			var force = dir * Universe.G * mass * body.mass / sqr_dist
			var acc = force / mass
			velocity += acc * delta

func update_position(delta: float):
	position += velocity * delta
	

func values_changed():
	if mesh is SphereMesh:
		mesh.radius = radius
		mesh.height = radius * 2
	velocity = initial_velocity
