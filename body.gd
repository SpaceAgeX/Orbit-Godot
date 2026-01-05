extends Node3D
class_name CelestialBody

# All in kilometers (as you want)
@export var radius_km: float = 1.0
@export var solar_position_km: Vector3 = Vector3.ZERO

# Optional: tag so Sky can find bodies without relying on node names
@export var is_celestial_body: bool = true

func get_solar_position_km() -> Vector3:
	return solar_position_km
