extends Node3D
## Townling town diorama (design doc §5, §18 visual-direction update).
##
## Low-poly 3D on a fixed orthographic (isometric) camera. The six Band-B
## landmark buildings (spec §5 / design doc §5) sit on a 2x2-unit grid of
## KayKit City Builder tiles, each captioned with a floating label. Tapping a
## building selects it (a gentle pop) and slides up a name panel — the first
## step of the one-tap-deep hub navigation.
##
## The backend health check from the bootstrap is retained as a UI overlay.

const CITY := "res://assets/city/Assets/gltf/"
const TILE := 2.0  # world units per grid cell

## The six launch landmarks. Each: display name, building mesh, grid cell.
const LANDMARKS := [
	{"name": "Bank", "mesh": "building_G", "cell": Vector2i(0, 0)},
	{"name": "School", "mesh": "building_E", "cell": Vector2i(2, 0)},
	{"name": "Workplace", "mesh": "building_H", "cell": Vector2i(4, 0)},
	{"name": "Home", "mesh": "building_B", "cell": Vector2i(0, 4)},
	{"name": "Shop", "mesh": "building_A", "cell": Vector2i(2, 4)},
	{"name": "Notice Board", "mesh": "building_D", "cell": Vector2i(4, 4)},
]
## Mesh heights (world units) for label placement + pick boxes, from glTF bounds.
const HEIGHTS := {
	"building_A": 1.65, "building_B": 1.65, "building_D": 2.97,
	"building_E": 2.35, "building_G": 2.98, "building_H": 3.05,
}
const COLS := 5
const ROWS := 5
const ROAD_ROW := 2
const HOVER_LIFT := 0.45  # how far a selected building pops up

const DEFAULT_API_BASE := "http://localhost:8000"
var _api_base := DEFAULT_API_BASE

## Per-landmark runtime state: {name, node, box (world AABB), label}.
var _picks: Array = []
var _selected := -1

@onready var camera: Camera3D = $Camera
@onready var sun: DirectionalLight3D = $Sun
@onready var world: Node3D = $World
@onready var backend_status: Label = $UI/Banner/BackendStatus

var _panel: PanelContainer
var _panel_name: Label
var _config_request: HTTPRequest
var _health_request: HTTPRequest


func _ready() -> void:
	_setup_light()
	_build_town()
	_setup_camera()
	_setup_ui()

	if "--shot" in OS.get_cmdline_args():
		_capture_and_quit()
		return

	_config_request = HTTPRequest.new()
	_health_request = HTTPRequest.new()
	add_child(_config_request)
	add_child(_health_request)
	_config_request.request_completed.connect(_on_config_completed)
	_health_request.request_completed.connect(_on_health_completed)
	_load_config()


func _capture_and_quit() -> void:
	# Exercise the selected state so the preview shows the pop + name panel.
	if _picks.size() > 0:
		_selected = 0
		_picks[0]["node"].position.y = HOVER_LIFT
		_picks[0]["label"].modulate = Color("e24b4a")
		_panel_name.text = _picks[0]["name"]
		_panel.visible = true
	for _i in range(6):
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://shot.png")
	get_tree().quit()


# --- Scene construction ----------------------------------------------------

func _setup_light() -> void:
	sun.rotation = Vector3(deg_to_rad(-50.0), deg_to_rad(-55.0), 0.0)
	sun.light_energy = 0.6
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.shadow_enabled = true
	sun.shadow_blur = 2.0


func _build_town() -> void:
	var landmark_cells := {}
	for lm in LANDMARKS:
		landmark_cells[lm["cell"]] = lm

	for row in ROWS:
		for col in COLS:
			var cell := Vector2i(col, row)
			if landmark_cells.has(cell):
				continue
			if row == ROAD_ROW:
				_place("%sroad_straight.gltf" % CITY, col, row, 90.0)
			else:
				_place("%sbase.gltf" % CITY, col, row)

	for lm in LANDMARKS:
		var cell: Vector2i = lm["cell"]
		var inst := _place("%s%s.gltf" % [CITY, lm["mesh"]], cell.x, cell.y)
		if inst == null:
			continue
		var height: float = HEIGHTS.get(lm["mesh"], 3.0)
		var label := _add_label(inst, lm["name"], height)
		# World-space pick box: 2x2 footprint centred on the cell, mesh-tall.
		var box := AABB(
			Vector3(cell.x * TILE - 1.0, 0.0, cell.y * TILE - 1.0),
			Vector3(2.0, height, 2.0)
		)
		_picks.append({"name": lm["name"], "node": inst, "box": box, "label": label})

	_place("%scar_sedan.gltf" % CITY, 1, ROAD_ROW, 90.0)
	_place("%scar_taxi.gltf" % CITY, 3, ROAD_ROW, -90.0)
	_place("%sbush.gltf" % CITY, 2, 1)
	_place("%sbush.gltf" % CITY, 1, 3)
	_place("%sbush.gltf" % CITY, 3, 3)
	_place("%sstreetlight.gltf" % CITY, 0, 1, 180.0)
	_place("%sstreetlight.gltf" % CITY, 4, 3)


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


