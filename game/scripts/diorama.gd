extends Node3D
## Townling town diorama (design doc §5, §18 visual-direction update).
##
## Low-poly 3D on a fixed orthographic (isometric) camera, built from Kenney's
## City Builder kit (1x1-unit tiles). The six Band-B landmark buildings (spec
## §5) sit on a grass grid with a street, sidewalks, trees and a fountain, each
## captioned with a floating label. Tapping a building slides its screen up over
## the city; closing returns to it — one tap deep.
##
## The backend health check from the bootstrap is retained as a UI overlay.

const KEN := "res://assets/kenney/"
const TILE := 1.0  # world units per grid cell

## The six launch landmarks: name, Kenney model, grid cell, purpose blurb.
const LANDMARKS := [
	{"name": "Bank", "model": "building-small-c", "cell": Vector2i(1, 1),
		"blurb": "Save your coins in the jar and watch them grow."},
	{"name": "School", "model": "building-small-b", "cell": Vector2i(3, 1),
		"blurb": "Take a class to earn a skill star."},
	{"name": "Workplace", "model": "building-small-d", "cell": Vector2i(5, 1),
		"blurb": "Work a shift and earn your weekly salary."},
	{"name": "Home", "model": "building-small-a", "cell": Vector2i(1, 5),
		"blurb": "Rest to refill energy, decorate, plan your day."},
	{"name": "Shop", "model": "building-garage", "cell": Vector2i(3, 5),
		"blurb": "Buy groceries and the things you need."},
	{"name": "Notice Board", "model": "building-garage", "cell": Vector2i(5, 5),
		"blurb": "Find gigs and quick jobs for extra coins."},
]
## Model heights (world units) for label placement + pick boxes, from glTF bounds.
const HEIGHTS := {
	"building-small-a": 0.95, "building-small-b": 1.63, "building-small-c": 1.75,
	"building-small-d": 1.0, "building-garage": 0.55,
}
const COLS := 7
const ROWS := 7
const ROAD_ROW := 3
const SIDEWALK_ROWS := [2, 4]
const FOUNTAIN_CELL := Vector2i(3, 6)

const FONT := "res://assets/kenney/fonts/lilita_one_regular.ttf"
const SND_OPEN := "assets/kenney/sounds/placement-a.ogg"
const SND_CLOSE := "assets/kenney/sounds/removal-a.ogg"

const DEFAULT_API_BASE := "http://localhost:8000"
var _api_base := DEFAULT_API_BASE
var _font: Font

## Per-landmark pick data: {name, blurb, box (world AABB)}.
var _picks: Array = []

@onready var camera: Camera3D = $Camera
@onready var sun: DirectionalLight3D = $Sun
@onready var world: Node3D = $World
@onready var backend_status: Label = $UI/Banner/BackendStatus

var _screen: Control
var _card: PanelContainer
var _screen_title: Label
var _screen_body: Label
var _screen_open := false

var _config_request: HTTPRequest
var _health_request: HTTPRequest


func _ready() -> void:
	_font = load(FONT)
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
	if "--zoom" in OS.get_cmdline_args():
		var focus := Vector3(1.0, 0.6, 1.0)  # the Bank
		camera.size = 5.0
		camera.position = focus + Vector3(9.0, 10.0, 9.0)
		camera.look_at(focus, Vector3.UP)
	for _i in range(6):
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://shot.png")
	get_tree().quit()


# --- Scene construction ----------------------------------------------------

func _setup_light() -> void:
	# Cosy warm afternoon, matching the reference: golden key light, soft
	# shadows, a warm ambient fill so pastels stay soft, muted blue-grey sky.
	sun.rotation = Vector3(deg_to_rad(-50.0), deg_to_rad(-55.0), 0.0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.89, 0.72)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.2

	var env := ($WorldEnvironment as WorldEnvironment).environment
	env.background_color = Color("b3c4cc")            # soft muted blue-grey
	env.ambient_light_color = Color(1.0, 0.93, 0.82)  # warm fill
	env.ambient_light_energy = 0.28                   # lower fill -> deeper, soothing shadows


func _build_town() -> void:
	var building_cells := {}
	for lm in LANDMARKS:
		building_cells[lm["cell"]] = lm

	# Ground layer: road / sidewalk / grass.
	for row in ROWS:
		for col in COLS:
			var cell := Vector2i(col, row)
			if row == ROAD_ROW:
				_spawn("road-straight", cell, 90.0)
			elif row in SIDEWALK_ROWS:
				_spawn("pavement", cell)
			else:
				_spawn("grass", cell)

	# Landmarks + labels + pick boxes.
	for lm in LANDMARKS:
		var cell: Vector2i = lm["cell"]
		var inst := _spawn(lm["model"], cell)
		if inst == null:
			continue
		var height: float = HEIGHTS.get(lm["model"], 1.5)
		_add_label(inst, lm["name"], height)
		var box := AABB(
			Vector3(cell.x * TILE - 0.5, 0.0, cell.y * TILE - 0.5),
			Vector3(TILE, height, TILE)
		)
		_picks.append({"name": lm["name"], "blurb": lm["blurb"], "box": box})

	# Greenery: trees on the open grass cells (rows 0/6 and gaps in 1/5).
	var tree_cells := [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0),
		Vector2i(0, 1), Vector2i(2, 1), Vector2i(4, 1), Vector2i(6, 1),
		Vector2i(0, 5), Vector2i(2, 5), Vector2i(4, 5), Vector2i(6, 5),
		Vector2i(0, 6), Vector2i(1, 6), Vector2i(2, 6), Vector2i(4, 6),
		Vector2i(5, 6), Vector2i(6, 6),
	]
	var tall := true
	for cell in tree_cells:
		_spawn("grass-trees-tall" if tall else "grass-trees", cell)
		tall = not tall

	# A fountain centrepiece in the front park.
	_spawn("pavement-fountain", FOUNTAIN_CELL)


