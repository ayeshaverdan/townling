extends Control
## Bootstrap entry scene for the Townling client.
##
## Hello-world plus a live health check against the backend, proving the
## client -> server path (Godot HTTPRequest -> DRF, design doc §18). The real
## game is a city-diorama hub of tappable buildings (design doc §5); this is
## the empty stage it will be built on.
##
## The backend URL is resolved at runtime, not baked in: on the web the client
## fetches <origin>/config.json (written by nginx from $TOWNLING_API_BASE), so
## the same build can point at any environment. Editor/native runs fall back to
## DEFAULT_API_BASE.

const DEFAULT_API_BASE := "http://localhost:8000"

var _api_base := DEFAULT_API_BASE

@onready var subtitle: Label = $Center/Layout/Subtitle
@onready var backend_status: Label = $Center/Layout/BackendStatus
@onready var config_request: HTTPRequest = $ConfigRequest
@onready var health_request: HTTPRequest = $HealthRequest


func _ready() -> void:
	var info := Engine.get_version_info()
	var version_string: String = info.get("string", "unknown")
	print("Townling client — hello from Godot %s" % version_string)
	subtitle.text = "Godot %s · hello world" % version_string

	config_request.request_completed.connect(_on_config_completed)
	health_request.request_completed.connect(_on_health_completed)
	_load_config()


func _load_config() -> void:
	# Only the web build ships a config.json (served same-origin, no CORS).
	# Elsewhere, go straight to the default backend URL.
	var origin := _web_origin()
	if origin.is_empty():
		_check_backend()
		return
	backend_status.text = "backend: loading config…"
	var err := config_request.request("%s/config.json" % origin)
	if err != OK:
		push_warning("config.json request failed (err %d); using default" % err)
		_check_backend()


func _web_origin() -> String:
	if OS.has_feature("web"):
		var origin: Variant = JavaScriptBridge.eval("window.location.origin", true)
		if typeof(origin) == TYPE_STRING:
			return origin
	return ""


func _on_config_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var payload: Variant = JSON.parse_string(body.get_string_from_utf8())
		if typeof(payload) == TYPE_DICTIONARY and payload.has("api_base"):
			_api_base = str(payload["api_base"])
			print("Loaded api_base from config.json: %s" % _api_base)
	else:
		push_warning("config.json unavailable (code %d); using default" % response_code)
	_check_backend()


func _check_backend() -> void:
	backend_status.text = "backend: checking…"
	var err := health_request.request("%s/api/health/" % _api_base)
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
