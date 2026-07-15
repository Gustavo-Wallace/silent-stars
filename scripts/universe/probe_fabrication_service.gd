class_name ProbeFabricationService
extends RefCounted

static func fabricate_cost(has_dock: bool) -> Dictionary:
	return {"energy": 1 if not has_dock else 0, "matter": 4 if not has_dock else 3, "data": 1}

static func bay_cost(upgrades: int) -> Dictionary:
	return {"energy": 2 + upgrades, "matter": 10 + upgrades * 5, "data": 4 + upgrades * 2}
