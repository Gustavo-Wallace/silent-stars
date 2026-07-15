class_name UniverseMap
extends Node2D
## Generates and owns the reproducible, data-driven star map.

signal system_selected(data: StarSystemData)
signal system_updated(data: StarSystemData)
signal passive_observation_completed(data: StarSystemData)
signal active_scan_completed(data: StarSystemData)

const STAR_SYSTEM_SCENE := preload("res://scenes/universe/star_system_node.tscn")
const MAP_HALF_EXTENT := 2300.0
const SYSTEM_COUNT := 46
const MAP_SEED := 17012026

var systems: Array[StarSystemData] = []
var background_stars: Array[Dictionary] = []
var signal_time := 0.0
var rng := RandomNumberGenerator.new()
var selected_data: StarSystemData
var selected_node: StarSystemNode
var event_pulses: Array[Dictionary] = []


func _ready() -> void:
	rng.seed = MAP_SEED
	_generate_background_stars()
	_generate_systems()
	_create_system_nodes()
	queue_redraw()


func _process(delta: float) -> void:
	signal_time += delta
	for pulse in event_pulses:
		pulse["age"] = float(pulse["age"]) + delta
	event_pulses = event_pulses.filter(func(pulse: Dictionary): return float(pulse["age"]) < float(pulse["duration"]))
	queue_redraw()


func _draw() -> void:
	# A generous world-space field keeps the backdrop present while the camera pans.
	draw_rect(Rect2(-MAP_HALF_EXTENT, -MAP_HALF_EXTENT, MAP_HALF_EXTENT * 2.0, MAP_HALF_EXTENT * 2.0), Color("050916"))
	_draw_background_stars()
	_draw_routes()
	_draw_home_signal()
	_draw_event_pulses()


func _generate_background_stars() -> void:
	for i in 360:
		var pos := Vector2(rng.randf_range(-MAP_HALF_EXTENT, MAP_HALF_EXTENT), rng.randf_range(-MAP_HALF_EXTENT, MAP_HALF_EXTENT))
		background_stars.append({
			"position": pos,
			"radius": rng.randf_range(0.35, 1.25),
			"alpha": rng.randf_range(0.10, 0.48)
		})


func _generate_systems() -> void:
	var home := _make_system(0, "Solace", Vector2.ZERO, "Homeworld", 8, 64, true)
	systems.append(home)
	var names: PackedStringArray = ["Vesper", "Aster", "Nyx", "Lumen", "Erebos", "Caelum", "Oris", "Nadir", "Pale Echo", "Morrow", "Ilyra", "Cinder", "Axiom", "Halcyon"]
	var types: PackedStringArray = ["Main Sequence", "Red Dwarf", "Blue Giant", "Binary", "White Dwarf", "Anomalous"]
	for i in range(1, SYSTEM_COUNT):
		var candidate := Vector2.ZERO
		var valid := false
		for attempt in 24:
			candidate = Vector2(rng.randf_range(-MAP_HALF_EXTENT + 120.0, MAP_HALF_EXTENT - 120.0), rng.randf_range(-MAP_HALF_EXTENT + 120.0, MAP_HALF_EXTENT - 120.0))
			if candidate.length() > 250.0 and _is_far_enough(candidate):
				valid = true
				break
		if not valid:
			candidate = Vector2(rng.randf_range(-1800.0, 1800.0), rng.randf_range(-1800.0, 1800.0))
		var name: String = "%s %s" % [names[rng.randi_range(0, names.size() - 1)], _roman_numeral(rng.randi_range(1, 9))]
		var threat := rng.randi_range(4, 96)
		var resources := rng.randi_range(8, 94)
		var type: String = types[rng.randi_range(0, types.size() - 1)]
		systems.append(_make_system(i, name, candidate, type, threat, resources, false))


func _make_system(id_value: int, system_name: String, system_position: Vector2, type: String, threat: int, resources: int, home: bool) -> StarSystemData:
	var system := StarSystemData.new()
	system.id = id_value
	system.system_name = system_name
	system.position = system_position
	system.system_type = type
	system.threat_level = threat
	system.resource_potential = resources
	system.is_home = home
	system.discovered = true
	system.observed = home
	system.scanned = home
	system.callsign = "SECTOR %02d" % id_value
	return system


