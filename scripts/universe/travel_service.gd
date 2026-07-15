class_name TravelService
extends RefCounted
## Stateless travel balance rules. Future engines and technologies can modify these values.

const ENERGY_COST: int = 2


static func energy_cost(modifier: float) -> int:
	return maxi(1, ceili(float(ENERGY_COST) * modifier))


static func signature_for_distance(distance: float) -> int:
	if distance < 800.0:
		return 1
	if distance < 1600.0:
		return 2
	return 3
