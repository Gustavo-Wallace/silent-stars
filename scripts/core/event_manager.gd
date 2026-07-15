class_name EventManager
extends Node
## Generates compact, automatic arrival events. Choice branches can be added later.

var rng := RandomNumberGenerator.new()
var pending_event: EventData

func create_choice_event(system: StarSystemData, source_name: String, signature: int) -> EventData:
	var event := EventData.new()
	event.source = source_name
	if system.system_type == "Signal Ruin" or system.system_type == "Red Anomaly":
		event.title="Repeating Signal"; event.severity="MEDIUM"; event.description="A clean pulse repeats beneath local static. It is too deliberate to be weather."
		event.choices=[_choice("ARCHIVE SILENTLY","+2 DATA",{"data":2},"The signal was archived without reply."),_choice("DEEP DECODE","+5 DATA · +2 SIGNATURE",{"data":5,"signature":2},"The pattern opened in the noise."),_choice("BURN RECORDING","-1 ENERGY · -1 SIGNATURE",{"energy":-1,"signature":-1},"The recording was erased.")]
	elif system.system_type == "Mineral Belt" or system.system_type == "Dead World":
		event.title="Cold Debris Field"; event.severity="LOW"; event.description="Cold debris drifts in predictable arcs. Some of it is useful."
		event.choices=[_choice("COLLECT FRAGMENTS","+3 MATTER · +1 SIGNATURE",{"matter":3,"signature":1},"Fragments entered the hold."),_choice("IGNORE DEBRIS","NO EFFECT",{},"The debris continued its patient orbit."),_choice("SCAN COMPOSITION","+1 DATA · +1 SIGNATURE",{"data":1,"signature":1},"Composition archived.")]
	else:
		event.title="Unmapped Transit"; event.severity="HIGH" if signature >= 25 else "LOW"; event.description="The route behind you persists longer than it should."
		event.choices=[_choice("RECORD ROUTE","+2 DATA",{"data":2},"The route was recorded."),_choice("DELETE ROUTE","-1 SIGNATURE",{"signature":-1},"The route was deleted before it became a confession."),_choice("BROADCAST CORRECTION","+3 DATA · +2 SIGNATURE",{"data":3,"signature":2},"A correction entered the dark.")]
	pending_event = event
	return event

func choose(index: int, state: GameState) -> void:
	if pending_event == null or index < 0 or index >= pending_event.choices.size(): return
	var choice: EventChoiceData = pending_event.choices[index]
	if state.energy + int(choice.effects.get("energy",0)) < 0: state.add_log_message("Insufficient resources."); return
	state.apply_choice(choice.effects, choice.log_message)
	pending_event = null

func _choice(label_text: String, summary_text: String, effects: Dictionary, message: String) -> EventChoiceData:
	var choice := EventChoiceData.new()
	choice.label=label_text; choice.summary=summary_text; choice.effects=effects; choice.log_message=message
	return choice


func _ready() -> void:
	rng.seed = 24072026


func create_arrival_event(system: StarSystemData, cosmic_signature: int, risk_modifier: float = 1.0) -> ArrivalEventData:
	var candidates: Array[ArrivalEventData] = []
	candidates.append(_event("Silent Arrival", "Local space is quiet. Your instruments find only distance.", "No greeting detected."))
	if system.observed or system.system_type == "Signal Ruin":
		var data_gain := clampi(roundi(float(system.data_potential) / 38.0), 1, 3)
		candidates.append(_event("Weak Signal", "A weak pattern repeats beneath the stellar noise.", "+%d DATA archived." % data_gain, 0, 0, data_gain))
	if system.system_type == "Mineral Belt" or system.system_type == "Dead World" or system.matter_potential >= 65:
		var matter_gain := clampi(roundi(float(system.matter_potential) / 24.0), 2, 5)
		candidates.append(_event("Debris Cache", "Cold debris drifts in predictable arcs. Some of it is useful.", "+%d MATTER recovered." % matter_gain, 0, matter_gain))
	if system.system_type == "Pale Giant" or system.system_type == "Quiet Star":
		var energy_gain := clampi(roundi(float(system.energy_potential) / 25.0), 1, 4)
		candidates.append(_event("Stellar Drift", "The vessel harvests residual charge from the local stellar wind.", "+%d ENERGY collected." % energy_gain, energy_gain))
	if (system.threat_level >= 50 or cosmic_signature >= 10) and rng.randf() <= risk_modifier:
		candidates.append(_event("Sensor Ghost", "For one second, your sensors display another trajectory beside yours.", "+1 SIGNATURE.", 0, 0, 0, 1))
	if cosmic_signature >= 25 and rng.randf() <= risk_modifier:
		candidates.append(_event("Heat Bloom", "Your drive wake unfolds brighter than expected.", "+2 SIGNATURE.", 0, 0, 0, 2))
	if system.system_type == "Dark System" or system.system_type == "Dead World" or system.system_type == "Red Anomaly":
		candidates.append(_event("Dead Channel", "A recorded channel plays silence with impossible compression.", "No usable pattern recovered."))
	if (system.threat_level >= 75 or cosmic_signature >= 50) and rng.randf() <= risk_modifier:
		candidates.append(_event("Listening Shadow", "Something did not answer. Something adjusted.", "CONTACT STATUS: WATCHED.", 0, 0, 0, 0, "WATCHED"))
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _event(title_text: String, description_text: String, result_text: String, energy: int = 0, matter: int = 0, data: int = 0, signature: int = 0, contact: String = "") -> ArrivalEventData:
	var event := ArrivalEventData.new()
	event.title = title_text
	event.description = description_text
	event.result = result_text
	event.energy_delta = energy
	event.matter_delta = matter
	event.data_delta = data
	event.signature_delta = signature
	event.contact_override = contact
	return event


# Future: choices, weighted narrative chains, technology conditions and threat escalation.
