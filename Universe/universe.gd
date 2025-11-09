@tool
class_name Universe
extends Node3D

enum Orbit {
	FUTURE,
	PAST,
	NONE,
}

const G = 1#6.67e-11

@export_category("Reference")
@export var relative_to_body: bool = false
@export var central_body: HeavenlyBody

@export_category("Orbit Paths")
## number of time steps in the future to calculate the paths
@export_range(1, 200, 1, "or_greater") var num_steps := 500
## affects actual simulation as well, not just for calculating paths
@export_range(0.01, 0.1, 0.01, "or_greater") var time_step : float = 0.01
## positions are added to array each process, but only the nth one will get added to the mesh
@export var orbit_mode: Orbit = Orbit.FUTURE

@export_category("generate_terrain Terrain")
@export var generate_terrain := false
@export var reset := false

var orbit_mesh_steps := 2
var all_bodies : Array[HeavenlyBody]
var play := false
var show_orbits := true
var last_orbit_mode : Orbit
## like draw points but for past paths
var body_positions: Array
var orbits_array: Array[Path3D]
var mesh_instances_array: Array[MeshInstance3D]
var viewport : Viewport
@onready var heavenly_bodies_container: Node3D = $HeavenlyBodies
@onready var orbits: Node3D = $Orbits

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in heavenly_bodies_container.get_children():
		if child is HeavenlyBody:
			var orbit := Path3D.new()
			var mesh_instance := MeshInstance3D.new()
			orbits.add_child(orbit)
			var material := StandardMaterial3D.new()
			material.emission_enabled = true
			material.emission_energy_multiplier = 1.5
			material.emission = Color.WHEAT
			mesh_instance.material_override = material
			orbit.add_child(mesh_instance)
			orbits_array.append(orbit)
			mesh_instances_array.append(mesh_instance)
			all_bodies.append(child)
			body_positions.append([])
	viewport = get_viewport()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if show_orbits:
		match orbit_mode:
			Orbit.FUTURE:
				if play:
					print("Future Mode is only for Editor")
					orbit_mode = Orbit.NONE
				else:
					hide_orbits()
					calculate_and_show_orbits()
					last_orbit_mode = Orbit.FUTURE
			Orbit.NONE:
				hide_orbits()
	if reset:
		for body in heavenly_bodies_container.get_children():
			body.mesh = SphereMesh.new()
			body.mesh.radius = body.radius
			body.mesh.height = body.radius * 2
			body.collision_shape_3d.shape = SphereShape3D.new()
			body.collision_shape_3d.shape.radius = body.radius
		reset = false
		
	if generate_terrain:
		for body in heavenly_bodies_container.get_children():
			if !body.is_star:
				body.generate()
		generate_terrain = false
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("play"):
		play = !play
	if Input.is_action_just_pressed("hide"):
		hide_orbits()
		show_orbits = !show_orbits
	if Input.is_action_just_pressed("view_mode"):
		match viewport.debug_draw:
			0:
				viewport.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
			4:
				viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED
func _physics_process(_delta: float) -> void:
	if play:
		for body in all_bodies:
			body.update_velocity(all_bodies, time_step)
		for i in all_bodies.size():
			var body = all_bodies[i]
			body.update_position(time_step)
			if body_positions[i].size() > 0:
				if body_positions[i][-1] != body.position:
					body_positions[i].append(body.position)
			else:
				body_positions[i].append(body.position)

			while body_positions[i].size() > num_steps:
				body_positions[i].pop_front()
		if show_orbits:
			if orbit_mode == Orbit.PAST:
				if last_orbit_mode == Orbit.FUTURE:
					hide_orbits()
				show_past_orbits()
				
func show_past_orbits():
	for i in body_positions.size():
		draw_orbits(i, body_positions)

