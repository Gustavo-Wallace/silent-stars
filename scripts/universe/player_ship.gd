class_name PlayerShip
extends Node2D
## Native-drawn vessel with a short world-space trail.

signal arrived(system_id: int)

@export var travel_speed := 480.0

var destination_id: int = 0
var target_position := Vector2.ZERO
var is_traveling := false
var heading := 0.0
var trail: Array[Vector2] = []


func setup_initial(start_position: Vector2, system_id: int) -> void:
	position = start_position
	destination_id = system_id
	target_position = start_position
	trail.clear()
	queue_redraw()


func travel_to(destination: Vector2, system_id: int) -> void:
	target_position = destination
	destination_id = system_id
	is_traveling = true
	queue_redraw()


func _process(delta: float) -> void:
	if not is_traveling:
		return
	var direction := position.direction_to(target_position)
	if direction.length_squared() > 0.0:
		heading = direction.angle()
	position = position.move_toward(target_position, travel_speed * delta)
	trail.push_front(position)
	if trail.size() > 12:
		trail.pop_back()
	if position.distance_to(target_position) < 0.5:
		position = target_position
		is_traveling = false
		trail.clear()
		arrived.emit(destination_id)
	queue_redraw()


func _draw() -> void:
	for index in range(1, trail.size()):
		var alpha := 0.28 * (1.0 - float(index) / 12.0)
		draw_line(trail[index - 1] - position, trail[index] - position, Color(0.38, 0.82, 1.0, alpha), 1.1, true)
	draw_circle(Vector2.ZERO, 11.0, Color(0.3, 0.78, 1.0, 0.08))
	draw_circle(Vector2.ZERO, 5.8, Color(0.38, 0.84, 1.0, 0.18))
	var hull := PackedVector2Array([Vector2(9, 0), Vector2(-6, 4.8), Vector2(-3.5, 0), Vector2(-6, -4.8)])
	for index in hull.size():
		hull[index] = hull[index].rotated(heading)
	draw_colored_polygon(hull, Color(0.66, 0.94, 1.0, 0.96))

