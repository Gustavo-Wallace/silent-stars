class_name StarSystemData
extends Resource
## Pure data model. Gameplay systems can extend this without changing the visual node.

@export var id: int = -1
@export var system_name: String = "Unknown"
@export var position: Vector2 = Vector2.ZERO
@export var system_type: String = "Main Sequence"
@export_range(0, 100) var threat_level: int = 0
@export_range(0, 100) var resource_potential: int = 0
@export var is_home: bool = false
@export var discovered: bool = true
@export var scanned: bool = false


func status_text() -> String:
	if is_home:
		return "HOME"
	return "SCANNED" if scanned else "UNSCANNED"


# Future data: probes, mining sites, scan results, event flags, technology effects,
# and hidden Dark Forest threat data can be represented here.
