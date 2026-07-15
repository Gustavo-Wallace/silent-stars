class_name StarSystemNode
extends Area2D
## Native drawn representation of one star system.

signal selected(data: StarSystemData)

var data: StarSystemData
var star_color := Color(0.75, 0.88, 1.0)
var star_radius := 5.0
var pulse_phase := 0.0
var is_hovered := false
var is_selected := false
var feedback_time := 0.0
var feedback_strength := 0.0
var feedback_tint := Color("52d8ff")


func setup(system_data: StarSystemData) -> void:
	data = system_data
	position = data.position
	star_color = _color_for_system()
	star_radius = _radius_for_system()
	queue_redraw()


func _process(delta: float) -> void:
	pulse_phase = fmod(pulse_phase + delta, TAU)
	feedback_time = maxf(0.0, feedback_time - delta)
	queue_redraw()


func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()


func refresh_visual() -> void:
	star_color = _color_for_system()
	star_radius = _radius_for_system()
	queue_redraw()


func trigger_action_feedback(is_active: bool) -> void:
	feedback_time = 1.15 if is_active else 0.68
	feedback_strength = 1.0 if is_active else 0.45
	feedback_tint = Color("52d8ff")
	queue_redraw()


func trigger_analysis_feedback() -> void:
	feedback_time = 0.82
	feedback_strength = 0.36
	feedback_tint = Color("9ad9ff")
	queue_redraw()


func trigger_extraction_feedback() -> void:
	feedback_time = 1.25
	feedback_strength = 0.82
	feedback_tint = Color("d9b26b")
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
	if data.observed and not data.is_home:
		draw_arc(Vector2.ZERO, star_radius + 4.5, -0.7, 2.0, 20, Color(star_color, 0.48), 0.8, true)
	if data.scanned and not data.is_home:
		draw_arc(Vector2.ZERO, star_radius + 7.0, 0.35, 5.9, 28, Color(0.7, 0.92, 1.0, 0.7), 1.0, true)
		draw_circle(Vector2(star_radius + 6.0, -star_radius - 2.0), 1.8, Color(0.75, 0.96, 1.0, 0.9))
	if data.extraction_level > 0 and not data.is_home:
		for level in data.extraction_level:
			var orbit_radius := star_radius + 10.0 + level * 3.2
			draw_arc(Vector2.ZERO, orbit_radius, 0.48 + level * 0.55, 2.45 + level * 0.3, 22, Color(0.78, 0.63, 0.37, 0.58), 0.85, true)
	if data.depleted:
		draw_arc(Vector2.ZERO, star_radius + 10.0, 3.25, 5.75, 22, Color(0.38, 0.56, 0.67, 0.54), 1.0, true)

	if data.is_home:
		var ring_radius := 18.0 + sin(pulse_phase * 1.7) * 1.4
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, Color(0.38, 0.88, 1.0, 0.56), 1.2, true)
		draw_line(Vector2(-27, 0), Vector2(-20, 0), Color(0.42, 0.9, 1.0, 0.46), 1.0)
		draw_line(Vector2(20, 0), Vector2(27, 0), Color(0.42, 0.9, 1.0, 0.46), 1.0)

	if is_hovered or is_selected:
		draw_arc(Vector2.ZERO, star_radius + 8.0, 0.0, TAU, 32, Color(0.83, 0.96, 1.0, 0.85), 1.0, true)
	if is_selected:
		var selected_radius := star_radius + 12.0 + sin(pulse_phase * 2.1) * 1.4
		draw_arc(Vector2.ZERO, selected_radius, 0.0, TAU, 48, Color(0.35, 0.82, 1.0, 0.72), 1.15, true)
	if feedback_time > 0.0:
		var feedback_phase := 1.0 - feedback_time / (1.15 if feedback_strength > 0.7 else 0.68)
		var feedback_radius := star_radius + 10.0 + feedback_phase * (44.0 + feedback_strength * 34.0)
		draw_arc(Vector2.ZERO, feedback_radius, 0.0, TAU, 48, Color(feedback_tint, (1.0 - feedback_phase) * 0.72), 1.1, true)

	if data.is_home or is_hovered or is_selected:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(star_radius + 9.0, -star_radius - 8.0), data.display_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.78, 0.9, 0.96, 0.88))


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
	if data.depleted:
		return Color("73909e")
	# Unknown systems deliberately stay neutral so their color does not leak hidden data.
	if not data.scanned:
		return Color("c8d9e2")
	match data.system_type:
		"Mineral Belt":
			return Color("d8b66c")
		"Pale Giant":
			return Color("b8d5ff")
		"Dead World":
			return Color("a2b0b9")
		"Signal Ruin":
			return Color("8bd9cf")
		"Red Anomaly":
			return Color("c76f9f")
		"Dark System":
			return Color("8b7da6")
	return Color("d7e7ef")


func _radius_for_system() -> float:
	if data.is_home:
		return 8.0
	if data.depleted:
		return 3.5
	if not data.scanned:
		return 4.0
	if data.system_type == "Pale Giant":
		return 7.0
	if data.system_type == "Red Anomaly" or data.system_type == "Mineral Belt":
		return 6.0
	return 4.0
