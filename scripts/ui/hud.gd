class_name ObservatoryHUD
extends Control
## Presentation-only HUD. It asks Main for actions through signals and never mutates map data.

signal passive_observe_requested
signal active_scan_requested
signal analyze_requested
signal extraction_requested
signal travel_requested
signal research_requested(technology_id: String)
signal probe_requested
signal event_choice_requested(index: int)
signal infrastructure_requested(id: String)
signal blackout_requested
signal fabricate_probe_requested
signal expand_probe_bay_requested
signal protocol_requested

const MAX_LOG_MESSAGES := 5

@onready var telemetry: Label = $Telemetry
@onready var signature_value: Label = $SignatureMeter/Value
@onready var signature_fill: ColorRect = $SignatureMeter/Track/Fill
@onready var resource_readout: Label = $ResourceReadout
@onready var location_readout: Label = $LocationReadout
@onready var details: Label = $DetailsPanel/Details
@onready var action_hint: Label = $DetailsPanel/ActionHint
@onready var passive_button: Button = $DetailsPanel/PassiveObserve
@onready var scan_button: Button = $DetailsPanel/ActiveScan
@onready var analyze_button: Button = $DetailsPanel/AnalyzeData
@onready var extraction_button: Button = $DetailsPanel/BeginExtraction
@onready var travel_button: Button = $DetailsPanel/Travel
@onready var log_entries: Label = $LogPanel/Entries
@onready var event_panel: ColorRect = $ArrivalEvent
@onready var event_title: Label = $ArrivalEvent/Title
@onready var event_description: Label = $ArrivalEvent/Description
@onready var event_result: Label = $ArrivalEvent/Result
@onready var event_continue: Button = $ArrivalEvent/Continue
@onready var choice_one: Button = $ArrivalEvent/ChoiceOne
@onready var choice_two: Button = $ArrivalEvent/ChoiceTwo
@onready var choice_three: Button = $ArrivalEvent/ChoiceThree
@onready var research_toggle: Button = $ResearchToggle
@onready var research_panel: ColorRect = $ResearchPanel
@onready var technology_list: ItemList = $ResearchPanel/TechnologyList
@onready var research_details: Label = $ResearchPanel/Details
@onready var research_button: Button = $ResearchPanel/Research
@onready var research_close: Button = $ResearchPanel/Close
@onready var probe_button: Button = $DetailsPanel/LaunchProbe
@onready var objective_label: Label = $Objective
@onready var protocol_label: Label = $Protocol
@onready var protocol_button: Button = $ExecuteProtocol

var selected_system: StarSystemData
var log_messages: Array[String] = []
var current_system_id: int = 0
var is_traveling := false
var technologies: Array[TechnologyData] = []
var research_energy: int = 0
var research_matter: int = 0
var research_data: int = 0
var probes_count: int = 0
var probes_capacity: int = 4
var infrastructure: Array[InfrastructureData] = []
var selected_technology_index: int = -1

func update_void(_attention: int, pressure: String) -> void:
	location_readout.text = location_readout.text.split("\n")[0] + "\nVOID PRESSURE     " + pressure

func _on_blackout_pressed() -> void:
	blackout_requested.emit()
func set_infrastructure(items: Array[InfrastructureData]) -> void:
	infrastructure = items

func _on_infrastructure_pressed() -> void:
	if not infrastructure.is_empty(): infrastructure_requested.emit(infrastructure[0].structure_id)
func _ready() -> void:
	passive_button.pressed.connect(_on_passive_observe_pressed)
	scan_button.pressed.connect(_on_active_scan_pressed)
	analyze_button.pressed.connect(_on_analyze_pressed)
	extraction_button.pressed.connect(_on_extraction_pressed)
	travel_button.pressed.connect(_on_travel_pressed)
	event_continue.pressed.connect(_on_event_continue_pressed)
	choice_one.pressed.connect(func(): event_choice_requested.emit(0))
	choice_two.pressed.connect(func(): event_choice_requested.emit(1))
	choice_three.pressed.connect(func(): event_choice_requested.emit(2))
	probe_button.pressed.connect(func(): probe_requested.emit())
	research_toggle.pressed.connect(_on_research_toggle_pressed)
	research_close.pressed.connect(_on_research_close_pressed)
	research_button.pressed.connect(_on_research_pressed)
	technology_list.item_selected.connect(_on_technology_selected)
	passive_button.disabled = true
	scan_button.disabled = true
	analyze_button.disabled = true
	extraction_button.disabled = true
	travel_button.disabled = true
	probe_button.disabled = true
	event_panel.visible = false
	research_panel.visible = false
	passive_button.visible = false
	scan_button.visible = false
	analyze_button.visible = false
	extraction_button.visible = false
	travel_button.visible = false
	probe_button.visible = false


