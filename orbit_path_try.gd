@tool
class_name OrbitPathMesh
extends Node3D

	

func generate_mesh(path_3d: Path3D, thickness:= 0.1) -> ArrayMesh:
	var st := SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var curve := path_3d.curve
	for i in curve.point_count - 1:
		var p1 = curve.get_point_position(i)
		var p2 = curve.get_point_position(i + 1)
		
		var i00 = p1 + Vector3(-1, -1, 0) * thickness
		var i01 = p1 + Vector3(-1, 1, 0) * thickness
		var i02 = p1 + Vector3(1, -1, 0) * thickness
		var i03 = p1 + Vector3(1, 1, 0) * thickness
		var i10 = p2 + Vector3(-1, -1, 0) * thickness
		var i11 = p2 + Vector3(-1, 1, 0) * thickness
		var i12 = p2 + Vector3(1, -1, 0) * thickness
		var i13 = p2 + Vector3(1, 1, 0) * thickness

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
	st.index()
	
	var mesh := st.commit()
	return mesh
	
