class_name GameState
extends Node
## Owns small global state. Future save/load and long-term progression can live here.

signal state_changed(current_cycle: int, cosmic_signature: int, contact_state: String)
signal log_message_added(message: String)
signal signature_increased(intensity: float)
signal resources_changed(energy: int, matter: int, data: int)
signal travel_status_changed(current_system_id: int, is_traveling: bool)

var current_cycle: int = 1
var cosmic_signature: int = 0
var contact_state := "SILENT"
var energy: int = 25
var matter: int = 10
var data: int = 0
var current_system_id: int = 0
var home_system_id: int = 0
var is_traveling := false
var forced_contact_state := ""


func publish_initial_state() -> void:
	state_changed.emit(current_cycle, cosmic_signature, contact_state)
	resources_changed.emit(energy, matter, data)
	log_message_added.emit("The void remains quiet.")


func add_log_message(message: String) -> void:
	log_message_added.emit(message)


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


func begin_travel(destination: StarSystemData, distance: float) -> bool:
	if is_traveling:
		return false
	if energy < TravelService.ENERGY_COST:
		log_message_added.emit("Insufficient energy for active operation.")
		return false
	energy -= TravelService.ENERGY_COST
	resources_changed.emit(energy, matter, data)
	is_traveling = true
	_advance_action(TravelService.signature_for_distance(distance), 0.42)
	travel_status_changed.emit(current_system_id, true)
	log_message_added.emit("Course plotted toward %s." % destination.system_name)
	log_message_added.emit("The vessel crossed a silent interval.")
	return true


func complete_travel(destination: StarSystemData) -> void:
	current_system_id = destination.id
	is_traveling = false
	travel_status_changed.emit(current_system_id, false)
	log_message_added.emit("Arrival confirmed. No greeting detected.")
	log_message_added.emit("Engines dimmed before entering local orbit.")


func apply_arrival_event(event: ArrivalEventData) -> void:
	energy += event.energy_delta
	matter += event.matter_delta
	data = max(0, data + event.data_delta)
	resources_changed.emit(energy, matter, data)
	if event.signature_delta > 0:
		_advance_signature_only(event.signature_delta, 0.36)
	if not event.contact_override.is_empty():
		forced_contact_state = event.contact_override
		_refresh_contact_state()
		state_changed.emit(current_cycle, cosmic_signature, contact_state)
	log_message_added.emit("%s — %s" % [event.title, event.result])


func _advance_action(signature_gain: int, pulse_intensity: float) -> void:
	var old_band: String = signature_band()
	current_cycle += 1
	cosmic_signature += signature_gain
	_refresh_contact_state()
	state_changed.emit(current_cycle, cosmic_signature, contact_state)
	signature_increased.emit(pulse_intensity)
	if old_band != signature_band():
		log_message_added.emit(_signature_threshold_message())


func _advance_signature_only(signature_gain: int, pulse_intensity: float) -> void:
	var old_band: String = signature_band()
	cosmic_signature += signature_gain
	_refresh_contact_state()
	state_changed.emit(current_cycle, cosmic_signature, contact_state)
	signature_increased.emit(pulse_intensity)
	if old_band != signature_band():
		log_message_added.emit(_signature_threshold_message())


func _refresh_contact_state() -> void:
	var calculated := _contact_state_for_signature()
	if forced_contact_state == "WATCHED" or forced_contact_state == "COMPROMISED":
		contact_state = forced_contact_state
	else:
		contact_state = calculated


func signature_band() -> String:
	if cosmic_signature < 10:
		return "LOW"
	if cosmic_signature < 25:
		return "ELEVATED"
	if cosmic_signature < 50:
		return "LOUD"
	return "EXPOSED"


func _contact_state_for_signature() -> String:
	if cosmic_signature < 10:
		return "SILENT"
	if cosmic_signature < 50:
		return "UNEASY"
	return "WATCHED"


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
