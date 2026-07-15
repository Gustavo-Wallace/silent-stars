class_name TechnologyManager
extends Node

signal technologies_changed(technologies: Array[TechnologyData])
signal research_completed(technology: TechnologyData)

var technologies: Array[TechnologyData] = []
var game_state: GameState


func configure(state: GameState) -> void:
	game_state = state
	_build_catalog()
	technologies_changed.emit(technologies)


func research(technology_id: String) -> void:
	var technology := _find(technology_id)
	if technology == null or technology.researched:
		return
	if not _prerequisites_met(technology):
		game_state.add_log_message("Prerequisite missing.")
		return
	if game_state.energy < technology.cost_energy or game_state.matter < technology.cost_matter or game_state.data < technology.cost_data:
		game_state.add_log_message("Insufficient resources for research.")
		return
	game_state.energy -= technology.cost_energy
	game_state.matter -= technology.cost_matter
	game_state.data -= technology.cost_data
	game_state.resources_changed.emit(game_state.energy, game_state.matter, game_state.data)
	technology.researched = true
	_apply_effect(technology)
	game_state.add_log_message("Research complete: %s." % technology.technology_name)
	game_state.add_log_message(_research_flavor(technology))
	technologies_changed.emit(technologies)
	research_completed.emit(technology)


func _build_catalog() -> void:
	technologies = [
		_tech("passive_listening", "Passive Listening Array", "Analysis", "Turns silence into usable information.", 0, 2, 6, [], "passive_observe_data_bonus", 1.0),
		_tech("cold_scan", "Cold Scan Protocol", "Silence", "Active sensors fire in shorter, colder bursts.", 2, 0, 8, [], "scan_signature_modifier", 0.75),
		_tech("dimmed_drives", "Dimmed Drives", "Exploration", "Travel wakes fade before they become patterns.", 4, 4, 10, [], "travel_signature_modifier", 0.8),
		_tech("efficient_burn", "Efficient Burn", "Exploration", "Every movement wastes less light.", 3, 3, 8, [], "travel_energy_modifier", 0.75),
		_tech("harvest_rigs", "Orbital Harvest Rigs", "Industry", "Small machines chew quietly through dead orbits.", 4, 8, 6, [], "extraction_yield_modifier", 1.25),
		_tech("deep_patterns", "Deep Pattern Analysis", "Analysis", "Noise becomes structure. Structure becomes warning.", 2, 0, 12, [], "analysis_yield_modifier", 1.35),
		_tech("ghost_routing", "Ghost Routing", "Survival", "Your routes stop looking like routes.", 6, 4, 14, ["dimmed_drives"], "event_risk_modifier", 0.8),
		_tech("blackout", "Blackout Discipline", "Silence", "The civilization learns when not to breathe.", 8, 6, 18, ["cold_scan"], "blackout", 1.0)
	]


func _tech(id: String, name: String, category_name: String, detail: String, energy: int, matter: int, data: int, requirements: PackedStringArray, effect: String, value: float) -> TechnologyData:
	var technology := TechnologyData.new()
	technology.technology_id = id
	technology.technology_name = name
	technology.category = category_name
	technology.description = detail
	technology.cost_energy = energy
	technology.cost_matter = matter
	technology.cost_data = data
	technology.prerequisites = requirements
	technology.effect_type = effect
	technology.effect_value = value
	return technology


func _apply_effect(technology: TechnologyData) -> void:
	match technology.effect_type:
		"scan_signature_modifier": game_state.scan_signature_modifier *= technology.effect_value
		"travel_signature_modifier": game_state.travel_signature_modifier *= technology.effect_value
		"travel_energy_modifier": game_state.travel_energy_modifier *= technology.effect_value
		"extraction_yield_modifier": game_state.extraction_yield_modifier *= technology.effect_value
		"analysis_yield_modifier": game_state.analysis_yield_modifier *= technology.effect_value
		"passive_observe_data_bonus": game_state.passive_observe_data_bonus += int(technology.effect_value)
		"event_risk_modifier": game_state.event_risk_modifier *= technology.effect_value
		"blackout":
			game_state.scan_signature_modifier *= 0.9
			game_state.travel_signature_modifier *= 0.9
			game_state.reduce_signature(4)


func _find(id: String) -> TechnologyData:
	for technology in technologies:
		if technology.technology_id == id:
			return technology
	return null


func _prerequisites_met(technology: TechnologyData) -> bool:
	for requirement in technology.prerequisites:
		var required := _find(requirement)
		if required == null or not required.researched:
			return false
	return true


func _research_flavor(technology: TechnologyData) -> String:
	if technology.category == "Silence": return "The dark keeps fewer records."
	if technology.category == "Industry": return "Industrial yield improved. The scars remain."
	return "A new pattern enters the observatory's vocabulary."