func _is_far_enough(candidate: Vector2) -> bool:
	for system in systems:
		if system.position.distance_to(candidate) < 130.0:
			return false
	return true


func _create_system_nodes() -> void:
	for data in systems:
		var node := STAR_SYSTEM_SCENE.instantiate() as StarSystemNode
		$Systems.add_child(node)
		node.setup(data)
		node.selected.connect(_on_system_selected)


func _on_system_selected(data: StarSystemData) -> void:
	selected_data = data
	for child in $Systems.get_children():
		var system_node: StarSystemNode = child as StarSystemNode
		if system_node != null:
			system_node.set_selected(system_node.data == selected_data)
	selected_node = _node_for_data(data)
	system_selected.emit(data)


func observe_selected_system() -> void:
	if selected_data == null or selected_data.is_home or selected_data.observed:
		return
	selected_data.observed = true
	selected_node.trigger_action_feedback(false)
	_refresh_selected_node()
	system_updated.emit(selected_data)
	passive_observation_completed.emit(selected_data)


func scan_selected_system() -> void:
	if selected_data == null or selected_data.is_home or selected_data.scanned:
		return
	selected_data.observed = true
	selected_data.scanned = true
	selected_node.trigger_action_feedback(true)
	trigger_world_pulse(selected_data.position, 0.95)
	_refresh_selected_node()
	system_updated.emit(selected_data)
	active_scan_completed.emit(selected_data)


func trigger_signature_pulse(intensity: float) -> void:
	trigger_world_pulse(Vector2.ZERO, intensity)


func trigger_world_pulse(origin: Vector2, intensity: float) -> void:
	event_pulses.append({"origin": origin, "age": 0.0, "duration": 1.8 + intensity * 0.45, "intensity": intensity})


func _node_for_data(data: StarSystemData) -> StarSystemNode:
	for node in $Systems.get_children():
		var system_node := node as StarSystemNode
		if system_node.data == data:
			return system_node
	return null


func _refresh_selected_node() -> void:
	if selected_node != null:
		selected_node.refresh_visual()


func _draw_background_stars() -> void:
	for star in background_stars:
		draw_circle(star.position, star.radius, Color(0.58, 0.74, 0.9, star.alpha))


func _draw_routes() -> void:
	# Draw only a sparse nearest-neighbor network to avoid visual noise.
	for system in systems:
		var neighbors: Array[StarSystemData] = []
		for other in systems:
			if other == system:
				continue
			if system.position.distance_to(other.position) < 620.0:
				neighbors.append(other)
		neighbors.sort_custom(func(a: StarSystemData, b: StarSystemData): return system.position.distance_squared_to(a.position) < system.position.distance_squared_to(b.position))
		for i in min(2, neighbors.size()):
			var neighbor := neighbors[i]
			if neighbor.id > system.id:
				draw_line(system.position, neighbor.position, Color(0.24, 0.48, 0.65, 0.16), 1.0, true)


func _draw_home_signal() -> void:
	# Visual-only precursor to future cosmic-signature and detection mechanics.
	for offset in [0.0, 0.33, 0.66]:
		var phase := fmod(signal_time * 0.065 + offset, 1.0)
		var radius := 95.0 + phase * 680.0
		var alpha := (1.0 - phase) * 0.18
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 128, Color(0.27, 0.78, 1.0, alpha), 1.15, true)


func _draw_event_pulses() -> void:
	for pulse in event_pulses:
		var age: float = float(pulse["age"])
		var duration: float = float(pulse["duration"])
		var intensity: float = float(pulse["intensity"])
		var origin: Vector2 = pulse["origin"]
		var phase: float = age / duration
		var radius: float = 20.0 + phase * (240.0 + intensity * 260.0)
		var alpha: float = (1.0 - phase) * (0.32 if intensity > 0.7 else 0.16)
		draw_arc(origin, radius, 0.0, TAU, 96, Color(0.36, 0.84, 1.0, alpha), 1.35, true)


func _roman_numeral(value: int) -> String:
	var numerals: PackedStringArray = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]
	return numerals[clampi(value, 1, 9) - 1]
