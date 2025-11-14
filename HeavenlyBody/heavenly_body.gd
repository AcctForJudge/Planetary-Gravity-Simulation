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
@export_category("Velocity")
@export var initial_velocity := Vector3.ZERO:
	set(value):
		initial_velocity = value
		values_changed()
@export_category("Terrain")
@export var is_star := false
@export var fnl := FastNoiseLite.new():
	set(value):
		fnl = value
		#generate()
@export var height_scale := 5.0
var velocity := Vector3.ZERO
var mdt = MeshDataTool.new()

var collision_shape_3d := CollisionShape3D.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var col := StaticBody3D.new()
	add_child(col)
	col.add_child(collision_shape_3d)

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
	
func generate():
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(0))
	mdt.create_from_surface(arr_mesh, 0)
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i).normalized()
		# Push out vertex by noise.
		vertex = vertex * (pow(2, fnl.get_noise_3dv(vertex) * height_scale) + radius) 
		mdt.set_vertex(i, vertex)

	# Calculate vertex normals, face-by-face.
	for i in range(mdt.get_face_count()):
		# Get the index in the vertex array.
		var a = mdt.get_face_vertex(i, 0)
		var b = mdt.get_face_vertex(i, 1)
		var c = mdt.get_face_vertex(i, 2)
		# Get vertex position using vertex index.
		var ap = mdt.get_vertex(a)
		var bp = mdt.get_vertex(b)
		var cp = mdt.get_vertex(c)
		# Calculate face normal.
		var n = (bp - cp).cross(ap - bp).normalized()
		# Add face normal to current vertex normal.
		# This will not result in perfect normals, but it will be close.
		mdt.set_vertex_normal(a, n + mdt.get_vertex_normal(a))
		mdt.set_vertex_normal(b, n + mdt.get_vertex_normal(b))
		mdt.set_vertex_normal(c, n + mdt.get_vertex_normal(c))

	# Run through vertices one last time to normalize normals and
	# set color to normal.
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex_normal(i).normalized()
		mdt.set_vertex_normal(i, v)
		mdt.set_vertex_color(i, Color(v.x, v.y, v.z))
	arr_mesh.clear_surfaces()
	mdt.commit_to_surface(arr_mesh)
	mesh = arr_mesh
	collision_shape_3d.shape = mesh.create_trimesh_shape()
	
func values_changed():
	if mesh is SphereMesh:
		mesh.radius = radius
		mesh.height = radius * 2
	velocity = initial_velocity
	collision_shape_3d.shape = SphereShape3D.new()
	collision_shape_3d.shape.radius = radius
	