func display_system(data: StarSystemData) -> void:
	selected_system = data
	details.text = _details_for(data)
	passive_button.disabled = data.is_home or data.observed
	scan_button.disabled = data.is_home or data.scanned
	analyze_button.disabled = data.is_home or not data.observed
	extraction_button.disabled = data.is_home or not data.scanned or data.depleted
	travel_button.disabled = is_traveling or data.id == current_system_id or not data.observed
	probe_button.disabled = data.id == current_system_id or not data.observed
	passive_button.visible = not data.is_home and not data.observed
	scan_button.visible = not data.is_home and not data.scanned
	analyze_button.visible = data.observed and not data.is_home
	travel_button.visible = data.observed and not data.is_home
	probe_button.visible = data.observed and not data.is_home
	extraction_button.visible = data.scanned and data.id == current_system_id and not data.is_home
	if data.id != current_system_id:
		extraction_button.disabled = true
	if data.is_home:
		action_hint.text = "HOME SYSTEM — COMPLETE TELEMETRY AVAILABLE"
	elif data.depleted:
		action_hint.text = "RESOURCE PROFILE COLLAPSED — EXTRACTION UNAVAILABLE"
	elif data.scanned and data.id != current_system_id:
		action_hint.text = "LOCAL PRESENCE REQUIRED FOR EXTRACTION"
	elif is_traveling:
		action_hint.text = "VESSEL IN TRANSIT — LOCAL ACTIONS PAUSED"
	elif data.scanned:
		action_hint.text = "ACTIVE SCAN ARCHIVED"
	elif data.observed:
		action_hint.text = "PASSIVE OBSERVATION COMPLETE"
	else:
		action_hint.text = "CHOOSE HOW MUCH OF YOURSELF TO REVEAL"


func update_game_state(cycle: int, signature: int, contact: String) -> void:
	var band := _signature_band(signature)
	telemetry.text = "CYCLE                %03d\nCOSMIC SIGNATURE  %s\nCONTACT STATUS    %s" % [cycle, band, contact]
	signature_value.text = "%02d  /  SIGNAL FOOTPRINT" % signature
	signature_fill.size.x = 190.0 * minf(float(signature) / 50.0, 1.0)
	signature_fill.color = _signature_color(band)


func update_resources(energy: int, matter: int, data: int) -> void:
	research_energy = energy
	research_matter = matter
	research_data = data
	resource_readout.text = "ENERGY  %03d\nMATTER  %03d\nDATA    %03d\nPROBES  %02d/%02d" % [energy, matter, data, probes_count, probes_capacity]
	_refresh_research()

func update_probes(count: int, capacity: int) -> void:
	probes_count = count
	probes_capacity = capacity
	resource_readout.text = "ENERGY  %03d\nMATTER  %03d\nDATA    %03d\nPROBES  %02d/%02d" % [research_energy, research_matter, research_data, probes_count, probes_capacity]

func _on_fabricate_pressed() -> void:
	fabricate_probe_requested.emit()
func _on_expand_bay_pressed() -> void:
	expand_probe_bay_requested.emit()

func update_objective(text: String) -> void:
	objective_label.text = text

func update_protocol(text: String, ready: bool) -> void:
	protocol_label.text = text
	protocol_button.disabled = not ready

func _on_protocol_pressed() -> void:
	protocol_requested.emit()

func show_run_report(victory: bool, report: String) -> void:
	event_title.text = "RUN COMPLETE" if victory else "LOCATION INFERRED"
	event_description.text = report
	event_result.text = "Review final telemetry."
	event_continue.visible = true
	event_panel.visible = true


func set_technologies(next_technologies: Array[TechnologyData]) -> void:
	technologies = next_technologies
	_refresh_research()


func update_location(system_name: String, system_id: int, traveling: bool) -> void:
	current_system_id = system_id
	is_traveling = traveling
	location_readout.text = "CURRENT LOCATION  %s\nTRAVEL STATUS     %s" % [system_name, "IN TRANSIT" if traveling else "DOCKED"]
	if selected_system != null:
		display_system(selected_system)


func show_arrival_event(event: ArrivalEventData) -> void:
	event_title.text = event.title.to_upper()
	event_description.text = event.description
	event_result.text = event.result
	event_panel.visible = true

func show_choice_event(event: EventData) -> void:
	event_title.text = "%s · %s" % [event.title.to_upper(), event.severity]
	event_description.text = "[%s] %s" % [event.source, event.description]
	event_result.text = "Choose a response."
	var buttons := [choice_one, choice_two, choice_three]
	for index in buttons.size():
		buttons[index].visible = index < event.choices.size()
		if index < event.choices.size(): buttons[index].text = "%s  —  %s" % [event.choices[index].label, event.choices[index].summary]
	event_continue.visible = false
	event_panel.visible = true


func add_log_message(message: String) -> void:
	log_messages.append("› " + message)
	if log_messages.size() > MAX_LOG_MESSAGES:
		log_messages.pop_front()
	log_entries.text = "\n".join(log_messages)


