extends Node3D

@export var target_path: NodePath
@export var distance: float = 10.0
@export var min_distance: float = 1.0
@export var max_distance: float = 500.0
@export var rotate_speed: float = 0.01
@export var zoom_speed: float = 1.5

# Pitch limits (radians)
@export var min_pitch: float = deg_to_rad(-85.0)
@export var max_pitch: float = deg_to_rad(85.0)

@onready var cam: Camera3D = $Camera3D

var yaw: float = 0.0
var pitch: float = deg_to_rad(-15.0)

func _ready() -> void:
	# Make sure we have a camera and it's active
	if cam:
		cam.current = true
	_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	# Hold Right Mouse Button to orbit
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * rotate_speed
		pitch -= event.relative.y * rotate_speed
		pitch = clamp(pitch, min_pitch, max_pitch)
		_update_camera()

	# Mouse wheel zoom
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - zoom_speed, min_distance, max_distance)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + zoom_speed, min_distance, max_distance)
			_update_camera()

func _update_camera() -> void:
	var target := get_node_or_null(target_path) as Node3D
	if target == null or cam == null:
		return

	# Rig follows the target position (ship stays at origin anyway)
	global_position = target.global_position

	# Build orbit rotation (yaw around Y, pitch around X)
	var rot := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)

	# Camera offset: place behind on +Z, then rotate
	var offset := rot * Vector3(0, 0, distance)

	cam.global_position = global_position + offset
	cam.look_at(global_position, Vector3.UP)
