extends Node3D
## Townling town diorama (design doc §5, §18 visual-direction update).
##
## Low-poly 3D on a fixed orthographic (isometric) camera. The six Band-B
## landmark buildings (spec §5 / design doc §5) sit on a 2x2-unit grid of
## KayKit City Builder tiles, each captioned with a floating label. Tapping a
## building slides its screen up over the city; closing returns to the city —
## everything one tap deep.
##
## The backend health check from the bootstrap is retained as a UI overlay.

const CITY := "res://assets/city/Assets/gltf/"
const TILE := 2.0  # world units per grid cell

## The six launch landmarks. Each: display name, building mesh, grid cell, and a
## one-line purpose blurb shown on the (placeholder) building screen.
const LANDMARKS := [
	{"name": "Bank", "mesh": "building_G", "cell": Vector2i(0, 0),
		"blurb": "Save your coins in the jar and watch them grow."},
	{"name": "School", "mesh": "building_E", "cell": Vector2i(2, 0),
		"blurb": "Take a class to earn a skill star."},
	{"name": "Workplace", "mesh": "building_H", "cell": Vector2i(4, 0),
		"blurb": "Work a shift and earn your weekly salary."},
	{"name": "Home", "mesh": "building_B", "cell": Vector2i(0, 4),
		"blurb": "Rest to refill energy, decorate, plan your day."},
	{"name": "Shop", "mesh": "building_A", "cell": Vector2i(2, 4),
		"blurb": "Buy groceries and the things you need."},
	{"name": "Notice Board", "mesh": "building_D", "cell": Vector2i(4, 4),
		"blurb": "Find gigs and quick jobs for extra coins."},
]
## Mesh heights (world units) for label placement + pick boxes, from glTF bounds.
const HEIGHTS := {
	"building_A": 1.65, "building_B": 1.65, "building_D": 2.97,
	"building_E": 2.35, "building_G": 2.98, "building_H": 3.05,
}
const COLS := 5
const ROWS := 5
const ROAD_ROW := 2

const DEFAULT_API_BASE := "http://localhost:8000"
var _api_base := DEFAULT_API_BASE

## Per-landmark pick data: {name, blurb, box (world AABB)}.
var _picks: Array = []

@onready var camera: Camera3D = $Camera
@onready var sun: DirectionalLight3D = $Sun
@onready var world: Node3D = $World
@onready var backend_status: Label = $UI/Banner/BackendStatus

# Building-screen widgets (built in code).
var _screen: Control
var _card: PanelContainer
var _screen_title: Label
var _screen_body: Label
var _screen_open := false

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
	# --zoom frames a single building for design review; default is the town.
	if "--zoom" in OS.get_cmdline_args():
		var focus := Vector3(0.0, 1.0, 1.4)  # the Bank lot
		camera.size = 7.0
		camera.position = focus + Vector3(9.0, 10.0, 9.0)
		camera.look_at(focus, Vector3.UP)
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
		_add_label(inst, lm["name"], height)
		var box := AABB(
			Vector3(cell.x * TILE - 1.0, 0.0, cell.y * TILE - 1.0),
			Vector3(2.0, height, 2.0)
		)
		_picks.append({"name": lm["name"], "blurb": lm["blurb"], "box": box})

		# Per-landmark detailing (one category at a time).
		var origin := Vector3(cell.x * TILE, 0.0, cell.y * TILE)
		if lm["name"] == "Bank":
			_decorate_bank(origin)

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


# --- Composition helpers (world-space) -------------------------------------

## Instance a kit asset at a world position, rotated about Y and scaled.
func _spawn_at(path: String, pos: Vector3, rot_deg: float = 0.0, scale: float = 1.0) -> Node3D:
	var packed: Resource = load(path)
	if packed == null:
		push_warning("Missing asset: %s" % path)
		return null
	var inst: Node3D = packed.instantiate()
	inst.position = pos
	inst.rotation.y = deg_to_rad(rot_deg)
	inst.scale = Vector3.ONE * scale
	world.add_child(inst)
	return inst