func _details_for(data: StarSystemData) -> String:
	var infrastructure_text := "NONE" if not data.has_infrastructure() else ", ".join(data.built_structures)
	if data.is_home:
		return "%s\n\nTYPE       %s\nINFRA      %s\nLOCAL SIG  %s\nSTATUS     HOME\n\n%s" % [data.system_name, data.system_type, infrastructure_text, data.local_signature_text(), data.system_description()]
	if not data.observed:
		return "%s\n\nTYPE       UNKNOWN\nENERGY     UNKNOWN\nMATTER     UNKNOWN\nDATA       UNKNOWN\nTHREAT     UNKNOWN\nEXTRACTION UNKNOWN\nSTATUS     UNOBSERVED\n\nA distant point without a stable profile." % data.display_name()
	if not data.scanned:
		return "%s\n\nTYPE       %s\nENERGY     %s ESTIMATE\nMATTER     %s ESTIMATE\nDATA       %s ESTIMATE\nTHREAT     %s\nEXTRACTION %s\nSTATUS     OBSERVED\n\n%s" % [data.system_name, data.system_type, _resource_band(data.energy_potential), _resource_band(data.matter_potential), _resource_band(data.data_potential), data.observed_threat_text(), data.extraction_text(), data.system_description()]
	return "%s\n\nTYPE       %s\nINFRA      %s\nLOCAL SIG  %s\nEXTRACTION %s\nSTATUS     SCANNED\n\n%s" % [data.system_name, data.system_type, infrastructure_text, data.local_signature_text(), data.extraction_text(), data.system_description()]


func _on_passive_observe_pressed() -> void:
	passive_observe_requested.emit()


func _on_active_scan_pressed() -> void:
	active_scan_requested.emit()


func _on_analyze_pressed() -> void:
	analyze_requested.emit()


func _on_extraction_pressed() -> void:
	extraction_requested.emit()


func _on_travel_pressed() -> void:
	travel_requested.emit()


func _on_event_continue_pressed() -> void:
	event_panel.visible = false

func close_event() -> void:
	event_panel.visible = false


func _on_research_toggle_pressed() -> void:
	research_panel.visible = true
	_refresh_research()


func _on_research_close_pressed() -> void:
	research_panel.visible = false


func _on_technology_selected(index: int) -> void:
	selected_technology_index = index
	_refresh_research()


func _on_research_pressed() -> void:
	if selected_technology_index >= 0 and selected_technology_index < technologies.size():
		research_requested.emit(technologies[selected_technology_index].technology_id)


func _refresh_research() -> void:
	if technology_list == null:
		return
	technology_list.clear()
	for technology in technologies:
		technology_list.add_item("[%s] %s — %s" % [_technology_status(technology), technology.technology_name, technology.category])
	if selected_technology_index < 0 and not technologies.is_empty():
		selected_technology_index = 0
	if selected_technology_index >= technologies.size():
		selected_technology_index = technologies.size() - 1
	if selected_technology_index < 0:
		return
	technology_list.select(selected_technology_index)
	var technology := technologies[selected_technology_index]
	var prerequisite_text := "NONE" if technology.prerequisites.is_empty() else ", ".join(technology.prerequisites)
	research_details.text = "%s\n\nCATEGORY  %s\nSTATUS    %s\nCOST      %d ENERGY · %d MATTER · %d DATA\nREQUIRES  %s\n\n%s" % [technology.technology_name, technology.category, _technology_status(technology), technology.cost_energy, technology.cost_matter, technology.cost_data, prerequisite_text, technology.description]
	research_button.disabled = technology.researched or not _can_afford(technology) or not _prerequisites_met(technology)
	research_button.text = "RESEARCH" if not technology.researched else "RESEARCHED"


func _technology_status(technology: TechnologyData) -> String:
	if technology.researched: return "RESEARCHED"
	if not _prerequisites_met(technology): return "LOCKED"
	return "AVAILABLE" if _can_afford(technology) else "UNAVAILABLE"


func _can_afford(technology: TechnologyData) -> bool:
	return research_energy >= technology.cost_energy and research_matter >= technology.cost_matter and research_data >= technology.cost_data


func _prerequisites_met(technology: TechnologyData) -> bool:
	for required_id in technology.prerequisites:
		for candidate in technologies:
			if candidate.technology_id == required_id and not candidate.researched:
				return false
	return true


func _resource_band(value: int) -> String:
	if value < 34:
		return "LOW"
	if value < 68:
		return "MEDIUM"
	return "HIGH"


func _signature_band(signature: int) -> String:
	if signature < 10:
		return "LOW"
	if signature < 25:
		return "ELEVATED"
	if signature < 50:
		return "LOUD"
	return "EXPOSED"


func _signature_color(band: String) -> Color:
	match band:
		"ELEVATED":
			return Color("d7b56d")
		"LOUD":
			return Color("d88472")
		"EXPOSED":
			return Color("c86583")
	return Color("5cc9e8")


# Future HUD: event choices, probe orders, mining controls and progression panels.
