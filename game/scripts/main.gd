extends Control
## Bootstrap entry scene for the Townling client.
##
## Hello-world plus a live health check against the backend, proving the
## client -> server path (Godot HTTPRequest -> DRF, design doc §18). The real
## game is a city-diorama hub of tappable buildings (design doc §5); this is
## the empty stage it will be built on.

## Backend base URL. The web build is served from :8080 and the API from :8000
## in local dev; override here (or later via an exported config) per environment.
const API_BASE := "http://localhost:8000"

@onready var subtitle: Label = $Center/Layout/Subtitle
@onready var backend_status: Label = $Center/Layout/BackendStatus
@onready var health_request: HTTPRequest = $HealthRequest


func _ready() -> void:
	var info := Engine.get_version_info()
	var version_string: String = info.get("string", "unknown")
	print("Townling client — hello from Godot %s" % version_string)
	subtitle.text = "Godot %s · hello world" % version_string

	health_request.request_completed.connect(_on_health_completed)
	_check_backend()


func _check_backend() -> void:
	backend_status.text = "backend: checking…"
	var err := health_request.request("%s/api/health/" % API_BASE)
	if err != OK:
		backend_status.text = "backend: request failed (err %d)" % err


func _on_health_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		backend_status.text = "backend: unreachable"
		push_warning("Health check failed (result %d, code %d)" % [result, response_code])
		return

	var payload: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(payload) != TYPE_DICTIONARY or payload.get("status") != "ok":
		backend_status.text = "backend: unexpected response"
		return

	backend_status.text = "backend: %s · Django %s" % [payload["status"], payload.get("django", "?")]
	print("Backend healthy: %s" % payload)
