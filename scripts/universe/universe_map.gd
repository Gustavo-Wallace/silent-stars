class_name UniverseMap
extends Node2D
## Generates and owns the reproducible, data-driven star map.

signal system_selected(data: StarSystemData)
signal system_updated(data: StarSystemData)
signal passive_observation_completed(data: StarSystemData)
signal active_scan_completed(data: StarSystemData)
signal analysis_completed(data: StarSystemData, result: Dictionary)
signal extraction_completed(data: StarSystemData, result: Dictionary)
signal travel_requested(destination: StarSystemData, distance: float)
signal travel_arrived(destination: StarSystemData)
signal action_denied(message: String)
signal probe_requested(destination: StarSystemData, distance: float)
signal probe_arrived(destination: StarSystemData, probe: ProbeData)

const STAR_SYSTEM_SCENE := preload("res://scenes/universe/star_system_node.tscn")
const RESOURCE_SERVICE := preload("res://scripts/universe/resource_service.gd")
const PROBE_SCENE := preload("res://scenes/universe/probe_node.tscn")
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
var current_system_id: int = 0

@onready var player_ship: PlayerShip = $PlayerShip
@onready var travel_route: Line2D = $TravelRoute


func _ready() -> void:
	rng.seed = MAP_SEED
	_generate_background_stars()
	_generate_systems()
	_create_system_nodes()
	_set_current_system(0)
	player_ship.setup_initial(systems[0].position, 0)
	player_ship.arrived.connect(_on_ship_arrived)
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
	var home := _make_system(0, "Solace", Vector2.ZERO, "Home System", true)
	systems.append(home)
	var names: PackedStringArray = ["Vesper", "Aster", "Nyx", "Lumen", "Erebos", "Caelum", "Oris", "Nadir", "Pale Echo", "Morrow", "Ilyra", "Cinder", "Axiom", "Halcyon"]
	var types: PackedStringArray = ["Quiet Star", "Mineral Belt", "Pale Giant", "Dead World", "Signal Ruin", "Red Anomaly", "Dark System"]
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
		var type: String = types[rng.randi_range(0, types.size() - 1)]
		systems.append(_make_system(i, name, candidate, type, false))


func _make_system(id_value: int, system_name: String, system_position: Vector2, type: String, home: bool) -> StarSystemData:
	var system := StarSystemData.new()
	system.id = id_value
	system.system_name = system_name
	system.position = system_position
	system.system_type = type
	system.is_home = home
	system.discovered = true
	system.observed = home
	system.scanned = home
	system.callsign = "SECTOR %02d" % id_value
	_apply_resource_profile(system)
	return system


func _apply_resource_profile(system: StarSystemData) -> void:
	if system.is_home:
		system.energy_potential = 64
		system.matter_potential = 52
		system.data_potential = 48
		system.threat_level = 8
	else:
		match system.system_type:
			"Quiet Star":
				system.energy_potential = rng.randi_range(55, 90)
				system.matter_potential = rng.randi_range(18, 46)
				system.data_potential = rng.randi_range(10, 34)
				system.threat_level = rng.randi_range(5, 32)
			"Mineral Belt":
				system.energy_potential = rng.randi_range(14, 42)
				system.matter_potential = rng.randi_range(64, 96)
				system.data_potential = rng.randi_range(15, 46)
				system.threat_level = rng.randi_range(10, 42)
			"Pale Giant":
				system.energy_potential = rng.randi_range(72, 100)
				system.matter_potential = rng.randi_range(10, 36)
				system.data_potential = rng.randi_range(24, 55)
				system.threat_level = rng.randi_range(42, 78)
			"Dead World":
				system.energy_potential = rng.randi_range(9, 30)
				system.matter_potential = rng.randi_range(32, 68)
				system.data_potential = rng.randi_range(20, 58)
				system.threat_level = rng.randi_range(5, 38)
			"Signal Ruin":
				system.energy_potential = rng.randi_range(14, 38)
				system.matter_potential = rng.randi_range(18, 48)
				system.data_potential = rng.randi_range(68, 100)
				system.threat_level = rng.randi_range(34, 84)
			"Red Anomaly":
				system.energy_potential = rng.randi_range(38, 78)
				system.matter_potential = rng.randi_range(18, 54)
				system.data_potential = rng.randi_range(54, 92)
				system.threat_level = rng.randi_range(62, 100)
			"Dark System":
				system.energy_potential = rng.randi_range(8, 42)
				system.matter_potential = rng.randi_range(30, 72)
				system.data_potential = rng.randi_range(34, 78)
				system.threat_level = rng.randi_range(36, 88)
	system.resource_potential = roundi(float(system.energy_potential + system.matter_potential + system.data_potential) / 3.0)


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


