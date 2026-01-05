# res://sun.gd
extends Node3D
class_name SunBody

# Sun data (km)
@export var radius_km: float = 696_340.0
@export var solar_position_km: Vector3 = Vector3.ZERO

@export var ship_path: NodePath

@onready var light: DirectionalLight3D = $DirectionalLight3D

func _process(_delta: float) -> void:
	var ship := _resolve_ship()
	if ship == null or light == null:
		return

	var rays_dir := (ship.global_position - global_position).normalized()
	if rays_dir == Vector3.ZERO:
		return

	# DirectionalLight shines along its -Z axis; rotate so -Z points along rays_dir
	light.global_position = global_position
	light.look_at(light.global_position + rays_dir, Vector3.UP)

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
	
