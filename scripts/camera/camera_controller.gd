class_name CameraController
extends Camera2D
## Independent navigation controller; map gameplay never needs to know camera details.

@export var min_zoom := 0.48
@export var max_zoom := 2.35
@export var zoom_step := 0.12
@export var zoom_smoothing := 9.0

var target_zoom := 1.0
var is_dragging := false


func _ready() -> void:
	target_zoom = zoom.x


func _process(delta: float) -> void:
	var smoothed := lerpf(zoom.x, target_zoom, minf(delta * zoom_smoothing, 1.0))
	zoom = Vector2.ONE * smoothed


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_set_zoom(target_zoom * (1.0 + zoom_step))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_set_zoom(target_zoom * (1.0 - zoom_step))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and is_dragging:
		# Camera movement is inverted to make the world feel grabbed by the cursor.
		position -= event.relative / zoom.x
		get_viewport().set_input_as_handled()


func _set_zoom(next_zoom: float) -> void:
	target_zoom = clampf(next_zoom, min_zoom, max_zoom)
