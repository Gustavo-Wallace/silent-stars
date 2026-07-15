class_name ArrivalEventData
extends Resource
## Data-only arrival event. Future choice-based events can extend this resource.

var title: String = "Silent Arrival"
var description: String = "Local space is quiet. Your instruments find only distance."
var result: String = "No change detected."
var energy_delta: int = 0
var matter_delta: int = 0
var data_delta: int = 0
var signature_delta: int = 0
var contact_override: String = ""

