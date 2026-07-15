class_name GameState
extends Node
## Owns small global state. Future save/load and long-term progression can live here.

signal state_changed(current_cycle: int, cosmic_signature: int, contact_state: String)
signal log_message_added(message: String)
signal signature_increased(intensity: float)
signal resources_changed(energy: int, matter: int, data: int)

var current_cycle: int = 1
var cosmic_signature: int = 0
var contact_state := "SILENT"
var energy: int = 25
var matter: int = 10
var data: int = 0


func publish_initial_state() -> void:
	state_changed.emit(current_cycle, cosmic_signature, contact_state)
	resources_changed.emit(energy, matter, data)
	log_message_added.emit("The void remains quiet.")


func complete_passive_observation(system: StarSystemData) -> void:
	current_cycle += 1
	state_changed.emit(current_cycle, cosmic_signature, contact_state)
	log_message_added.emit("Passive observation completed. No transmission burst detected.")
	log_message_added.emit("%s resolves as a %s." % [system.system_name, system.system_type])


func complete_active_scan(system: StarSystemData) -> void:
	_advance_action(8, 1.0)
	log_message_added.emit("Active scan resolved mineral traces in %s." % system.system_name)
	log_message_added.emit("Signal bloom expanded from the home system.")


func complete_analysis(system: StarSystemData, result: Dictionary) -> void:
	var data_gain: int = int(result["data"])
	data += data_gain
	resources_changed.emit(energy, matter, data)
	_advance_action(int(result["signature"]), 0.32)
	if system.scanned:
		log_message_added.emit("Deep analysis extracted impossible geometry from %s. +%d DATA." % [system.system_name, data_gain])
	else:
		log_message_added.emit("Archived passive readings from %s. +%d DATA." % [system.system_name, data_gain])


func complete_extraction(system: StarSystemData, result: Dictionary) -> void:
	var energy_gain: int = int(result["energy"])
	var matter_gain: int = int(result["matter"])
	energy += energy_gain
	matter += matter_gain
	resources_changed.emit(energy, matter, data)
	_advance_action(int(result["signature"]), 0.78)
	log_message_added.emit("Matter harvest completed in %s. +%d ENERGY  +%d MATTER." % [system.system_name, energy_gain, matter_gain])
	if system.depleted:
		log_message_added.emit("Resource profile collapsed. %s is depleted." % system.system_name)
		log_message_added.emit("Dead systems are quiet. That is their only mercy.")
	elif system.extraction_level == 2:
		log_message_added.emit("Orbital extraction scars are now visible around %s." % system.system_name)
	elif (system.id + system.extraction_level) % 2 == 0:
		log_message_added.emit("Industrial heat blooms briefly in the dark.")


func _advance_action(signature_gain: int, pulse_intensity: float) -> void:
	var old_band: String = signature_band()
	current_cycle += 1
	cosmic_signature += signature_gain
	contact_state = _contact_state_for_signature()
	state_changed.emit(current_cycle, cosmic_signature, contact_state)
	signature_increased.emit(pulse_intensity)
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
