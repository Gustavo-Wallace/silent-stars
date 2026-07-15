class_name GameState
extends Node
## Owns small global state. Future save/load and long-term progression can live here.

signal state_changed(current_cycle: int, cosmic_signature: int, contact_state: String)
signal log_message_added(message: String)
signal signature_increased(intensity: float)

var current_cycle: int = 1
var cosmic_signature: int = 0
var contact_state := "SILENT"


func publish_initial_state() -> void:
	state_changed.emit(current_cycle, cosmic_signature, contact_state)
	log_message_added.emit("The void remains quiet.")


func complete_passive_observation(system: StarSystemData) -> void:
	current_cycle += 1
	state_changed.emit(current_cycle, cosmic_signature, contact_state)
	log_message_added.emit("Passive observation completed. No transmission burst detected.")
	log_message_added.emit("%s resolves as a %s." % [system.system_name, system.system_type])


func complete_active_scan(system: StarSystemData) -> void:
	var old_band := signature_band()
	current_cycle += 1
	cosmic_signature += 8
	contact_state = _contact_state_for_signature()
	state_changed.emit(current_cycle, cosmic_signature, contact_state)
	log_message_added.emit("Active scan resolved mineral traces in %s." % system.system_name)
	log_message_added.emit("Signal bloom expanded from the home system.")
	signature_increased.emit(1.0)
	if old_band != signature_band():
		log_message_added.emit(_signature_threshold_message())


func signature_band() -> String:
	if cosmic_signature < 10:
		return "LOW"
	if cosmic_signature < 25:
		return "ELEVATED"
	if cosmic_signature < 50:
		return "LOUD"
	return "EXPOSED"


func _contact_state_for_signature() -> String:
	if cosmic_signature < 25:
		return "SILENT"
	if cosmic_signature < 50:
		return "UNCERTAIN"
	return "EXPOSED"


func _signature_threshold_message() -> String:
	match signature_band():
		"ELEVATED":
			return "Background noise rises around your origin point."
		"LOUD":
			return "Your signal footprint is no longer negligible."
		"EXPOSED":
			return "Something distant may have heard you."
	return "The void remains quiet."


# Future: technology modifiers, long-term detection, narrative events and saves.
