class_name GameState
extends Node
## Owns small global state. Future save/load and long-term progression can live here.

signal state_changed(current_cycle: int, cosmic_signature: int, contact_state: String)
signal log_message_added(message: String)
signal signature_increased(intensity: float)
signal resources_changed(energy: int, matter: int, data: int)
signal travel_status_changed(current_system_id: int, is_traveling: bool)
signal probes_changed(count: int)
signal void_changed(attention: int, pressure: String)

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
var scan_signature_modifier: float = 1.0
var travel_signature_modifier: float = 1.0
var travel_energy_modifier: float = 1.0
var extraction_yield_modifier: float = 1.0
var analysis_yield_modifier: float = 1.0
var passive_observe_data_bonus: int = 0
var event_risk_modifier: float = 1.0
var probes_available: int = 2
var probes_launched_total: int = 0
var probes_lost_total: int = 0
var probe_signature_modifier: float = 1.0
var void_attention: int = 0
var void_pressure := "DORMANT"

func launch_probe() -> bool:
	if probes_available <= 0: add_log_message("No probes available."); return false
	if energy < 1: add_log_message("Insufficient energy for probe launch."); return false
	probes_available -= 1; probes_launched_total += 1; energy -= 1
	probes_changed.emit(probes_available)
	resources_changed.emit(energy, matter, data)
	_advance_action(_modified_signature(1, probe_signature_modifier), 0.22)
	return true

func apply_probe_result(system: StarSystemData, result: String, data_gain: int, matter_gain: int, signature_gain: int, watched: bool) -> void:
	data += data_gain; matter += matter_gain
	resources_changed.emit(energy, matter, data)
	if signature_gain > 0: _advance_signature_only(signature_gain, 0.3)
	if watched: forced_contact_state = "WATCHED"; _refresh_contact_state(); state_changed.emit(current_cycle, cosmic_signature, contact_state)
	add_log_message(result)


func publish_initial_state() -> void:
	state_changed.emit(current_cycle, cosmic_signature, contact_state)
	resources_changed.emit(energy, matter, data)
	probes_changed.emit(probes_available)
	void_changed.emit(void_attention, void_pressure)
	log_message_added.emit("The void remains quiet.")


func add_log_message(message: String) -> void:
	log_message_added.emit(message)

func add_void_attention(amount: int) -> void:
	var previous := void_pressure
	void_attention = maxi(0, void_attention + amount)
	if void_attention < 10: void_pressure = "DORMANT"
	elif void_attention < 25: void_pressure = "LISTENING"
	elif void_attention < 50: void_pressure = "SEARCHING"
	elif void_attention < 80: void_pressure = "HUNTING"
	else: void_pressure = "CONVERGING"
	void_changed.emit(void_attention, void_pressure)
	if previous != void_pressure: add_log_message("VOID: %s." % void_pressure)

func enter_blackout() -> void:
	if energy < 2 or data < 2: add_log_message("Insufficient resources for blackout."); return
	energy -= 2; data -= 2; current_cycle += 1
	resources_changed.emit(energy,matter,data); reduce_signature(2); add_void_attention(-3)
	add_log_message("All outgoing systems dimmed. Civilization became rumor.")

func apply_choice(effects: Dictionary, message: String) -> void:
	energy += int(effects.get("energy", 0))
	matter += int(effects.get("matter", 0))
	data = maxi(0, data + int(effects.get("data", 0)))
	resources_changed.emit(energy, matter, data)
	var signature_delta: int = int(effects.get("signature", 0))
	if signature_delta > 0: _advance_signature_only(signature_delta, 0.3)
	elif signature_delta < 0: reduce_signature(-signature_delta)
	if effects.has("contact"):
		forced_contact_state = str(effects["contact"])
		_refresh_contact_state()
		state_changed.emit(current_cycle, cosmic_signature, contact_state)
	add_log_message(message)


func complete_passive_observation(system: StarSystemData) -> void:
	current_cycle += 1
	state_changed.emit(current_cycle, cosmic_signature, contact_state)
	log_message_added.emit("Passive observation completed. No transmission burst detected.")
	log_message_added.emit("%s resolves as a %s." % [system.system_name, system.system_type])
	if passive_observe_data_bonus > 0:
		data += passive_observe_data_bonus
		resources_changed.emit(energy, matter, data)
		log_message_added.emit("Passive array archived +%d DATA." % passive_observe_data_bonus)


func complete_active_scan(system: StarSystemData) -> void:
	_advance_action(_modified_signature(8, scan_signature_modifier), 1.0)
	log_message_added.emit("Active scan resolved mineral traces in %s." % system.system_name)
	log_message_added.emit("Signal bloom expanded from the home system.")
	if cosmic_signature >= 10 or system.threat_level >= 60: add_void_attention(1)


func complete_analysis(system: StarSystemData, result: Dictionary) -> void:
	var data_gain: int = maxi(1, roundi(float(int(result["data"])) * analysis_yield_modifier))
	data += data_gain
	resources_changed.emit(energy, matter, data)
	_advance_action(int(result["signature"]), 0.32)
	if system.scanned:
		log_message_added.emit("Deep analysis extracted impossible geometry from %s. +%d DATA." % [system.system_name, data_gain])
	else:
		log_message_added.emit("Archived passive readings from %s. +%d DATA." % [system.system_name, data_gain])


func complete_extraction(system: StarSystemData, result: Dictionary) -> void:
	var energy_gain: int = maxi(1, roundi(float(int(result["energy"])) * extraction_yield_modifier))
	var matter_gain: int = maxi(1, roundi(float(int(result["matter"])) * extraction_yield_modifier))
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
	var travel_cost: int = TravelService.energy_cost(travel_energy_modifier)
	if energy < travel_cost:
		log_message_added.emit("Insufficient energy for active operation.")
		return false
	energy -= travel_cost
	resources_changed.emit(energy, matter, data)
	is_traveling = true
	_advance_action(_modified_signature(TravelService.signature_for_distance(distance), travel_signature_modifier), 0.42)
	travel_status_changed.emit(current_system_id, true)
	log_message_added.emit("Course plotted toward %s." % destination.system_name)
	log_message_added.emit("The vessel crossed a silent interval.")
	if distance >= 800.0: add_void_attention(1 if distance < 1600.0 else 2)
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


func reduce_signature(amount: int) -> void:
	cosmic_signature = maxi(0, cosmic_signature - amount)
	_refresh_contact_state()
	state_changed.emit(current_cycle, cosmic_signature, contact_state)


func _modified_signature(base: int, modifier: float) -> int:
	return maxi(1, roundi(float(base) * modifier))


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
