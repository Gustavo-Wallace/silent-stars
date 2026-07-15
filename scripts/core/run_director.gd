class_name RunDirector
extends Node
signal objective_changed(text: String)
signal protocol_changed(text: String, ready: bool)
signal run_finished(victory: bool, report: String)

var state: GameState
var technologies: TechnologyManager
var infrastructure: InfrastructureManager
var universe: UniverseMap
var run_state := "RUNNING"
const TARGET_CYCLE := 40

func configure(game_state: GameState, technology_manager: TechnologyManager, infrastructure_manager: InfrastructureManager, map: UniverseMap) -> void:
	state=game_state; technologies=technology_manager; infrastructure=infrastructure_manager; universe=map
	refresh()

func refresh() -> void:
	if run_state != "RUNNING": return
	if state.current_cycle > TARGET_CYCLE: state.add_void_attention(1)
	var silence_tech := _silence_tech_count()
	var quiet_infra := _quiet_infra_count()
	var ready := state.data >= 50 and silence_tech >= 2 and quiet_infra >= 2 and state.void_pressure != "CONVERGING"
	protocol_changed.emit("SILENT PROTOCOL\n[%s] 50 DATA\n[%s] 2 SILENCE / SURVIVAL TECH\n[%s] 2 QUIET INFRASTRUCTURES\n[%s] VOID BELOW CONVERGING" % [_check(state.data>=50),_check(silence_tech>=2),_check(quiet_infra>=2),_check(state.void_pressure!="CONVERGING")],ready)
	objective_changed.emit(_objective(ready,silence_tech,quiet_infra))
	if state.void_pressure == "CONVERGING" and state.signature_band() == "EXPOSED" and state.contact_state == "COMPROMISED":
		run_state="DEFEAT"; run_finished.emit(false,"LOCATION INFERRED\nThe dark did not answer. It arrived.")

func execute_protocol() -> void:
	refresh()
	var ready := state.data >= 50 and _silence_tech_count() >= 2 and _quiet_infra_count() >= 2 and state.void_pressure != "CONVERGING"
	if not ready: state.add_log_message("Silent Protocol requirements incomplete."); return
	run_state="VICTORY"; run_finished.emit(true,"SILENT PROTOCOL EXECUTED\nYour civilization did not conquer the stars. It became indistinguishable from them.")

func _silence_tech_count() -> int:
	var count:=0
	for tech in technologies.technologies:
		if tech.researched and (tech.category=="Silence" or tech.category=="Survival"): count+=1
	return count
func _quiet_infra_count() -> int:
	var count:=0
	for system in universe.systems:
		for id in system.built_structures:
			if id=="blackout_beacon" or id=="warning_lattice" or id=="listening_outpost" or id=="data_vault": count+=1
	return count
func _check(value: bool) -> String: return "x" if value else " "
func _objective(ready: bool, tech: int, infra: int) -> String:
	if ready: return "OBJECTIVE: Execute Silent Protocol"
	if state.data < 20: return "OBJECTIVE: Gather 20 DATA"
	if tech < 2: return "OBJECTIVE: Research Silence / Survival"
	if infra < 2: return "OBJECTIVE: Build a quiet network"
	return "OBJECTIVE: Secure 50 DATA"
