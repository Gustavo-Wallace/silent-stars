class_name ProbeService
extends RefCounted

static func risk(system: StarSystemData, signature: int, distance: float, modifier: float) -> float:
	var value: float = float(system.threat_level) / 160.0 + float(signature) / 180.0 + distance / 8000.0
	if system.system_type == "Red Anomaly" or system.system_type == "Dark System" or system.system_type == "Signal Ruin": value += 0.18
	return clampf(value * modifier, 0.05, 0.9)
