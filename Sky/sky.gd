# res://sky.gd
extends Node3D

# Bodies are rendered at this fixed distance from the ship/camera (meters; Godot units)
@export var visualization_distance_m: float = 1000.0

# 1.0 = physically correct angular sizes. >1 exaggerates (optional).
@export var angular_exaggeration: float = 1.0

# Path to your Ship node (the cube at 0,0,0 in Godot).
@export var ship_path: NodePath = ^"../Ship"

# Update every frame (good while tweaking inspector values)
@export var live_update: bool = true

# If bodies are nested under sub-nodes, this will still find them
@export var search_recursively: bool = true

var ship: Node3D

func _ready() -> void:
	_sanitize_exports()
	ship = _resolve_ship()
	_update_all()

func _process(_delta: float) -> void:
	if live_update:
		if ship == null:
			ship = _resolve_ship()
		_update_all()

func _sanitize_exports() -> void:
	if visualization_distance_m == null:
		visualization_distance_m = 1000.0
	if angular_exaggeration == null:
		angular_exaggeration = 1.0
	if ship_path == null or ship_path.is_empty():
		ship_path = ^"../Ship"
	if live_update == null:
		live_update = true
	if search_recursively == null:
		search_recursively = true

func _resolve_ship() -> Node3D:
	if ship_path != null and not ship_path.is_empty():
		var n := get_node_or_null(ship_path)
		if n is Node3D:
			return n as Node3D

	var root := get_tree().current_scene
	if root:
		var fallback := root.find_child("Ship", true, false)
		if fallback is Node3D:
			return fallback as Node3D

	return null

func _update_all() -> void:
	if ship == null:
		return

	var ship_solar_km_v: Variant = _get_solar_km(ship)
	# If ship solar is not set / missing, nothing to do
	if ship_solar_km_v == null:
		return
	var ship_solar_km: Vector3 = ship_solar_km_v

	var bodies: Array[Node3D] = []
	if search_recursively:
		_collect_bodies_recursive(self, bodies)
	else:
		for c in get_children():
			if c is Node3D and _is_body(c):
				bodies.append(c)
	
	for b in bodies:
		_place_body(b, ship_solar_km)
	

func _collect_bodies_recursive(node: Node, out: Array[Node3D]) -> void:
	for c in node.get_children():
		if c is Node3D and _is_body(c):
			out.append(c)
		_collect_bodies_recursive(c, out)

func _is_body(n: Node3D) -> bool:
	# A "body" is anything that has radius + solar position (either naming convention)
	return _get_radius_km(n) != null and _get_solar_km(n) != null

func _place_body(body: Node3D, ship_solar_km: Vector3) -> void:
	var body_solar_km_v: Variant = _get_solar_km(body)
	var radius_km_v: Variant = _get_radius_km(body)
	if body_solar_km_v == null or radius_km_v == null:
		return

	var body_solar_km: Vector3 = body_solar_km_v
	var radius_km: float = float(radius_km_v)

	var rel_km: Vector3 = body_solar_km - ship_solar_km
	var dist_km: float = rel_km.length()
	if dist_km <= 0.0:
		return

	var dir := rel_km.normalized()

	# Place the visual body at a fixed distance from the ship
	body.global_position = ship.global_position + dir * visualization_distance_m

	# Preserve angular size:
	# theta = atan(radius_km / dist_km)  (angular radius)
	# visible radius at D_vis: r_vis_m = D_vis_m * tan(theta)
	var theta := atan(radius_km / dist_km) * angular_exaggeration
	var r_vis_m := visualization_distance_m * tan(theta)

	# Scale mesh (expects a MeshInstance3D child named "MeshInstance3D")
	var mesh_i: MeshInstance3D = body.get_node_or_null("MeshInstance3D")
	if mesh_i and mesh_i.mesh is SphereMesh:
		var base_radius := (mesh_i.mesh as SphereMesh).radius
		if base_radius <= 0.0:
			base_radius = 1.0
		mesh_i.scale = Vector3.ONE * (r_vis_m / base_radius)

# --- Compatibility helpers (support both old/new property names) ---

func _get_radius_km(o: Object) -> Variant:
	if _has_prop(o, "radius_km"):
		return float(o.get("radius_km"))
	if _has_prop(o, "radius"):
		return float(o.get("radius"))
	return null

func _get_solar_km(o: Object) -> Variant:
	if _has_prop(o, "solar_position_km"):
		return o.get("solar_position_km")
	if _has_prop(o, "solarPosition"):
		return o.get("solarPosition")
	return null

func _has_prop(obj: Object, prop_name: String) -> bool:
	for p in obj.get_property_list():
		if p.name == prop_name:
			return true
	return false
