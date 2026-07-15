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
@export var observed: bool = false
@export var scanned: bool = false
@export var callsign: String = "UNRESOLVED"


func status_text() -> String:
	if is_home:
		return "HOME"
	if scanned:
		return "SCANNED"
	return "OBSERVED" if observed else "UNOBSERVED"


func display_name() -> String:
	return system_name if is_home or observed or scanned else callsign


func resource_band() -> String:
	if resource_potential < 34:
		return "LOW"
	if resource_potential < 68:
		return "MEDIUM"
	return "HIGH"


func observed_threat_text() -> String:
	return "NO OBVIOUS ACTIVITY" if threat_level < 35 else "UNCLEAR"


# Future data: probes, mining sites, detailed scan results, event flags, technology effects,
# and hidden Dark Forest threat data can be represented here.
