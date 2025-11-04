@tool
class_name Universe
extends Node3D

const G = 6.67e-11


@export_category("Reference")
@export var relative_to_body: bool = false
@export var central_body: HeavenlyBody

@export_category("Orbit Paths")
## number of time steps in the future to calculate the paths
@export_range(1, 200, 1, "or_greater") var num_steps := 200
## affects actual simulation as well, not just for calculating paths
@export_range(0.01, 0.1, 0.01) var time_step : float = 0.01

@export var show_past_path := false

var all_bodies : Array[HeavenlyBody]
var play := false
var future_orbits_shown := true
## like draw points but for past paths
var body_positions: Array

@onready var heavenly_bodies_container: Node3D = $HeavenlyBodies
@onready var orbits: Node3D = $Orbits
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in heavenly_bodies_container.get_children():
		if child is HeavenlyBody:
			all_bodies.append(child)
			body_positions.append([])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if !play:
		hide_orbits()
		if future_orbits_shown:
			calculate_and_show_orbits()
	else:
		if show_past_path:
			show_past_orbits()
		else:
			if future_orbits_shown:
				hide_orbits()
				calculate_and_show_orbits()
			else:
				hide_orbits()
		
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("play"):
		play = !play
	if Input.is_action_just_pressed("hide"):
		hide_orbits()
		future_orbits_shown = !future_orbits_shown
	
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
	var orbit := Path3D.new()
	var curve := Curve3D.new()
	
	# some error occurs in the c++ source code when two successive points are the same
	var prev_pos: Vector3 = Vector3.ZERO
	for pos:Vector3 in draw_points[i]:
		if !pos.is_equal_approx(prev_pos):
			curve.add_point(pos)
		prev_pos = pos
	orbit.curve = curve
	orbits.add_child(orbit)
	
	var csg_polygon := CSGPolygon3D.new()
	var points := PackedVector2Array()

	points.append(Vector2.ZERO)
	points.append( Vector2(0, 0.1))
	points.append(Vector2(0.1, 0.1))
	points.append(Vector2(0.1, 0))
	csg_polygon.polygon = points

	csg_polygon.mode = CSGPolygon3D.MODE_PATH
	csg_polygon.path_node = orbit.get_path()
	orbit.add_child(csg_polygon)

func hide_orbits():
	for child in orbits.get_children():
			child.queue_free()

func calc_acc(i: int, virtual_bodies: Array[VirtualBody]):
	var acc := Vector3.ZERO
	for j in virtual_bodies.size():
		if i != j:
			var dir := virtual_bodies[i].vb_pos.direction_to(virtual_bodies[j].vb_pos)
			var sqr_dist := virtual_bodies[i].vb_pos.distance_squared_to(virtual_bodies[j].vb_pos)
			var force := dir * G * virtual_bodies[j].vb_mass / sqr_dist # no need for i's mass cuz a = f/m
			acc += force
	return acc

class VirtualBody:
	# properties
	var vb_mass: float
	var vb_pos: Vector3
	var vb_vel: Vector3
	
	func _init(body: HeavenlyBody):
		vb_mass = body.mass
		vb_pos = body.position
		vb_vel = body.velocity
