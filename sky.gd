extends Node3D

@export var visualization_distance_m: float = 1000.0
@export var live_update: bool = true

# Use this (1 = physical, 10 = 10x bigger angular diameter, etc.)
@export var angular_exaggeration: float = 1.0

# If true, we create a tiny marker so you can tell where the object is even if the mesh is missing/material is dark
@export var debug_markers: bool = true
@export var debug_marker_size_m: float = 1.0

var _camera: Camera3D
var _markers := {} # NodePath -> MeshInstance3D

func _ready() -> void:
	_camera = _get_camera()
	_update_all()

func _process(_delta: float) -> void:
	if live_update:
		_camera = _get_camera()
		_update_all()

func _get_camera() -> Camera3D:
	# Best: active viewport camera
	var cam := get_viewport().get_camera_3d()
	if cam:
		return cam

	# Fallback: find any Camera3D in the current scene
	var found := get_tree().current_scene.find_child("", true, false)
	# (not super important; normally the viewport camera exists)
	return cam

func _update_all() -> void:
	if _camera == null:
		return

	for child in get_children():
		if child is Node3D and _has_props(child):
			_place_body(child as Node3D)

func _has_props(n: Node) -> bool:
	return _has_prop(n, "radius") and _has_prop(n, "distance") and _has_prop(n, "angle")

func _has_prop(obj: Object, name: String) -> bool:
	for p in obj.get_property_list():
		if p.name == name:
			return true
	return false

func _place_body(body: Node3D) -> void:
	var R: float = float(body.get("radius"))     # meters
	var D: float = float(body.get("distance"))   # meters
	var a_deg: float = float(body.get("angle"))  # degrees

	if D <= 0.0:
		return

	# Direction: 0° = horizon forward, 90° = straight up
	var a := deg_to_rad(a_deg)
	var forward := -_camera.global_transform.basis.z.normalized()
	var up := _camera.global_transform.basis.y.normalized()
	var dir := (forward * cos(a) + up * sin(a)).normalized()

	# Place the body at fixed visualization distance
	body.global_position = _camera.global_position + dir * visualization_distance_m

	# Correct angular radius: theta = atan(R/D)
	# Apply angular exaggeration by scaling theta (keeps geometry consistent)
	var theta := atan(R / D) * angular_exaggeration
	var R_vis := visualization_distance_m * tan(theta)

	# Scale MeshInstance3D child if present
	var mesh_i: MeshInstance3D = body.get_node_or_null("MeshInstance3D")
	if mesh_i:
		var base_radius := 1.0
		if mesh_i.mesh is SphereMesh:
			base_radius = (mesh_i.mesh as SphereMesh).radius
		mesh_i.scale = Vector3.ONE * (R_vis / base_radius)

	# Debug marker so you can confirm placement even if the mesh isn't set up
	if debug_markers:
		_ensure_marker(body)
		var m: MeshInstance3D = _markers[body.get_path()]
		m.global_position = body.global_position
		m.scale = Vector3.ONE * debug_marker_size_m

func _ensure_marker(body: Node3D) -> void:
	var key := body.get_path()
	if _markers.has(key):
		return

	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	mi.mesh = sm

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0, 0, 1) # red marker
	mi.material_override = mat

	add_child(mi)
	_markers[key] = mi
