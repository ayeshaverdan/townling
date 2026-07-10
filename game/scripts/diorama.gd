extends Node3D
## Townling town diorama (design doc §5, §18 visual-direction update).
##
## Low-poly 3D on a fixed orthographic (isometric) camera. The six Band-B
## landmark buildings (spec §5 / design doc §5) are placed on a 2x2-unit grid
## from KayKit City Builder tiles, each recoloured toward the Townling palette
## and captioned with a floating label. Soft lighting for a storybook feel.
##
## The backend health check from the bootstrap is retained as a UI overlay.

const CITY := "res://assets/city/Assets/gltf/"
const TILE := 2.0  # world units per grid cell

## The six launch landmarks. Each: display name, building mesh, grid cell, and
## a Townling-palette skin (a luminance-colorized copy of the KayKit atlas in
## assets/city/townling/ — keeps windows/roofs/shopfronts, recolours the hue).
const SKINS := "res://assets/city/townling/"
const LANDMARKS := [
	{"name": "Bank", "mesh": "building_G", "cell": Vector2i(0, 0), "skin": "bank"},
	{"name": "School", "mesh": "building_E", "cell": Vector2i(2, 0), "skin": "school"},
	{"name": "Workplace", "mesh": "building_H", "cell": Vector2i(4, 0), "skin": "workplace"},
	{"name": "Home", "mesh": "building_B", "cell": Vector2i(0, 4), "skin": "home"},
	{"name": "Shop", "mesh": "building_A", "cell": Vector2i(2, 4), "skin": "shop"},
	{"name": "Notice Board", "mesh": "building_D", "cell": Vector2i(4, 4), "skin": "noticeboard"},
]
## Mesh heights (world units) for label placement, from the glTF bounds.
const HEIGHTS := {
	"building_A": 1.65, "building_B": 1.65, "building_D": 2.97,
	"building_E": 2.35, "building_G": 2.98, "building_H": 3.05,
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

	if "--shot" in OS.get_cmdline_args():
		_capture_and_quit()
		return

	config_request.request_completed.connect(_on_config_completed)
	health_request.request_completed.connect(_on_health_completed)
	_load_config()


func _capture_and_quit() -> void:
	for _i in range(6):
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://shot.png")
	get_tree().quit()


# --- Scene construction ----------------------------------------------------

func _setup_light() -> void:
	# Soft, warm key light with a well-lit ambient fill so shadows stay gentle.
	sun.rotation = Vector3(deg_to_rad(-50.0), deg_to_rad(-55.0), 0.0)
	sun.light_energy = 0.6
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.shadow_enabled = true
	sun.shadow_blur = 2.0


func _build_town() -> void:
	var landmark_cells := {}
	for lm in LANDMARKS:
		landmark_cells[lm["cell"]] = lm

	# Ground + street first.
	for row in ROWS:
		for col in COLS:
			var cell := Vector2i(col, row)
			if landmark_cells.has(cell):
				continue
			if row == ROAD_ROW:
				_place("%sroad_straight.gltf" % CITY, col, row, 90.0)
			else:
				_place("%sbase.gltf" % CITY, col, row)

	# Landmarks: recoloured skin + floating label.
	for lm in LANDMARKS:
		var cell: Vector2i = lm["cell"]
		var inst := _place("%s%s.gltf" % [CITY, lm["mesh"]], cell.x, cell.y)
		if inst:
			_skin(inst, "%s%s.png" % [SKINS, lm["skin"]])
			_add_label(inst, lm["name"], HEIGHTS.get(lm["mesh"], 3.0))

	# A little life on the street and lots.
	_place("%scar_sedan.gltf" % CITY, 1, ROAD_ROW, 90.0)
	_place("%scar_taxi.gltf" % CITY, 3, ROAD_ROW, -90.0)
	_place("%sbush.gltf" % CITY, 2, 1)
	_place("%sbush.gltf" % CITY, 1, 3)
	_place("%sbush.gltf" % CITY, 3, 3)
	_place("%sstreetlight.gltf" % CITY, 0, 1, 180.0)
	_place("%sstreetlight.gltf" % CITY, 4, 3)


## Instance a tile at grid (col, row), optionally rotated about Y (degrees).
func _place(path: String, col: int, row: int, rot_deg: float = 0.0) -> Node3D:
	var packed: Resource = load(path)
	if packed == null:
		push_warning("Missing asset: %s" % path)
		return null
	var inst: Node3D = packed.instantiate()
	inst.position = Vector3(col * TILE, 0.0, row * TILE)
	inst.rotation.y = deg_to_rad(rot_deg)
	world.add_child(inst)
	return inst


## Re-skin every mesh surface under `node` with a colorized atlas texture.
## Keeps the model's UVs (so windows/roofs/shopfronts stay), swaps the palette.
func _skin(node: Node, texture_path: String) -> void:
	var tex: Texture2D = load(texture_path)
	if tex == null:
		push_warning("Missing skin: %s" % texture_path)
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.95
	mat.metallic = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	for mi in _mesh_instances(node):
		mi.material_override = mat


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_mesh_instances(child))
	return out


## Float a billboarded name label just above a placed building's roof.
func _add_label(building: Node3D, text: String, height: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.006
	label.font_size = 44
	label.outline_size = 10
	label.modulate = Color("2c2c2a")
	label.outline_modulate = Color(1, 1, 1, 0.95)
	label.position = Vector3(0.0, height + 0.6, 0.0)
	building.add_child(label)


func _setup_camera() -> void:
	var target := Vector3((COLS - 1) * TILE * 0.5, 3.0, (ROWS - 1) * TILE * 0.5)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 13.0
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