## Instance a Kenney model at grid (col, row), rotated about Y.
func _spawn(model: String, cell: Vector2i, rot_deg: float = 0.0) -> Node3D:
	var packed: Resource = load("%s%s.glb" % [KEN, model])
	if packed == null:
		push_warning("Missing model: %s" % model)
		return null
	var inst: Node3D = packed.instantiate()
	inst.position = Vector3(cell.x * TILE, 0.0, cell.y * TILE)
	inst.rotation.y = deg_to_rad(rot_deg)
	world.add_child(inst)
	return inst


func _add_label(building: Node3D, text: String, height: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = _font
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.0035
	label.font_size = 40
	label.outline_size = 10
	label.modulate = Color("2c2c2a")
	label.outline_modulate = Color(1, 1, 1, 0.95)
	label.position = Vector3(0.0, height + 0.35, 0.0)
	building.add_child(label)


func _setup_camera() -> void:
	var target := Vector3((COLS - 1) * TILE * 0.5, 1.2, (ROWS - 1) * TILE * 0.5)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 9.0
	camera.position = target + Vector3(12.0, 13.0, 12.0)
	camera.look_at(target, Vector3.UP)


# --- Interaction: tap a building -> open its screen -------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _screen_open:
		return
	var pos := Vector2.INF
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
	if pos == Vector2.INF:
		return

	var origin := camera.project_ray_origin(pos)
	var dir := camera.project_ray_normal(pos)
	var best := -1
	var best_dist := INF
	for i in _picks.size():
		var t := _ray_aabb(origin, dir, _picks[i]["box"])
		if t >= 0.0 and t < best_dist:
			best_dist = t
			best = i
	if best != -1:
		_open_screen(best)


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


# --- Building screen (slide up over the city) ------------------------------

func _open_screen(index: int) -> void:
	var pick = _picks[index]
	_screen_title.text = pick["name"]
	_screen_body.text = "%s\n\n(building screen — coming soon)" % pick["blurb"]
	_screen_open = true
	_screen.visible = true
	Sfx.play(SND_OPEN, -8.0)
	_size_card()
	var vp := get_viewport().get_visible_rect().size
	_card.position = Vector2(16.0, vp.y)
	var tween := create_tween()
	tween.tween_property(_card, "position:y", 64.0, 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _close_screen() -> void:
	if not _screen_open:
		return
	_screen_open = false
	Sfx.play(SND_CLOSE, -8.0)
	var vp := get_viewport().get_visible_rect().size
	var tween := create_tween()
	tween.tween_property(_card, "position:y", vp.y, 0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: _screen.visible = false)


# --- UI --------------------------------------------------------------------

func _setup_ui() -> void:
	var ui: CanvasLayer = $UI

	_screen = Control.new()
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen.visible = false
	_screen.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_screen()
	)
	ui.add_child(_screen)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.17, 0.17, 0.16, 0.25)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(dim)

	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f7f6f2")
	style.set_corner_radius_all(24)
	style.set_content_margin_all(28)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 12
	_card.add_theme_stylebox_override("panel", style)
	_screen.add_child(_card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	_card.add_child(col)

	var header := HBoxContainer.new()
	col.add_child(header)

	_screen_title = Label.new()
	_screen_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_screen_title.add_theme_color_override("font_color", Color("2c2c2a"))
	_screen_title.add_theme_font_size_override("font_size", 52)
	header.add_child(_screen_title)

	var close := Button.new()
	close.text = "✕"
	close.custom_minimum_size = Vector2(72, 72)
	close.add_theme_font_size_override("font_size", 36)
	close.pressed.connect(_close_screen)
	header.add_child(close)

	_screen_body = Label.new()
	_screen_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_screen_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_screen_body.add_theme_color_override("font_color", Color("7a5410"))
	_screen_body.add_theme_font_size_override("font_size", 30)
	col.add_child(_screen_body)

	_size_card()


func _size_card() -> void:
	var vp := get_viewport().get_visible_rect().size
	_card.custom_minimum_size = Vector2(vp.x - 32.0, vp.y - 96.0)
	_card.size = Vector2(vp.x - 32.0, vp.y - 96.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED and _card != null:
		_size_card()
		if _screen_open:
			_card.position = Vector2(16.0, 64.0)


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