func _add_label(building: Node3D, text: String, height: float) -> Label3D:
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
	return label


func _setup_camera() -> void:
	var target := Vector3((COLS - 1) * TILE * 0.5, 3.0, (ROWS - 1) * TILE * 0.5)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 13.0
	camera.position = target + Vector3(14.0, 15.0, 14.0)
	camera.look_at(target, Vector3.UP)


# --- Interaction -----------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	var pos := Vector2.INF
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
	if pos == Vector2.INF:
		return
	_pick_at(pos)


func _pick_at(screen_pos: Vector2) -> void:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var best := -1
	var best_dist := INF
	for i in _picks.size():
		var t := _ray_aabb(origin, dir, _picks[i]["box"])
		if t >= 0.0 and t < best_dist:
			best_dist = t
			best = i
	if best == -1:
		_deselect()
	else:
		_select(best)


## Ray/AABB entry distance via the slab method; -1 if no hit.
func _ray_aabb(ro: Vector3, rd: Vector3, box: AABB) -> float:
	var tmin := -INF
	var tmax := INF
	for i in 3:
		if absf(rd[i]) < 1e-8:
			if ro[i] < box.position[i] or ro[i] > box.position[i] + box.size[i]:
				return -1.0
		else:
			var inv := 1.0 / rd[i]
			var t1 := (box.position[i] - ro[i]) * inv
			var t2 := (box.position[i] + box.size[i] - ro[i]) * inv
			if t1 > t2:
				var tmp := t1
				t1 = t2
				t2 = tmp
			tmin = maxf(tmin, t1)
			tmax = minf(tmax, t2)
			if tmin > tmax:
				return -1.0
	if tmax < 0.0:
		return -1.0
	return tmin if tmin >= 0.0 else tmax


func _select(index: int) -> void:
	if index == _selected:
		return
	_deselect()
	_selected = index
	var pick = _picks[index]
	_hop(pick["node"], HOVER_LIFT)
	pick["label"].modulate = Color("e24b4a")
	_panel_name.text = pick["name"]
	_panel.visible = true


func _deselect() -> void:
	if _selected == -1:
		return
	var pick = _picks[_selected]
	_hop(pick["node"], 0.0)
	pick["label"].modulate = Color("2c2c2a")
	_selected = -1
	_panel.visible = false


## Tween a building's height with a little bounce.
func _hop(node: Node3D, to_y: float) -> void:
	var tween := create_tween()
	tween.tween_property(node, "position:y", to_y, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_open_pressed() -> void:
	if _selected == -1:
		return
	# Placeholder for the building screen (one tap deep, design doc §5/§13).
	_panel_name.text = "%s — coming soon" % _picks[_selected]["name"]


# --- UI --------------------------------------------------------------------

func _setup_ui() -> void:
	var ui: CanvasLayer = $UI

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 24.0
	_panel.offset_right = -24.0
	_panel.offset_top = -132.0
	_panel.offset_bottom = -28.0
	_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color("f7f6f2")
	style.set_corner_radius_all(18)
	style.set_content_margin_all(18)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", style)
	ui.add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_panel.add_child(row)

	_panel_name = Label.new()
	_panel_name.text = ""
	_panel_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_panel_name.add_theme_color_override("font_color", Color("2c2c2a"))
	_panel_name.add_theme_font_size_override("font_size", 40)
	row.add_child(_panel_name)

	var open := Button.new()
	open.text = "Open"
	open.custom_minimum_size = Vector2(120, 64)
	open.add_theme_font_size_override("font_size", 28)
	open.pressed.connect(_on_open_pressed)
	row.add_child(open)


# --- Backend health overlay (retained from bootstrap) ----------------------

func _load_config() -> void:
	var origin := _web_origin()
	if origin.is_empty():
		_check_backend()
		return
	backend_status.text = "backend: loading config…"
	var err := _config_request.request("%s/config.json" % origin)
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
	var err := _health_request.request("%s/api/health/" % _api_base)
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
