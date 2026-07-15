extends Node2D
## Composition root. Future game-state, progression and narrative services belong here.

@onready var universe_map: UniverseMap = $UniverseMap
@onready var hud: ObservatoryHUD = $Interface/HUD
@onready var game_state: GameState = $GameState
@onready var event_manager: EventManager = $EventManager


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
	hud.passive_observe_requested.connect(universe_map.observe_selected_system)
	hud.active_scan_requested.connect(universe_map.scan_selected_system)
	hud.analyze_requested.connect(universe_map.analyze_selected_system)
	hud.extraction_requested.connect(universe_map.extract_selected_system)
	hud.travel_requested.connect(universe_map.begin_travel_to_selected)
	game_state.state_changed.connect(hud.update_game_state)
	game_state.resources_changed.connect(hud.update_resources)
	game_state.travel_status_changed.connect(_on_travel_status_changed)
	game_state.log_message_added.connect(hud.add_log_message)
	game_state.signature_increased.connect(universe_map.trigger_signature_pulse)
	game_state.publish_initial_state()
	_on_travel_status_changed(game_state.current_system_id, false)


func _on_travel_requested(destination: StarSystemData, distance: float) -> void:
	if game_state.begin_travel(destination, distance):
		universe_map.start_ship_travel(destination)


func _on_travel_arrived(destination: StarSystemData) -> void:
	game_state.complete_travel(destination)
	var arrival_event: ArrivalEventData = event_manager.create_arrival_event(destination, game_state.cosmic_signature)
	game_state.apply_arrival_event(arrival_event)
	hud.show_arrival_event(arrival_event)


func _on_travel_status_changed(system_id: int, traveling: bool) -> void:
	var system: StarSystemData = universe_map.current_system()
	if system != null:
		hud.update_location(system.system_name, system_id, traveling)


# Future integration points: cosmic signature, time cycles, technology progression,
# Dark Forest threats and narrative events should coordinate here without coupling UI to map generation.
