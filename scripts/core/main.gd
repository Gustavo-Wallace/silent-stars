extends Node2D
## Composition root. Future game-state, progression and narrative services belong here.

@onready var universe_map: UniverseMap = $UniverseMap
@onready var hud: ObservatoryHUD = $Interface/HUD
@onready var game_state: GameState = $GameState


func _ready() -> void:
	# Main connects independent presentation layers without giving UI ownership of map data.
	universe_map.system_selected.connect(hud.display_system)
	universe_map.system_updated.connect(hud.display_system)
	universe_map.passive_observation_completed.connect(game_state.complete_passive_observation)
	universe_map.active_scan_completed.connect(game_state.complete_active_scan)
	universe_map.analysis_completed.connect(game_state.complete_analysis)
	universe_map.extraction_completed.connect(game_state.complete_extraction)
	hud.passive_observe_requested.connect(universe_map.observe_selected_system)
	hud.active_scan_requested.connect(universe_map.scan_selected_system)
	hud.analyze_requested.connect(universe_map.analyze_selected_system)
	hud.extraction_requested.connect(universe_map.extract_selected_system)
	game_state.state_changed.connect(hud.update_game_state)
	game_state.resources_changed.connect(hud.update_resources)
	game_state.log_message_added.connect(hud.add_log_message)
	game_state.signature_increased.connect(universe_map.trigger_signature_pulse)
	game_state.publish_initial_state()


# Future integration points: cosmic signature, time cycles, technology progression,
# Dark Forest threats and narrative events should coordinate here without coupling UI to map generation.