func calculate_and_show_orbits():
	var heavenly_bodies = all_bodies
	
	var virtual_bodies: Array[VirtualBody] = []
	virtual_bodies.resize(heavenly_bodies.size())
	
	## 2d array of vec3 positions, one dimension for the body, other dimension for the time step
	var draw_points: Array = [] 
	draw_points.resize(heavenly_bodies.size())
	
	var reference_frame_index = 0
	var reference_body_init_pos := Vector3.ZERO
	
	for i in virtual_bodies.size():
		virtual_bodies[i] = VirtualBody.new(heavenly_bodies[i])
		draw_points[i] = []
		draw_points[i].resize(num_steps)
		if heavenly_bodies[i] == central_body and relative_to_body:
			reference_frame_index = i
			reference_body_init_pos = virtual_bodies[i].vb_pos
			
	for step in num_steps:
		var reference_body_position: Vector3 
		if relative_to_body:
			reference_body_position = virtual_bodies[reference_frame_index].vb_pos 
		else:
			reference_body_position = Vector3.ZERO
		
		for i in virtual_bodies.size():
			virtual_bodies[i].vb_vel += calc_acc(i, virtual_bodies) * time_step
			
		for i in virtual_bodies.size():
			var new_pos := virtual_bodies[i].vb_pos + virtual_bodies[i].vb_vel * time_step
			virtual_bodies[i].vb_pos = new_pos
			if relative_to_body:
				var reference_point_offset = reference_body_position - reference_body_init_pos
				new_pos -= reference_point_offset
			if relative_to_body and i == reference_frame_index:
				new_pos = reference_body_init_pos
			
			draw_points[i][step] = new_pos
			
	
	for i in virtual_bodies.size():
		draw_orbits(i, draw_points)

func draw_orbits(i: int, draw_points: Array):
	# some error occurs in the c++ source code when two successive points are the same
	#var dist = $Camera.position.distance_squared_to(orbits_array[i].position)
	#if dist < 2000:
		#orbit_mesh_steps = 2
	#elif dist < 4000:
		#orbit_mesh_steps = 3
	#else:
		#orbit_mesh_steps = 4
			
	var prev_pos: Vector3 = Vector3.ZERO
	var curve := Curve3D.new()
	var c = 0
	for pos: Vector3 in draw_points[i]:
		if !pos.is_equal_approx(prev_pos) and c % 2 == 0:
			curve.add_point(pos)
		c += 1
		prev_pos = pos
	orbits_array[i].curve = curve
	mesh_instances_array[i].mesh = generate_mesh(orbits_array[i], 0.3)
		
func hide_orbits():
	for i in orbits.get_child_count():
		mesh_instances_array[i].mesh = null
		

func calc_acc(i: int, virtual_bodies: Array[VirtualBody]):
	var acc := Vector3.ZERO
	for j in virtual_bodies.size():
		if i != j:
			var dir := virtual_bodies[i].vb_pos.direction_to(virtual_bodies[j].vb_pos)
			var sqr_dist := virtual_bodies[i].vb_pos.distance_squared_to(virtual_bodies[j].vb_pos)
			var force := dir * G * virtual_bodies[j].vb_mass / sqr_dist # no need for i's mass cuz a = f/m
			acc += force
	return acc
	
func generate_mesh(path_3d: Path3D, thickness:= 0.1) -> ArrayMesh:
	var st := SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var curve := path_3d.curve
	var v1 := Vector3(-1, -1, 0) * thickness
	var v2 := Vector3(-1, 1, 0) * thickness
	var v3 := Vector3(1, -1, 0) * thickness
	var v4 := Vector3(1, 1, 0) * thickness
	for i in curve.point_count - 1:
		var p1 = curve.get_point_position(i)
		var p2 = curve.get_point_position(i + 1)
		
		var i00 = p1 + v1
		var i01 = p1 + v2
		var i02 = p1 + v3
		var i03 = p1 + v4
		var i10 = p2 + v1
		var i11 = p2 + v2
		var i12 = p2 + v3
		var i13 = p2 + v4

		# bottom
		st.add_vertex(i10)
		st.add_vertex(i02)
		st.add_vertex(i00)
		
		st.add_vertex(i10)
		st.add_vertex(i12)
		st.add_vertex(i02)
		
		# front
		st.add_vertex(i12)
		st.add_vertex(i03)
		st.add_vertex(i02)
		
		st.add_vertex(i12)
		st.add_vertex(i13)
		st.add_vertex(i03)
		
		# top
		st.add_vertex(i13)
		st.add_vertex(i11)
		st.add_vertex(i03)
		
		st.add_vertex(i03)
		st.add_vertex(i11)
		st.add_vertex(i01)
		
		# back
		st.add_vertex(i01)
		st.add_vertex(i10)
		st.add_vertex(i00)
		
		st.add_vertex(i10)
		st.add_vertex(i01)
		st.add_vertex(i11)
	var mesh := st.commit()
	return mesh
	
class VirtualBody:
	# properties
	var vb_mass: float
	var vb_pos: Vector3
	var vb_vel: Vector3
	
	func _init(body: HeavenlyBody):
		vb_mass = body.mass
		vb_pos = body.position
		vb_vel = body.velocity
