class_name ProbeNode
extends Node2D

signal arrived(probe: ProbeData)

var probe: ProbeData
var target := Vector2.ZERO
var speed := 620.0
var trail: Array[Vector2] = []

func launch(data: ProbeData, origin: Vector2, destination: Vector2) -> void:
	probe = data
	position = origin
	target = destination

func _process(delta: float) -> void:
	if probe == null: return
	position = position.move_toward(target, speed * delta)
	trail.push_front(position)
	if trail.size() > 8: trail.pop_back()
	if position.distance_to(target) < 1.0:
		probe.state = "ARRIVED"
		arrived.emit(probe)
		queue_free()
	queue_redraw()

func _draw() -> void:
	for i in range(1, trail.size()):
		draw_line(trail[i - 1] - position, trail[i] - position, Color(0.68, 1, 0.72, 0.28), 1.0, true)
	draw_circle(Vector2.ZERO, 5.0, Color(0.55, 1, 0.68, 0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(5, 0), Vector2(0, 3), Vector2(-4, 0), Vector2(0, -3)]), Color(0.72, 1, 0.78, 0.96))

