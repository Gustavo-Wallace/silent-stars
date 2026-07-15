class_name ObservatoryHUD
extends Control
## Presentation-only HUD. It receives selected data from Main via a signal connection.

@onready var details: Label = $DetailsPanel/Details


func display_system(data: StarSystemData) -> void:
	var status := data.status_text().capitalize()
	details.text = "%s\n\nTYPE       %s\nRESOURCES  %d%%\nTHREAT     %d%%\nSTATUS     %s" % [data.system_name, data.system_type, data.resource_potential, data.threat_level, status]


# Future UI additions: scan actions, probe controls, mining reports, signature meter,
# technology progression and narrative / Dark Forest event notifications.