## A soft matte coloured box primitive (for signage / trunks).
func _box(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mi.material_override = mat
	mi.position = pos
	world.add_child(mi)
	return mi


## A low-poly tree: slim brown trunk + a scaled bush canopy, styled to the kit.
func _tree(pos: Vector3, size: float = 2.0) -> void:
	_box(Vector3(0.1, 0.45, 0.1), Color("6b4a2a"), pos + Vector3(0, 0.22, 0))
	_spawn_at("%sbush.gltf" % CITY, pos + Vector3(0, 0.35, 0), 0.0, size)


## A standing sign: post + coloured panel + billboard text.
func _sign(pos: Vector3, text: String, panel_color: Color, face_deg: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = deg_to_rad(face_deg)
	world.add_child(root)

	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.09, 1.35, 0.09)
	post.mesh = post_mesh
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color("8a8a8a")
	post.material_override = post_mat
	post.position = Vector3(0, 0.675, 0)
	root.add_child(post)

	var panel := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(1.35, 0.6, 0.08)
	panel.mesh = panel_mesh
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = panel_color
	panel_mat.roughness = 0.9
	panel.material_override = panel_mat
	panel.position = Vector3(0, 1.55, 0)
	root.add_child(panel)

	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.005
	label.font_size = 90
	label.outline_size = 10
	label.modulate = Color("ffffff")
	label.outline_modulate = Color(0.06, 0.1, 0.24, 1.0)
	label.position = Vector3(0, 1.55, 0.06)
	root.add_child(label)


## Detail the Bank lot: hedges, trees, a BANK sign, an ATM, street furniture.
## Front faces the road (+Z). Kept inside the lot so it reads at town scale.
func _decorate_bank(origin: Vector3) -> void:
	# Neat trimmed hedge along the frontage, with a gap for the entrance path.
	for x in [-0.8, -0.5, 0.5, 0.8]:
		_spawn_at("%sbush.gltf" % CITY, origin + Vector3(x, 0, 1.1), 0.0, 1.1)
	# Two trees framing the plot at the front corners, clear of the sign.
	_tree(origin + Vector3(-1.35, 0, 1.6))
	_tree(origin + Vector3(1.35, 0, 2.4))
	# Prominent BANK sign on the entrance path, facing the camera.
	_sign(origin + Vector3(0.0, 0, 1.9), "BANK", Color("3a4a7a"), 45.0)
	# An ATM: dark cabinet + a little blue screen, beside the entrance.
	_box(Vector3(0.34, 0.72, 0.28), Color("343a45"), origin + Vector3(0.75, 0.36, 1.3))
	_box(Vector3(0.22, 0.16, 0.06), Color("6aa6d6"), origin + Vector3(0.75, 0.5, 1.16))
	# Street furniture, tucked to the sides.
	_spawn_at("%sbench.gltf" % CITY, origin + Vector3(-1.3, 0, 2.5), 90.0)
	_spawn_at("%sstreetlight.gltf" % CITY, origin + Vector3(1.5, 0, 1.0), 180.0)
	_spawn_at("%sfirehydrant.gltf" % CITY, origin + Vector3(-1.45, 0, 1.1))
	# A customer's car parked at the curb.
	_spawn_at("%scar_sedan.gltf" % CITY, origin + Vector3(0.1, 0, 3.05), 90.0)


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


# --- Building screen (slide up over the city) ------------------------------

func _open_screen(index: int) -> void:
	var pick = _picks[index]
	_screen_title.text = pick["name"]
	_screen_body.text = "%s\n\n(building screen — coming soon)" % pick["blurb"]
	_screen_open = true
	_screen.visible = true
	_size_card()
	var vp := get_viewport().get_visible_rect().size
	_card.position = Vector2(16.0, vp.y)  # start just below the screen
	var tween := create_tween()
	tween.tween_property(_card, "position:y", 64.0, 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _close_screen() -> void:
	if not _screen_open:
		return
	_screen_open = false
	var vp := get_viewport().get_visible_rect().size
	var tween := create_tween()
	tween.tween_property(_card, "position:y", vp.y, 0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: _screen.visible = false)


# --- UI --------------------------------------------------------------------

func _setup_ui() -> void:
	var ui: CanvasLayer = $UI

	# Full-screen blocker; a tap on the dim area outside the card closes it.
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

	# The card (manual size/position so it can slide independently).
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
