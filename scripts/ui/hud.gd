class_name ObservatoryHUD
extends Control
## Presentation-only HUD. It asks Main for actions through signals and never mutates map data.

signal passive_observe_requested
signal active_scan_requested

const MAX_LOG_MESSAGES := 5

@onready var telemetry: Label = $Telemetry
@onready var signature_value: Label = $SignatureMeter/Value
@onready var signature_fill: ColorRect = $SignatureMeter/Track/Fill
@onready var details: Label = $DetailsPanel/Details
@onready var action_hint: Label = $DetailsPanel/ActionHint
@onready var passive_button: Button = $DetailsPanel/PassiveObserve
@onready var scan_button: Button = $DetailsPanel/ActiveScan
@onready var log_entries: Label = $LogPanel/Entries

var selected_system: StarSystemData
var log_messages: Array[String] = []


func _ready() -> void:
	passive_button.pressed.connect(_on_passive_observe_pressed)
	scan_button.pressed.connect(_on_active_scan_pressed)
	passive_button.disabled = true
	scan_button.disabled = true


func display_system(data: StarSystemData) -> void:
	selected_system = data
	details.text = _details_for(data)
	passive_button.disabled = data.is_home or data.observed
	scan_button.disabled = data.is_home or data.scanned
	if data.is_home:
		action_hint.text = "HOME SYSTEM — COMPLETE TELEMETRY AVAILABLE"
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


func add_log_message(message: String) -> void:
	log_messages.append("› " + message)
	if log_messages.size() > MAX_LOG_MESSAGES:
		log_messages.pop_front()
	log_entries.text = "\n".join(log_messages)


func _details_for(data: StarSystemData) -> String:
	if data.is_home:
		return "%s\n\nTYPE       %s\nRESOURCES  %d%%\nTHREAT     %d%%\nSTATUS     HOME" % [data.system_name, data.system_type, data.resource_potential, data.threat_level]
	if not data.observed:
		return "%s\n\nTYPE       UNKNOWN\nRESOURCES  UNKNOWN\nTHREAT     UNKNOWN\nSTATUS     UNOBSERVED" % data.display_name()
	if not data.scanned:
		return "%s\n\nTYPE       %s\nRESOURCES  %s ESTIMATE\nTHREAT     %s\nSTATUS     OBSERVED" % [data.system_name, data.system_type, data.resource_band(), data.observed_threat_text()]
	return "%s\n\nTYPE       %s\nRESOURCES  %d%%\nTHREAT     %d%%\nSTATUS     SCANNED" % [data.system_name, data.system_type, data.resource_potential, data.threat_level]


func _on_passive_observe_pressed() -> void:
	passive_observe_requested.emit()


func _on_active_scan_pressed() -> void:
	active_scan_requested.emit()


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
