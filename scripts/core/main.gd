extends Node2D
## Composition root. Future game-state, progression and narrative services belong here.

@onready var universe_map: UniverseMap = $UniverseMap
@onready var hud: ObservatoryHUD = $Interface/HUD
@onready var game_state: GameState = $GameState
@onready var event_manager: EventManager = $EventManager
@onready var technology_manager: TechnologyManager = $TechnologyManager


func _ready() -> void:
	# Main connects independent presentation layers without giving UI ownership of map data.
	universe_map.system_selected.connect(hud.display_system)
	universe_map.system_updated.connect(hud.display_system)
	universe_map.passive_observation_completed.connect(game_state.complete_passive_observation)
	universe_map.active_scan_completed.connect(game_state.complete_active_scan)
	universe_map.analysis_completed.connect(game_state.complete_analysis)
	universe_map.extraction_completed.connect(game_state.complete_extraction)
	universe_map.travel_requested.connect(_on_travel_requested)
	universe_map.travel_arrived.connect(_on_travel_arrived)
	universe_map.action_denied.connect(game_state.add_log_message)
	universe_map.probe_requested.connect(_on_probe_requested)
	universe_map.probe_arrived.connect(_on_probe_arrived)
	hud.passive_observe_requested.connect(universe_map.observe_selected_system)
	hud.active_scan_requested.connect(universe_map.scan_selected_system)
	hud.analyze_requested.connect(universe_map.analyze_selected_system)
	hud.extraction_requested.connect(universe_map.extract_selected_system)
	hud.travel_requested.connect(universe_map.begin_travel_to_selected)
	hud.probe_requested.connect(universe_map.launch_probe_to_selected)
	hud.event_choice_requested.connect(_on_event_choice)
	hud.research_requested.connect(technology_manager.research)
	game_state.state_changed.connect(hud.update_game_state)
	game_state.resources_changed.connect(hud.update_resources)
	game_state.probes_changed.connect(hud.update_probes)
	game_state.travel_status_changed.connect(_on_travel_status_changed)
	game_state.log_message_added.connect(hud.add_log_message)
	game_state.signature_increased.connect(universe_map.trigger_signature_pulse)
	technology_manager.technologies_changed.connect(hud.set_technologies)
	technology_manager.research_completed.connect(_on_research_completed)
	technology_manager.configure(game_state)
	game_state.publish_initial_state()
	_on_travel_status_changed(game_state.current_system_id, false)


func _on_travel_requested(destination: StarSystemData, distance: float) -> void:
	if game_state.begin_travel(destination, distance):
		universe_map.start_ship_travel(destination)


func _on_travel_arrived(destination: StarSystemData) -> void:
	game_state.complete_travel(destination)
	var arrival_event: EventData = event_manager.create_choice_event(destination, "Arrival", game_state.cosmic_signature)
	hud.show_choice_event(arrival_event)


func _on_travel_status_changed(system_id: int, traveling: bool) -> void:
	var system: StarSystemData = universe_map.current_system()
	if system != null:
		hud.update_location(system.system_name, system_id, traveling)


func _on_research_completed(_technology: TechnologyData) -> void:
	universe_map.trigger_signature_pulse(0.25)

func choose_event(index: int) -> void:
	event_manager.choose(index, game_state)

func _on_event_choice(index: int) -> void:
	choose_event(index)
	hud.close_event()

func _on_probe_requested(destination: StarSystemData, distance: float) -> void:
	if game_state.launch_probe():
		var probe := ProbeData.new()
		probe.probe_id = game_state.probes_launched_total
		probe.origin_system_id = game_state.current_system_id
		probe.target_system_id = destination.id
		probe.risk_level = ProbeService.risk(destination, game_state.cosmic_signature, distance, game_state.event_risk_modifier)
		universe_map.start_probe(destination, probe)
		game_state.add_log_message("Probe launched toward %s." % destination.system_name)

func _on_probe_arrived(destination: StarSystemData, probe: ProbeData) -> void:
	var roll := float((probe.probe_id * 37) % 100) / 100.0
	if roll < probe.risk_level * 0.35:
		game_state.probes_lost_total += 1
		game_state.apply_probe_result(destination, "Probe signal terminated without decay.", 0, 0, 2, probe.risk_level > 0.45)
		return
	destination.observed = true
	var deep := destination.system_type == "Signal Ruin" or destination.system_type == "Red Anomaly" or roll > 0.72
	if deep: destination.scanned = true
	var data_gain := 2 + int(destination.data_potential / 45)
	if deep: data_gain += 2
	game_state.apply_probe_result(destination, "Probe survey completed. Local readings archived. +%d DATA." % data_gain, data_gain, 0, 0, false)
	hud.display_system(destination)


# Future integration points: cosmic signature, time cycles, technology progression,
# Dark Forest threats and narrative events should coordinate here without coupling UI to map generation.
