class_name ObservatoryHUD
extends Control
## Presentation-only HUD. It asks Main for actions through signals and never mutates map data.

signal passive_observe_requested
signal active_scan_requested
signal analyze_requested
signal extraction_requested

const MAX_LOG_MESSAGES := 5

@onready var telemetry: Label = $Telemetry
@onready var signature_value: Label = $SignatureMeter/Value
@onready var signature_fill: ColorRect = $SignatureMeter/Track/Fill
@onready var resource_readout: Label = $ResourceReadout
@onready var details: Label = $DetailsPanel/Details
@onready var action_hint: Label = $DetailsPanel/ActionHint
@onready var passive_button: Button = $DetailsPanel/PassiveObserve
@onready var scan_button: Button = $DetailsPanel/ActiveScan
@onready var analyze_button: Button = $DetailsPanel/AnalyzeData
@onready var extraction_button: Button = $DetailsPanel/BeginExtraction
@onready var log_entries: Label = $LogPanel/Entries

var selected_system: StarSystemData
var log_messages: Array[String] = []


func _ready() -> void:
	passive_button.pressed.connect(_on_passive_observe_pressed)
	scan_button.pressed.connect(_on_active_scan_pressed)
	analyze_button.pressed.connect(_on_analyze_pressed)
	extraction_button.pressed.connect(_on_extraction_pressed)
	passive_button.disabled = true
	scan_button.disabled = true
	analyze_button.disabled = true
	extraction_button.disabled = true


func display_system(data: StarSystemData) -> void:
	selected_system = data
	details.text = _details_for(data)
	passive_button.disabled = data.is_home or data.observed
	scan_button.disabled = data.is_home or data.scanned
	analyze_button.disabled = data.is_home or not data.observed
	extraction_button.disabled = data.is_home or not data.scanned or data.depleted
	if data.is_home:
		action_hint.text = "HOME SYSTEM — COMPLETE TELEMETRY AVAILABLE"
	elif data.depleted:
		action_hint.text = "RESOURCE PROFILE COLLAPSED — EXTRACTION UNAVAILABLE"
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
	resource_readout.text = "ENERGY  %03d\nMATTER  %03d\nDATA    %03d" % [energy, matter, data]


func add_log_message(message: String) -> void:
	log_messages.append("› " + message)
	if log_messages.size() > MAX_LOG_MESSAGES:
		log_messages.pop_front()
	log_entries.text = "\n".join(log_messages)


func _details_for(data: StarSystemData) -> String:
	if data.is_home:
		return "%s\n\nTYPE       %s\nENERGY     %d\nMATTER     %d\nDATA       %d\nTHREAT     %d%%\nEXTRACTION HOME\nSTATUS     HOME\n\n%s" % [data.system_name, data.system_type, data.energy_potential, data.matter_potential, data.data_potential, data.threat_level, data.system_description()]
	if not data.observed:
		return "%s\n\nTYPE       UNKNOWN\nENERGY     UNKNOWN\nMATTER     UNKNOWN\nDATA       UNKNOWN\nTHREAT     UNKNOWN\nEXTRACTION UNKNOWN\nSTATUS     UNOBSERVED\n\nA distant point without a stable profile." % data.display_name()
	if not data.scanned:
		return "%s\n\nTYPE       %s\nENERGY     %s ESTIMATE\nMATTER     %s ESTIMATE\nDATA       %s ESTIMATE\nTHREAT     %s\nEXTRACTION %s\nSTATUS     OBSERVED\n\n%s" % [data.system_name, data.system_type, _resource_band(data.energy_potential), _resource_band(data.matter_potential), _resource_band(data.data_potential), data.observed_threat_text(), data.extraction_text(), data.system_description()]
	return "%s\n\nTYPE       %s\nENERGY     %d\nMATTER     %d\nDATA       %d\nTHREAT     %d%%\nEXTRACTION %s\nSTATUS     SCANNED\n\n%s" % [data.system_name, data.system_type, data.energy_potential, data.matter_potential, data.data_potential, data.threat_level, data.extraction_text(), data.system_description()]


func _on_passive_observe_pressed() -> void:
	passive_observe_requested.emit()


func _on_active_scan_pressed() -> void:
	active_scan_requested.emit()


func _on_analyze_pressed() -> void:
	analyze_requested.emit()


func _on_extraction_pressed() -> void:
	extraction_requested.emit()


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
