class_name InfrastructureManager
extends Node
signal catalog_changed(items: Array[InfrastructureData])
signal structure_built(system: StarSystemData)
var items: Array[InfrastructureData] = []
var state: GameState

func configure(game_state: GameState) -> void:
	state = game_state
	items=[_item("listening_outpost","Listening Outpost","Observation","A cold observatory that listens more than it asks.",2,4,6,1,"analysis",2.0),_item("silent_extractor","Silent Extractor","Industry","Harvest rigs tuned to chew softly.",4,8,4,2,"extraction",1.25),_item("probe_dock","Probe Dock","Probe","A small hangar for machines meant to disappear.",3,7,5,2,"probe",1.0),_item("blackout_beacon","Blackout Beacon","Silence","A beacon that teaches machines when to go dark.",5,5,10,0,"blackout",1.0),_item("data_vault","Data Vault","Analysis","An archive buried under redundant silence.",2,5,12,1,"data",1.0),_item("warning_lattice","Warning Lattice","Survival","Thin sensors arranged to notice attention.",6,6,8,2,"warning",1.0)]
	catalog_changed.emit(items)

func build(id: String, system: StarSystemData, current_id: int) -> void:
	var item := _find(id)
	if item == null or system.id != current_id: state.add_log_message("Local presence required."); return
	if not system.scanned: state.add_log_message("System scan required."); return
	if system.built_structures.has(id): state.add_log_message("Structure already exists in this system."); return
	if state.energy < item.cost_energy or state.matter < item.cost_matter or state.data < item.cost_data: state.add_log_message("Insufficient resources."); return
	state.energy-=item.cost_energy; state.matter-=item.cost_matter; state.data-=item.cost_data; state.resources_changed.emit(state.energy,state.matter,state.data)
	system.built_structures.append(id); system.infrastructure_level+=1; system.local_signature+=item.local_signature_gain
	if item.effect_type=="blackout": state.reduce_signature(1)
	if item.effect_type=="probe": state.probes_available+=1; state.probes_changed.emit(state.probes_available)
	state.apply_choice({"signature":1}, "%s assembled in cold orbit." % item.structure_name)
	structure_built.emit(system); catalog_changed.emit(items)

func _item(id:String,name:String,cat:String,desc:String,e:int,m:int,d:int,s:int,effect:String,value:float)->InfrastructureData:
	var item:=InfrastructureData.new(); item.structure_id=id; item.structure_name=name; item.category=cat; item.description=desc; item.cost_energy=e; item.cost_matter=m; item.cost_data=d; item.local_signature_gain=s; item.effect_type=effect; item.effect_value=value; return item
func _find(id:String)->InfrastructureData:
	for item in items: if item.structure_id==id: return item
	return null
