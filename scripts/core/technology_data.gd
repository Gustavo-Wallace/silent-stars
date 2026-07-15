class_name TechnologyData
extends Resource

var technology_id: String = ""
var technology_name: String = ""
var description: String = ""
var category: String = ""
var cost_energy: int = 0
var cost_matter: int = 0
var cost_data: int = 0
var researched := false
var prerequisites: PackedStringArray = []
var effect_type: String = ""
var effect_value: float = 0.0

