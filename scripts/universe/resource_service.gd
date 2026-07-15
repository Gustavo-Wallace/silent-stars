class_name ResourceService
extends RefCounted
## Stateless economy rules. Future technologies can modify these yields without changing UI or map code.


static func analyze(system: StarSystemData) -> Dictionary:
	var divisor: float = 18.0 if system.scanned else 40.0
	var minimum: int = 2 if system.scanned else 1
	var data_gain: int = clampi(roundi(float(system.data_potential) / divisor), minimum, 6)
	var signature_gain: int = 2 if system.scanned else 1
	return {"data": data_gain, "signature": signature_gain}


static func extract(system: StarSystemData) -> Dictionary:
	var efficiency: float = 1.0 - float(system.extraction_level) * 0.23
	var energy_gain: int = maxi(2, roundi(float(system.energy_potential) / 13.0 * efficiency))
	var matter_gain: int = maxi(2, roundi(float(system.matter_potential) / 13.0 * efficiency))
	var signature_gain: int = 5 + system.extraction_level
	system.extraction_level += 1
	if system.extraction_level >= 3:
		system.extraction_level = 3
		system.depleted = true
	return {"energy": energy_gain, "matter": matter_gain, "signature": signature_gain}


# Future: infrastructure, probes, technologies and threat effects may alter yield, cost and depletion.
