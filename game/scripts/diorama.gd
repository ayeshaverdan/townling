extends Node3D
## First isometric town diorama (design doc §5, §18 visual-direction update).
##
## Low-poly 3D on a fixed orthographic (isometric) camera. Buildings, roads and
## props are KayKit City Builder Bits tiles — every tile is a 2x2 unit,
## origin-centred, sitting on y=0 — placed procedurally on a grid. This is a
## static first look at the 2.5D direction; interaction/UI come later.
##
## The backend health check from the bootstrap is retained as an overlay, so the
## client -> server path (design doc §18) still proves out on this scene.

const CITY := "res://assets/city/Assets/gltf/"
const TILE := 2.0  # world units per grid cell

## Grid layout. Keys are Vector2i(col, row); value is the building mesh name.
## Empty cells become ground; row 2 is the street.
const BUILDINGS := {
	Vector2i(0, 0): "building_C",
	Vector2i(1, 0): "building_D",
	Vector2i(3, 0): "building_G",
	Vector2i(4, 0): "building_H",
	Vector2i(0, 4): "building_E",
	Vector2i(2, 4): "building_B",
	Vector2i(4, 4): "building_F",
}
const COLS := 5
const ROWS := 5
const ROAD_ROW := 2

const DEFAULT_API_BASE := "http://localhost:8000"
var _api_base := DEFAULT_API_BASE

@onready var camera: Camera3D = $Camera
@onready var sun: DirectionalLight3D = $Sun
@onready var world: Node3D = $World
@onready var backend_status: Label = $UI/Banner/BackendStatus
@onready var config_request: HTTPRequest = $ConfigRequest
@onready var health_request: HTTPRequest = $HealthRequest


func _ready() -> void:
	_setup_light()
	_build_town()
	_setup_camera()

	# Offscreen capture path for previews/CI (inert unless --shot is passed).
	if "--shot" in OS.get_cmdline_args():
		_capture_and_quit()
		return

	config_request.request_completed.connect(_on_config_completed)
	health_request.request_completed.connect(_on_health_completed)
	_load_config()


func _capture_and_quit() -> void:
	# Let a few frames render so meshes/lighting are present, then save.
	for _i in range(6):
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://shot.png")
	get_tree().quit()


# --- Scene construction ----------------------------------------------------

func _setup_light() -> void:
	sun.rotation = Vector3(deg_to_rad(-50.0), deg_to_rad(-55.0), 0.0)


func _build_town() -> void:
	for row in ROWS:
		for col in COLS:
			var cell := Vector2i(col, row)
			if BUILDINGS.has(cell):
				_place("%s%s.gltf" % [CITY, BUILDINGS[cell]], col, row)
			elif row == ROAD_ROW:
				# road_straight runs along Z by default; rotate to run along X.
				_place("%sroad_straight.gltf" % CITY, col, row, 90.0)
			else:
				_place("%sbase.gltf" % CITY, col, row)

	# A little life on the street and the lots.
	_place("%scar_sedan.gltf" % CITY, 1, ROAD_ROW, 90.0)
	_place("%scar_taxi.gltf" % CITY, 3, ROAD_ROW, -90.0)
	_place("%sbush.gltf" % CITY, 2, 1)
	_place("%sbush.gltf" % CITY, 1, 3)
	_place("%sbush.gltf" % CITY, 3, 3)
	_place("%sstreetlight.gltf" % CITY, 0, 1, 180.0)
	_place("%sstreetlight.gltf" % CITY, 4, 3)


## Instance a tile at grid (col, row), optionally rotated about Y (degrees).
func _place(path: String, col: int, row: int, rot_deg: float = 0.0) -> void:
	var packed: Resource = load(path)
	if packed == null:
		push_warning("Missing asset: %s" % path)
		return
	var inst: Node3D = packed.instantiate()
	inst.position = Vector3(col * TILE, 0.0, row * TILE)
	inst.rotation.y = deg_to_rad(rot_deg)
	world.add_child(inst)


func _setup_camera() -> void:
	# Centre of the grid footprint; lift the aim point so the block sits
	# vertically centred in the tall portrait frame rather than low.
	var target := Vector3((COLS - 1) * TILE * 0.5, 3.0, (ROWS - 1) * TILE * 0.5)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 13.0  # tighter framing → more presence
	# Classic isometric vantage: up and off one corner, looking at the centre.
	camera.position = target + Vector3(14.0, 15.0, 14.0)
	camera.look_at(target, Vector3.UP)


# --- Backend health overlay (retained from bootstrap) ----------------------

func _load_config() -> void:
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
		return
	var payload: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(payload) != TYPE_DICTIONARY or payload.get("status") != "ok":
		backend_status.text = "backend: unexpected response"
		return
	backend_status.text = "backend: %s · Django %s" % [payload["status"], payload.get("django", "?")]
