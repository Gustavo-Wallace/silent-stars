extends Node2D
## Composition root. Future game-state, progression and narrative services belong here.

@onready var universe_map: UniverseMap = $UniverseMap
@onready var hud: ObservatoryHUD = $Interface/HUD


func _ready() -> void:
	# The map owns system data; Main simply connects independent presentation layers.
	universe_map.system_selected.connect(hud.display_system)


# Future integration points: cosmic signature, time cycles, technology progression,
# Dark Forest threats and narrative events should coordinate here without coupling UI to map generation.