func analyze_selected_system() -> void:
	if selected_data == null or selected_data.is_home or not selected_data.observed:
		return
	var result: Dictionary = RESOURCE_SERVICE.analyze(selected_data)
	selected_node.trigger_analysis_feedback()
	trigger_world_pulse(selected_data.position, 0.28)
	system_updated.emit(selected_data)
	analysis_completed.emit(selected_data, result)


func extract_selected_system() -> void:
	if selected_data == null or selected_data.is_home or not selected_data.scanned or selected_data.depleted:
		return
	if selected_data.id != current_system_id:
		action_denied.emit("Local presence required for extraction.")
		return
	var result: Dictionary = RESOURCE_SERVICE.extract(selected_data)
	selected_node.trigger_extraction_feedback()
	trigger_world_pulse(selected_data.position, 0.72)
	_refresh_selected_node()
	system_updated.emit(selected_data)
	extraction_completed.emit(selected_data, result)


func begin_travel_to_selected() -> void:
	if selected_data == null or player_ship.is_traveling:
		return
	if selected_data.id == current_system_id:
		action_denied.emit("The vessel is already in local orbit.")
		return
	if not selected_data.observed:
		action_denied.emit("Observation data required before plotting a course.")
		return
	var origin := _system_by_id(current_system_id)
	if origin == null:
		return
	travel_requested.emit(selected_data, origin.position.distance_to(selected_data.position))

func launch_probe_to_selected() -> void:
	if selected_data == null or selected_data.id == current_system_id or not selected_data.observed:
		action_denied.emit("Observation data required before probe launch.")
		return
	var origin := _system_by_id(current_system_id)
	probe_requested.emit(selected_data, origin.position.distance_to(selected_data.position))

func start_probe(destination: StarSystemData, probe: ProbeData) -> void:
	var node := PROBE_SCENE.instantiate() as ProbeNode
	add_child(node)
	node.launch(probe, _system_by_id(current_system_id).position, destination.position)
	node.arrived.connect(func(data: ProbeData): _on_probe_arrived(destination, data))
	trigger_world_pulse(_system_by_id(current_system_id).position, 0.18)

func _on_probe_arrived(destination: StarSystemData, probe: ProbeData) -> void:
	trigger_world_pulse(destination.position, 0.28)
	probe_arrived.emit(destination, probe)


func start_ship_travel(destination: StarSystemData) -> void:
	var origin := _system_by_id(current_system_id)
	if origin == null:
		return
	travel_route.points = PackedVector2Array([origin.position, destination.position])
	trigger_world_pulse(origin.position, 0.32)
	player_ship.travel_to(destination.position, destination.id)


func _on_ship_arrived(system_id: int) -> void:
	travel_route.clear_points()
	_set_current_system(system_id)
	var destination := _system_by_id(system_id)
	if destination != null:
		trigger_world_pulse(destination.position, 0.52)
		travel_arrived.emit(destination)


func _set_current_system(system_id: int) -> void:
	current_system_id = system_id
	for child in $Systems.get_children():
		var system_node: StarSystemNode = child as StarSystemNode
		if system_node != null:
			system_node.set_current(system_node.data.id == current_system_id)


func _system_by_id(system_id: int) -> StarSystemData:
	for system in systems:
		if system.id == system_id:
			return system
	return null


func current_system() -> StarSystemData:
	return _system_by_id(current_system_id)


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
