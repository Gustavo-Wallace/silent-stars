class_name StarSystemNode
extends Area2D
## Native drawn representation of one star system.

signal selected(data: StarSystemData)

var data: StarSystemData
var star_color := Color(0.75, 0.88, 1.0)
var star_radius := 5.0
var pulse_phase := 0.0
var is_hovered := false


func setup(system_data: StarSystemData) -> void:
	data = system_data
	position = data.position
	star_color = _color_for_system()
	star_radius = _radius_for_system()
	queue_redraw()


func _process(delta: float) -> void:
	pulse_phase = fmod(pulse_phase + delta, TAU)
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var breathing := (sin(pulse_phase * (1.4 if data.is_home else 0.8)) + 1.0) * 0.5
	var glow_radius := star_radius * (3.7 + breathing * 0.65)
	draw_circle(Vector2.ZERO, glow_radius, Color(star_color, 0.045))
	draw_circle(Vector2.ZERO, star_radius * (1.75 + breathing * 0.12), Color(star_color, 0.16))
	draw_circle(Vector2.ZERO, star_radius, star_color)
	draw_circle(Vector2.ZERO, maxf(1.3, star_radius * 0.38), Color(0.92, 0.98, 1.0, 0.96))

	if data.is_home:
		var ring_radius := 18.0 + sin(pulse_phase * 1.7) * 1.4
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, Color(0.38, 0.88, 1.0, 0.56), 1.2, true)
		draw_line(Vector2(-27, 0), Vector2(-20, 0), Color(0.42, 0.9, 1.0, 0.46), 1.0)
		draw_line(Vector2(20, 0), Vector2(27, 0), Color(0.42, 0.9, 1.0, 0.46), 1.0)

	if is_hovered:
		draw_arc(Vector2.ZERO, star_radius + 8.0, 0.0, TAU, 32, Color(0.83, 0.96, 1.0, 0.85), 1.0, true)

	if data.is_home or is_hovered:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(star_radius + 9.0, -star_radius - 8.0), data.system_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.78, 0.9, 0.96, 0.88))


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(data)
		get_viewport().set_input_as_handled()


func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()


func _color_for_system() -> Color:
	if data.is_home:
		return Color("74d9ff")
	if data.threat_level >= 70:
		return Color("bc6eaf")
	if data.resource_potential >= 72:
		return Color("d8b66c")
	if data.system_type == "Blue Giant":
		return Color("a4c7ff")
	return Color("d7e7ef")


func _radius_for_system() -> float:
	if data.is_home:
		return 8.0
	if data.system_type == "Blue Giant":
		return 7.0
	if data.threat_level >= 70 or data.resource_potential >= 72:
		return 6.0
	return 4.0
