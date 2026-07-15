class_name StarSystemData
extends Resource
## Pure data model. Gameplay systems can extend this without changing the visual node.

@export var id: int = -1
@export var system_name: String = "Unknown"
@export var position: Vector2 = Vector2.ZERO
@export var system_type: String = "Main Sequence"
@export_range(0, 100) var threat_level: int = 0
@export_range(0, 100) var resource_potential: int = 0
@export_range(0, 100) var energy_potential: int = 0
@export_range(0, 100) var matter_potential: int = 0
@export_range(0, 100) var data_potential: int = 0
@export_range(0, 3) var extraction_level: int = 0
@export var depleted: bool = false
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


func extraction_text() -> String:
	return "DEPLETED" if depleted else "%d / 3" % extraction_level


func system_description() -> String:
	match system_type:
		"Quiet Star":
			return "A stable star with low visible activity."
		"Mineral Belt":
			return "Dense orbital debris rich in extractable matter."
		"Pale Giant":
			return "High-output stellar body. Bright, useful, dangerous."
		"Dead World":
			return "Cold planets circle in silence."
		"Signal Ruin":
			return "Structured noise leaks from ancient debris."
		"Red Anomaly":
			return "Sensor readings refuse to stabilize."
		"Dark System":
			return "Almost no emissions. Almost."
		"Home System":
			return "The origin point. Its infrastructure is already accounted for."
	return "A distant system waits without explanation."


# Future data: probes, mining sites, advanced extraction, event flags, technology effects,
# and hidden Dark Forest threat data can be represented here.
