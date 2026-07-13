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

## The six launch landmarks: name, Kenney model (subpath under assets/kenney/),
## uniform scale, grid cell, purpose blurb. Home is a pitched-roof suburban
## house and Shop a commercial storefront with a built-in awning (sister kits).
const LANDMARKS := [
	{"name": "Bank", "model": "commercial/building-i", "scale": 0.78, "cell": Vector2i(1, 1),
		"blurb": "Save your coins in the jar and watch them grow."},
	{"name": "School", "model": "commercial/building-e", "scale": 0.88, "cell": Vector2i(3, 1),
		"blurb": "Take a class to earn a skill star."},
	{"name": "Workplace", "model": "commercial/building-h", "scale": 1.0, "cell": Vector2i(5, 1),
		"blurb": "Work a shift and earn your weekly salary."},
	{"name": "Home", "model": "suburban/building-type-h", "scale": 0.75, "cell": Vector2i(1, 5),
		"blurb": "Rest to refill energy, decorate, plan your day."},
	{"name": "Shop", "model": "commercial/building-k", "scale": 0.62, "cell": Vector2i(3, 5),
		"blurb": "Buy groceries and the things you need."},
	{"name": "Notice Board", "model": "building-garage", "scale": 1.0, "cell": Vector2i(5, 5),
		"blurb": "Find gigs and quick jobs for extra coins."},
]
## Model heights (world units, pre-scale) for labels + pick boxes, from glTF bounds.
const HEIGHTS := {
	"building-small-a": 0.95, "building-small-b": 1.63, "building-small-c": 1.75,
	"building-small-d": 1.0, "building-garage": 0.55,
	"suburban/building-type-h": 0.74,
	"commercial/building-c": 0.89, "commercial/building-e": 0.89,
	"commercial/building-h": 1.29, "commercial/building-i": 1.68,
	"commercial/building-k": 1.47,
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
var _close_btn: Button
var _actions: VBoxContainer
var _screen_open := false
var _current_screen := ""  # open landmark name; "Evening" for the day summary

var _hud_day: Label
var _hud_wallet: Label
var _hud_bolts: Array[TextureRect] = []
var _hud_heart: ProgressBar
var _hud_dream_label: Label
var _hud_dream_bar: ProgressBar
var _hud_chapter: Label
var _lights_built := false

var _dream_spot: Node3D
var _dream_group: Node3D
var _dream_spot_key := ""  # rebuild monuments when the dream chain changes
var _hud_heart_icon: TextureRect
var _home_badge: Label3D
var _blink_time := 0.0

# Living city: drifting clouds, driving cars, and a day arc tied to slots.
# Snow-globe camera: orbit + zoom around the fixed diorama (never pans —
# design doc §5: navigation is not the game).
var _cam_yaw := 0.7853981634          # 45° — the home view
var _cam_dist := 30.0
var _cam_yaw_target := 0.7853981634
var _cam_dist_target := 30.0
var _press_pos := Vector2.INF
var _orbit_drag := false

var _clouds: Array = []      # [{node, speed}]
var _cars: Array = []        # [{node, speed, dir}]
var _sun_disc: MeshInstance3D
var _moon_disc: MeshInstance3D
var _sun_disc_mat: StandardMaterial3D
var _moon_disc_mat: StandardMaterial3D
var _env: Environment

## Day-arc targets per phase (0=morning … 3=dusk): sun energy, colour,
## elevation, ambient energy, background colour.
const DAY_PHASES := [
	{"e": 0.85, "col": Color("fff1dc"), "rot": -45.0, "amb": 0.36, "bg": Color("b2b69b")},
	{"e": 0.9, "col": Color("fff6e8"), "rot": -50.0, "amb": 0.33, "bg": Color("b2b69b")},
	{"e": 0.75, "col": Color("ffdfb0"), "rot": -35.0, "amb": 0.30, "bg": Color("aca789")},
	{"e": 0.38, "col": Color("ffc890"), "rot": -22.0, "amb": 0.20, "bg": Color("8f8ba0")},
]

var _config_request: HTTPRequest
var _health_request: HTTPRequest


func _ready() -> void:
	_font = load(FONT)
	_setup_light()
	_build_town()
	_setup_camera()
	_setup_ui()
	GameState.changed.connect(_refresh_hud)
	_refresh_hud()
	_maybe_debug_overlay()

	if "--shot" in OS.get_cmdline_args():
		_capture_and_quit()
		return

	# Day 1, minute 2 (spec §2): the dream is chosen before anything else —
	# it is the answer to "why do we need money?".
	if GameState.dream_id == "":
		_open_dream_picker.call_deferred()
	elif GameState.forced_rest_today:
		_open_rest_day.call_deferred()
	elif GameState.ch1_announce_pending:
		GameState.ch1_announce_pending = false
		GameState.save_game()
		_open_chapter_announce.call_deferred()

	_config_request = HTTPRequest.new()
	_health_request = HTTPRequest.new()
	add_child(_config_request)
	add_child(_health_request)
	_config_request.request_completed.connect(_on_config_completed)
	_health_request.request_completed.connect(_on_health_completed)
	_load_config()


func _capture_and_quit() -> void:
	if "--zoom" in OS.get_cmdline_args():
		var focus := Vector3(1.0, 0.7, 1.2)  # the Bank lot
		var dir := Vector3(1.0, 1.05, 1.0).normalized()
		camera.position = focus + dir * 11.0
		camera.look_at(focus, Vector3.UP)
	elif "--zoom2" in OS.get_cmdline_args():
		var focus2 := Vector3(3.0, 0.4, 5.0)  # south row: Home/Shop/Notice Board
		var dir2 := Vector3(1.0, 1.05, 1.0).normalized()
		camera.position = focus2 + dir2 * 12.0
		camera.look_at(focus2, Vector3.UP)
	elif "--ui" in OS.get_cmdline_args():
		# Exercise gameplay for the preview: open Workplace and work a shift
		# so the coin flight is captured mid-air.
		GameState.autosave = false
		GameState.init_new()
		for i in _picks.size():
			if _picks[i]["name"] == "Workplace":
				_open_screen(i)
				break
		_do_shift()
	elif "--dream" in OS.get_cmdline_args():
		GameState.autosave = false
		GameState.init_new()
		GameState.select_dream("puppy")
		GameState.wallet = 999
		while not GameState.dream_complete():
			GameState.fund_dream()
		GameState.start_new_dream("treehouse")
		GameState.wallet = 400
		for i in 12:
			GameState.fund_dream()
	elif "--ui6" in OS.get_cmdline_args():
		GameState.autosave = false
		GameState.init_new()
		GameState.select_dream("ocean")
		GameState.gigs_today = ["dog_walk", "bake_sale", "quiz"]
		for i in _picks.size():
			if _picks[i]["name"] == "Notice Board":
				_open_screen(i)
				break
	elif "--ui7" in OS.get_cmdline_args():
		GameState.autosave = false
		GameState.init_new()
		GameState.select_dream("ocean")
		GameState.ch1_active = true
		GameState.ch1_deadline = 21
		_refresh_hud()
		_open_chapter_announce()
	elif "--ui5" in OS.get_cmdline_args():
		GameState.autosave = false
		GameState.init_new()
		GameState.select_dream("treehouse")
		GameState.day = 3
		GameState.wallet = 95
		GameState.schedule_event("fridge_breaks", 3)
		GameState.prepare_tonight()
		_open_event()
	elif "--yaw" in OS.get_cmdline_args():
		GameState.autosave = false
		GameState.init_new()
		GameState.select_dream("treehouse")
		_cam_yaw = deg_to_rad(160.0)
		_cam_yaw_target = _cam_yaw
		_apply_camera()
	elif "--dusk" in OS.get_cmdline_args():
		GameState.autosave = false
		GameState.init_new()
		GameState.select_dream("treehouse")
		GameState.slots_left = 0
		# let the lerp settle for the capture
		for i in 90:
			_update_city_life(0.1)
	elif "--ui4" in OS.get_cmdline_args():
		GameState.autosave = false
		GameState.init_new()
		GameState.select_dream("puppy")
		GameState.wellbeing = 12
		_refresh_hud()
	elif "--ui2" in OS.get_cmdline_args():
		GameState.autosave = false
		GameState.init_new()
		_open_dream_picker()
	elif "--ui3" in OS.get_cmdline_args():
		GameState.autosave = false
		GameState.init_new()
		GameState.select_dream("treehouse")
		GameState.wallet = 210
		GameState.fund_dream()
		GameState.fund_dream()
		GameState.fund_dream()
		for i in _picks.size():
			if _picks[i]["name"] == "Home":
				_open_screen(i)
				break
	for _i in range(6):
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://shot.png")
	get_tree().quit()


# --- Scene construction ----------------------------------------------------

func _setup_light() -> void:
	# Warm sun-drenched afternoon (target reference + researched practice:
	# key light subtly warm — never a saturated hex — ambient slightly cooler
	# for contrast, softened shadows). The LOW sun elevation is what gives the
	# long, soft shadows that ground the diorama; the warm-sage backdrop and
	# the colormap's warm families carry the mood.
	sun.rotation = Vector3(deg_to_rad(-38.0), deg_to_rad(-55.0), 0.0)
	sun.light_energy = 0.8
	sun.light_color = Color("fff1dc")     # gently golden, ~5000K
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.9
	sun.shadow_blur = 1.5

	# Single-sun setup; the counter-fill stays off.
	($Sun2 as DirectionalLight3D).visible = false

	var env := ($WorldEnvironment as WorldEnvironment).environment
	_env = env
	env.background_color = Color("b2b69b")           # warm sage backdrop, a step deeper
	env.ambient_light_color = Color("c6c8bc")        # sage-grey fill, cooler than sun
	env.ambient_light_energy = 0.33
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC


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
		var lm_scale: float = lm.get("scale", 1.0)
		var inst := _spawn(lm["model"], cell, lm.get("rot", 0.0), lm_scale)
		if inst == null:
			continue
		var height: float = HEIGHTS.get(lm["model"], 1.5) * lm_scale
		_add_label_at(Vector3(cell.x * TILE, height + 0.35, cell.y * TILE), lm["name"])
		var box := AABB(
			Vector3(cell.x * TILE - 0.5, 0.0, cell.y * TILE - 0.5),
			Vector3(TILE, height, TILE)
		)
		_picks.append({"name": lm["name"], "blurb": lm["blurb"], "box": box, "node": inst})

		# Per-landmark detailing.
		var lot := Vector3(cell.x * TILE, 0.0, cell.y * TILE)
		match lm["name"]:
			"Bank":
				_decorate_bank(lot)
			"School":
				_decorate_school(lot)
			"Workplace":
				_decorate_workplace(lot)
			"Home":
				_decorate_home(lot)
			"Shop":
				_decorate_shop(lot)
			"Notice Board":
				_decorate_notice_board(lot)

	# Greenery: trees on the open grass cells (rows 0/6 and gaps in 1/5).
	var tree_cells := [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0),
		Vector2i(0, 1), Vector2i(2, 1), Vector2i(4, 1), Vector2i(6, 1),
		Vector2i(0, 5), Vector2i(2, 5), Vector2i(4, 5), Vector2i(6, 5),
		Vector2i(0, 6), Vector2i(2, 6), Vector2i(4, 6),
		Vector2i(5, 6),
	]
	# Corners occupied by dream monuments (past and present) get no trees.
	var dream_slots: int = mini(GameState.completed_dreams.size() + 1, DREAM_CELLS.size())
	var reserved: Array = DREAM_CELLS.slice(0, dream_slots)
	var tall := true
	for cell in tree_cells:
		if reserved.has(cell):
			continue
		_spawn("grass-trees-tall" if tall else "grass-trees", cell)
		tall = not tall

	# A fountain centrepiece in the front park, and a little sidewalk colour.
	_spawn("pavement-fountain", FOUNTAIN_CELL)
	_scatter_confetti()
	_update_dream_spot()

	# Street life: cars drive the two lanes and loop around (design: the town
	# feels alive; movement is ambient, never interactive).
	_add_car("cars/taxi", 0.9, 2.80, 1.0, 0.55)
	_add_car("cars/sedan", 4.6, 3.22, -1.0, 0.75)
	_add_car("cars/delivery", 2.2, 3.22, -1.0, 0.42)
	_add_clouds()
	_add_sky_bodies()


## Instance a Kenney model at grid (col, row), rotated about Y, optionally scaled.
func _spawn(model: String, cell: Vector2i, rot_deg: float = 0.0, scale: float = 1.0) -> Node3D:
	return _spawn_free(model, Vector3(cell.x * TILE, 0.0, cell.y * TILE), rot_deg, scale)


## Instance a Kenney model at a free world position.
func _spawn_free(model: String, pos: Vector3, rot_deg: float = 0.0, scale: float = 1.0) -> Node3D:
	var packed: Resource = load("%s%s.glb" % [KEN, model])
	if packed == null:
		push_warning("Missing model: %s" % model)
		return null
	var inst: Node3D = packed.instantiate()
	inst.position = pos
	inst.rotation.y = deg_to_rad(rot_deg)
	inst.scale = Vector3.ONE * scale
	world.add_child(inst)
	return inst


# --- Composition helpers (Kenney tiles are 1x1; surfaces sit at y≈0.06) ----

const GROUND_Y := 0.06

## A soft matte coloured box primitive, positioned by its base centre.
func _box(
	size: Vector3, color: Color, base_pos: Vector3,
	rot_deg: float = 0.0, rot_x_deg: float = 0.0
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mi.material_override = mat
	mi.position = base_pos + Vector3(0.0, size.y * 0.5, 0.0)
	mi.rotation.y = deg_to_rad(rot_deg)
	mi.rotation.x = deg_to_rad(rot_x_deg)
	world.add_child(mi)
	return mi


## A standing sign: grey post, coloured panel, Lilita text on the panel face.
func _sign(
	base_pos: Vector3, text: String, panel_color: Color, face_deg: float,
	panel_w: float = 0.55, font_px: int = 56
) -> void:
	var root := Node3D.new()
	root.position = base_pos
	root.rotation.y = deg_to_rad(face_deg)
	world.add_child(root)

	var post := BoxMesh.new()
	post.size = Vector3(0.05, 0.55, 0.05)
	var post_mi := MeshInstance3D.new()
	post_mi.mesh = post
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color("9a9a9a")
	post_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	post_mi.material_override = post_mat
	post_mi.position = Vector3(0.0, 0.275, 0.0)
	root.add_child(post_mi)

	var panel := BoxMesh.new()
	panel.size = Vector3(panel_w, 0.26, 0.05)
	var panel_mi := MeshInstance3D.new()
	panel_mi.mesh = panel
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = panel_color
	panel_mat.roughness = 0.9
	panel_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	panel_mi.material_override = panel_mat
	panel_mi.position = Vector3(0.0, 0.62, 0.0)
	root.add_child(panel_mi)

	var label := Label3D.new()
	label.text = text
	label.font = _font
	label.pixel_size = 0.003
	label.font_size = font_px
	label.modulate = Color(1, 1, 1)
	label.outline_size = 4
	label.outline_modulate = Color(0, 0, 0, 0.25)
	label.position = Vector3(0.0, 0.62, 0.03)
	root.add_child(label)


## A flat coin medallion (the kit's coin sprite) mounted on a wall face.
func _coin_medallion(pos: Vector3, face_deg: float, diameter: float = 0.2) -> void:
	var tex: Texture2D = load("res://assets/ui/coin.png")
	if tex == null:
		return
	var sprite := Sprite3D.new()
	sprite.texture = tex
	sprite.pixel_size = diameter / float(maxi(tex.get_width(), tex.get_height()))
	sprite.position = pos
	sprite.rotation.y = deg_to_rad(face_deg)
	sprite.shaded = true
	world.add_child(sprite)


## Detail the Bank lot (cell centre at `origin`; the door faces +Z, onto the
## sidewalk). Kept tight to the 1x1 lot so it reads at town scale.
func _decorate_bank(origin: Vector3) -> void:
	var ground := origin + Vector3(0.0, GROUND_Y, 0.0)
	# BANK sign at the front-left corner of the lot, angled to the camera.
	_sign(ground + Vector3(-0.42, 0.0, 0.62), "BANK", Color("3a4a7a"), 45.0)
	# Gold coin medallion mounted above the door (front wall is at z≈+0.5).
	_coin_medallion(origin + Vector3(0.0, 0.66, 0.515), 0.0, 0.27)
	# ATM: dark cabinet + small blue screen, right of the door.
	_box(Vector3(0.16, 0.34, 0.10), Color("3b4048"), ground + Vector3(0.36, 0.0, 0.47))
	_box(Vector3(0.10, 0.07, 0.02), Color("8fc1e8"), origin + Vector3(0.36, 0.26, 0.525))
	# Planters flanking the entrance: terracotta box + leafy top.
	for x in [-0.22, 0.22]:
		_box(Vector3(0.14, 0.09, 0.14), Color("b06041"), ground + Vector3(x, 0.0, 0.44))
		_box(Vector3(0.11, 0.10, 0.11), Color("61cb8b"), ground + Vector3(x, 0.09, 0.44))


## School lot: SCHOOL sign, flagpole with a little flag, and a play ball.
func _decorate_school(origin: Vector3) -> void:
	var ground := origin + Vector3(0.0, GROUND_Y, 0.0)
	_sign(ground + Vector3(-0.42, 0.0, 0.62), "SCHOOL", Color("b58a3a"), 45.0, 0.62, 44)
	# Flagpole at the right front corner.
	_box(Vector3(0.03, 0.85, 0.03), Color("d8d4c8"), ground + Vector3(0.42, 0.0, 0.40))
	_box(Vector3(0.16, 0.10, 0.015), Color("e24b4a"), ground + Vector3(0.51, 0.68, 0.40))
	# A red play ball on the lot.
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.055
	sphere.height = 0.11
	ball.mesh = sphere
	var ball_mat := StandardMaterial3D.new()
	ball_mat.albedo_color = Color("e24b4a")
	ball_mat.roughness = 0.8
	ball.material_override = ball_mat
	ball.position = ground + Vector3(-0.30, 0.055, 0.42)
	world.add_child(ball)


## Workplace lot: OFFICE sign + tidy planters by the door.
func _decorate_workplace(origin: Vector3) -> void:
	var ground := origin + Vector3(0.0, GROUND_Y, 0.0)
	_sign(ground + Vector3(-0.42, 0.0, 0.62), "OFFICE", Color("60748c"), 45.0, 0.62, 44)
	for x in [-0.24, 0.24]:
		_box(Vector3(0.13, 0.08, 0.13), Color("8a8478"), ground + Vector3(x, 0.0, 0.44))
		_box(Vector3(0.10, 0.09, 0.10), Color("5d8f5f"), ground + Vector3(x, 0.08, 0.44))


## Home lot: white picket fence with a gate gap, mailbox, and a flower bed.
func _decorate_home(origin: Vector3) -> void:
	var ground := origin + Vector3(0.0, GROUND_Y, 0.0)
	var fence_col := Color("f2efe6")
	# Fence rails either side of the gate (door is centred on the front face).
	for side in [-1.0, 1.0]:
		var cx: float = side * 0.30
		_box(Vector3(0.32, 0.035, 0.025), fence_col, ground + Vector3(cx, 0.10, 0.62))
		for i in 3:
			var post_x: float = cx + (i - 1) * 0.13
			_box(Vector3(0.045, 0.19, 0.035), fence_col, ground + Vector3(post_x, 0.0, 0.62))
	# Mailbox on a post by the gate, little red flag.
	_box(Vector3(0.03, 0.24, 0.03), Color("7a6a55"), ground + Vector3(0.16, 0.0, 0.70))
	_box(Vector3(0.10, 0.07, 0.07), Color("f7f4ea"), ground + Vector3(0.16, 0.24, 0.70))
	_box(Vector3(0.015, 0.06, 0.02), Color("e24b4a"), ground + Vector3(0.21, 0.28, 0.70))
	# Flower bed: green base with tiny colourful blooms.
	_box(Vector3(0.26, 0.035, 0.12), Color("5d8f5f"), ground + Vector3(-0.28, 0.0, 0.74))
	var blooms := [Color("e88ca0"), Color("f0c05a"), Color("e86a5a"), Color("d8a0e0")]
	for i in blooms.size():
		_box(Vector3(0.035, 0.05, 0.035), blooms[i],
			ground + Vector3(-0.37 + i * 0.062, 0.035, 0.74))


## Shop lot: striped awning over the front, SHOP sign, produce crates.
func _decorate_shop(origin: Vector3) -> void:
	var ground := origin + Vector3(0.0, GROUND_Y, 0.0)
	_sign(ground + Vector3(-0.45, 0.0, 0.52), "SHOP", Color("d98a4a"), 45.0)
	# (The commercial storefront model brings its own awning.)
	# Produce crates by the entrance.
	var crates := [
		{"pos": Vector3(0.30, 0.0, 0.60), "produce": Color("e8863c")},
		{"pos": Vector3(0.30, 0.0, 0.76), "produce": Color("cb4c44")},
		{"pos": Vector3(0.44, 0.0, 0.68), "produce": Color("7fb050")},
	]
	for c in crates:
		_box(Vector3(0.12, 0.08, 0.12), Color("9a7a52"), ground + c["pos"])
		for j in 3:
			_box(Vector3(0.032, 0.032, 0.032), c["produce"],
				ground + c["pos"] + Vector3(-0.032 + j * 0.033, 0.08, 0.01))


## Notice Board lot: a freestanding pinned board out front — the landmark IS
## the board (the little building behind is just its kiosk).
func _decorate_notice_board(origin: Vector3) -> void:
	var ground := origin + Vector3(0.0, GROUND_Y, 0.0)
	var root := Node3D.new()
	root.position = ground + Vector3(-0.05, 0.0, 0.72)
	root.rotation.y = deg_to_rad(45.0)
	world.add_child(root)
	# Posts + board panel + cork face.
	for x in [-0.30, 0.30]:
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.045, 0.62, 0.045)
		post.mesh = pm
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color("7a6a55")
		post.material_override = pmat
		post.position = Vector3(x, 0.31, 0.0)
		root.add_child(post)
	var panel := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.70, 0.40, 0.035)
	panel.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color("8a6b4d")
	panel.material_override = bmat
	panel.position = Vector3(0.0, 0.44, 0.0)
	root.add_child(panel)
	# Pinned notes: little pastel papers, slightly askew.
	var notes := [
		{"x": -0.24, "y": 0.50, "c": Color("f7e8a3"), "r": 4.0},
		{"x": -0.08, "y": 0.46, "c": Color("f2f0e8"), "r": -3.0},
		{"x": 0.09, "y": 0.52, "c": Color("a8d8f0"), "r": 2.0},
		{"x": 0.24, "y": 0.47, "c": Color("f0b8c8"), "r": -5.0},
		{"x": -0.16, "y": 0.36, "c": Color("bfe3b0"), "r": -2.0},
		{"x": 0.02, "y": 0.34, "c": Color("f7e8a3"), "r": 5.0},
		{"x": 0.20, "y": 0.35, "c": Color("f2f0e8"), "r": 3.0},
	]
	for n in notes:
		var note := MeshInstance3D.new()
		var nm := BoxMesh.new()
		nm.size = Vector3(0.085, 0.11, 0.008)
		note.mesh = nm
		var nmat := StandardMaterial3D.new()
		nmat.albedo_color = n["c"]
		note.material_override = nmat
		note.position = Vector3(n["x"], n["y"], 0.025)
		note.rotation.z = deg_to_rad(n["r"])
		root.add_child(note)


## Open http://.../?debug for live layout metrics (build tag + viewport math).
func _maybe_debug_overlay() -> void:
	if not OS.has_feature("web"):
		return
	var search: Variant = JavaScriptBridge.eval("window.location.search", true)
	if typeof(search) != TYPE_STRING or not ("debug" in str(search)):
		return
	var dbg := Label.new()
	dbg.name = "DebugOverlay"
	dbg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	dbg.offset_left = 12.0
	dbg.offset_top = -170.0
	dbg.add_theme_font_size_override("font_size", 16)
	dbg.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	($UI as CanvasLayer).add_child(dbg)
	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	add_child(t)
	t.timeout.connect(func() -> void:
		var js: Variant = JavaScriptBridge.eval(
			"JSON.stringify({iw:window.innerWidth,ih:window.innerHeight," +
			"dpr:window.devicePixelRatio," +
			"vvs:(window.visualViewport?window.visualViewport.scale:-1)," +
			"vvw:(window.visualViewport?window.visualViewport.width:-1)," +
			"cw:(document.getElementById('canvas')?document.getElementById('canvas').getBoundingClientRect().width:-1)})",
			true)
		dbg.text = "BUILD camfix3\nvisible_rect=%s\nwindow=%s\n%s" % [
			str(get_viewport().get_visible_rect().size),
			str(DisplayServer.window_get_size()), str(js)]
	)


# --- Feedback FX (design doc §13: money animates into/out of the wallet) -----

## Fly a batch of coins between the card and the wallet. delta>0 = earning
## (card -> wallet), delta<0 = spending (wallet -> card).
func _money_fx(delta: int) -> void:
	if delta == 0 or _hud_wallet == null:
		return
	var wallet_pos: Vector2 = _hud_wallet.get_global_position() + _hud_wallet.size * 0.5
	var card_pos: Vector2 = _card.get_global_position() + Vector2(_card.size.x * 0.5, 160.0)
	var from := card_pos if delta > 0 else wallet_pos
	var to := wallet_pos if delta > 0 else card_pos
	var count := clampi(absi(delta) / 8 + 2, 3, 9)
	Sfx.play("assets/kenney/sounds/toggle.ogg", -14.0)
	for i in count:
		_fly_coin(from, to, i * 0.05)
	var pt := create_tween()
	pt.tween_interval(0.5 + count * 0.05)
	pt.tween_callback(_pulse_wallet)


func _fly_coin(from: Vector2, to: Vector2, delay: float) -> void:
	var coin := TextureRect.new()
	coin.texture = load("res://assets/ui/coin.png")
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.size = Vector2(26, 26)
	coin.position = from - Vector2(13, 13) + Vector2(randf_range(-16, 16), randf_range(-10, 10))
	coin.modulate.a = 0.0
	($UI as CanvasLayer).add_child(coin)
	var start: Vector2 = coin.position + Vector2(13, 13)
	var mid: Vector2 = (start + to) * 0.5 + Vector2(randf_range(-30, 30), -70.0 - randf_range(0, 40))
	var tw := coin.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void: coin.modulate.a = 1.0)
	tw.tween_method(func(t: float) -> void:
		var p1 := start.lerp(mid, t)
		var p2 := mid.lerp(to, t)
		coin.position = p1.lerp(p2, t) - Vector2(13, 13)
	, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(coin.queue_free)


func _pulse_wallet() -> void:
	if _hud_wallet == null:
		return
	_hud_wallet.pivot_offset = _hud_wallet.size * 0.5
	var tw := _hud_wallet.create_tween()
	tw.tween_property(_hud_wallet, "scale", Vector2(1.28, 1.28), 0.09) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_hud_wallet, "scale", Vector2.ONE, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Gentle upward-floating icons (hearts after rest, etc.).
func _float_icons(tex_path: String, count: int) -> void:
	var origin: Vector2 = _card.get_global_position() + Vector2(_card.size.x * 0.5, 200.0)
	for i in count:
		var icon := TextureRect.new()
		icon.texture = load(tex_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2(30, 30)
		icon.position = origin + Vector2(randf_range(-70, 70), randf_range(-10, 10))
		($UI as CanvasLayer).add_child(icon)
		var tw := icon.create_tween()
		tw.tween_interval(i * 0.08)
		tw.set_parallel(true)
		tw.tween_property(icon, "position:y", icon.position.y - randf_range(70, 110), 0.7) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(icon, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
		tw.set_parallel(false)
		tw.tween_callback(icon.queue_free)


# --- Living city -------------------------------------------------------------

func _add_car(model: String, x: float, lane_z: float, dir: float, speed: float) -> void:
	var car := _spawn_free(model, Vector3(x, 0.05, lane_z), 90.0 * dir, 0.18)
	if car != null:
		_cars.append({"node": car, "speed": speed, "dir": dir})


## Find a re-entry x that isn't on top of another car in the same lane.
func _wrap_spot(entry_x: float, me: Dictionary, push_dir: float) -> float:
	var x := entry_x
	for _attempt in 4:
		var clear := true
		for o in _cars:
			if o == me or o["dir"] != me["dir"]:
				continue
			if absf(o["node"].position.x - x) < 0.7:
				clear = false
				break
		if clear:
			return x
		x += push_dir * 0.8
	return x


func _add_clouds() -> void:
	var specs := [
		{"x": 0.5, "y": 3.4, "z": 1.2, "s": 1.0, "v": 0.14},
		{"x": 3.5, "y": 4.0, "z": 3.5, "s": 1.4, "v": 0.10},
		{"x": 6.0, "y": 3.6, "z": 5.2, "s": 0.8, "v": 0.18},
	]
	for spec in specs:
		var cloud := Node3D.new()
		cloud.position = Vector3(spec["x"], spec["y"], spec["z"])
		world.add_child(cloud)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 1, 0.85)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.roughness = 1.0
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		var blobs := [Vector3.ZERO, Vector3(0.3, 0.05, 0.05), Vector3(-0.28, 0.02, -0.04)]
		var radii := [0.26, 0.19, 0.16]
		for i in blobs.size():
			var mi := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = radii[i] * float(spec["s"])
			sphere.height = radii[i] * 1.3 * float(spec["s"])
			mi.mesh = sphere
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.position = blobs[i] * float(spec["s"])
			cloud.add_child(mi)
		_clouds.append({"node": cloud, "speed": spec["v"]})


func _add_sky_bodies() -> void:
	_sun_disc_mat = StandardMaterial3D.new()
	_sun_disc_mat.albedo_color = Color(1.0, 0.85, 0.45, 1.0)
	_sun_disc_mat.emission_enabled = true
	_sun_disc_mat.emission = Color(1.0, 0.8, 0.4)
	_sun_disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sun_disc = _sky_disc(_sun_disc_mat, 0.34)
	_moon_disc_mat = StandardMaterial3D.new()
	_moon_disc_mat.albedo_color = Color(0.92, 0.93, 1.0, 0.0)
	_moon_disc_mat.emission_enabled = true
	_moon_disc_mat.emission = Color(0.7, 0.72, 0.85)
	_moon_disc = _sky_disc(_moon_disc_mat, 0.28)


func _sky_disc(mat: StandardMaterial3D, radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mi.mesh = sphere
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)
	return mi


func _update_city_life(delta: float) -> void:
	# Cars loop along the road — and never drive through the one ahead:
	# a faster car eases to the leader's speed inside the follow gap.
	for c in _cars:
		var node: Node3D = c["node"]
		var spd: float = c["speed"]
		for o in _cars:
			if o == c or o["dir"] != c["dir"]:
				continue
			var ahead: float = (o["node"].position.x - node.position.x) * c["dir"]
			if ahead > 0.001 and ahead < 0.6:
				spd = minf(spd, float(o["speed"]) * 0.95)
		node.position.x += spd * c["dir"] * delta
		if c["dir"] > 0.0 and node.position.x > 7.6:
			node.position.x = _wrap_spot(-1.6, c, -1.0)
		elif c["dir"] < 0.0 and node.position.x < -1.6:
			node.position.x = _wrap_spot(7.6, c, 1.0)
	# (helper keeps re-entering cars from stacking on one already there)
	# Clouds drift and wrap.
	for cl in _clouds:
		var cn: Node3D = cl["node"]
		cn.position.x += cl["speed"] * delta
		if cn.position.x > 9.0:
			cn.position.x = -2.5
	# The day arc: 3 slots = morning..evening; 0 slots = dusk.
	var phase: int = clampi(3 - GameState.slots_left, 0, 3)
	var t: Dictionary = DAY_PHASES[phase]
	var w := minf(delta * 1.6, 1.0)
	sun.light_energy = lerpf(sun.light_energy, t["e"], w)
	sun.light_color = sun.light_color.lerp(t["col"], w)
	sun.rotation.x = lerp_angle(sun.rotation.x, deg_to_rad(t["rot"]), w)
	if _env != null:
		_env.ambient_light_energy = lerpf(_env.ambient_light_energy, t["amb"], w)
		_env.background_color = _env.background_color.lerp(t["bg"], w)
	# Sun crosses the sky and fades at dusk; the moon rises in its place.
	if _sun_disc != null:
		var p := float(phase) / 3.0
		var sun_target := Vector3(lerpf(0.5, 6.2, p), lerpf(4.6, 3.4, p), -0.6)
		_sun_disc.position = _sun_disc.position.lerp(sun_target, w)
		_sun_disc_mat.albedo_color.a = lerpf(_sun_disc_mat.albedo_color.a,
			0.0 if phase == 3 else 1.0, w)
		_moon_disc.position = _moon_disc.position.lerp(Vector3(1.2, 4.5, -0.6), w)
		_moon_disc_mat.albedo_color.a = lerpf(_moon_disc_mat.albedo_color.a,
			1.0 if phase == 3 else 0.0, w)


# --- Building badges (design doc §5: badges on buildings ARE the UI) ---------

## A bouncing "!" over Home when the player is exhausted: go rest!
func _update_home_badge() -> void:
	var need := GameState.wellbeing < 30
	if need and _home_badge == null:
		_home_badge = Label3D.new()
		_home_badge.text = "!"
		_home_badge.font = _font
		_home_badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_home_badge.pixel_size = 0.006
		_home_badge.font_size = 96
		_home_badge.modulate = Color("e24b4a")
		_home_badge.outline_size = 14
		_home_badge.outline_modulate = Color(1, 1, 1, 1)
		_home_badge.no_depth_test = true
		var home_pos := Vector3(1.0, 1.05, 5.0)  # above the Home lot
		_home_badge.position = home_pos
		world.add_child(_home_badge)
		var bounce := _home_badge.create_tween().set_loops()
		bounce.tween_property(_home_badge, "position:y", home_pos.y + 0.14, 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bounce.tween_property(_home_badge, "position:y", home_pos.y, 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	elif not need and _home_badge != null:
		_home_badge.queue_free()
		_home_badge = null


## The evening event card (spec §12: one situation, 2-3 priced choices).
func _open_event() -> void:
	var card: Dictionary = GameState.tonight_event()
	if card.is_empty():
		_open_evening()
		return
	_current_screen = "Event"
	_screen_title.text = str(card.get("title", "Tonight"))
	_screen_body.text = str(card.get("text", ""))
	_build_actions()
	if not _screen_open:
		_show_card()


func _event_choice_label(choice: Dictionary) -> String:
	var label := str(choice.get("label", "?"))
	var dw := int(choice.get("wallet", 0))
	if dw < 0:
		label += "  ·  −€%d" % (-dw)
	elif dw > 0:
		label += "  ·  +€%d" % dw
	return label


func _do_event_choice(choice_id: String) -> void:
	var outcome: Dictionary = GameState.resolve_event_choice(choice_id)
	if outcome.is_empty():
		return
	Sfx.play(SND_OPEN, -10.0)
	_money_fx(int(outcome.get("wallet", 0)))
	var lines: Array[String] = []
	var dw := int(outcome.get("wallet", 0))
	var dwb := int(outcome.get("wellbeing", 0))
	if dw < 0:
		lines.append("−€%d from your wallet." % (-dw))
	elif dw > 0:
		lines.append("+€%d into your wallet!" % dw)
	if dwb != 0:
		lines.append("Wellbeing %+d." % dwb)
	if outcome.get("deferred", false):
		lines.append("(That might come back to bite you…)")
	if lines.is_empty():
		lines.append("Done.")
	_screen_body.text = "\n".join(lines)
	_build_actions()


func _do_gig(id: String) -> void:
	var r: Dictionary = GameState.take_gig(id)
	if r.is_empty():
		return
	Sfx.play(SND_OPEN, -10.0)
	_money_fx(int(r.get("pay", 0)))
	_screen_body.text = "%s done!\n\n+€%d straight into your wallet." % [r["label"], r["pay"]]
	_build_actions()


func _open_quiz() -> void:
	if GameState.slots_left <= 0:
		return
	_current_screen = "Quiz"
	_screen_title.text = "Bank quiz night"
	_screen_body.text = str(GameState.quiz_question().get("q", ""))
	_build_actions()


func _do_quiz_answer(idx: int) -> void:
	var r: Dictionary = GameState.answer_quiz(idx)
	if r.is_empty():
		return
	Sfx.play(SND_OPEN, -10.0)
	_money_fx(int(r.get("pay", 0)))
	_current_screen = "Notice Board"
	_screen_title.text = "Bank quiz night"
	if r.get("correct", false):
		_screen_body.text = "Correct! The quizmaster is impressed.\n\n+€%d!" % r["pay"]
	else:
		_screen_body.text = "Not quite — the right answer was:\n“%s”\n\nHere's €%d for playing. Now you know!" % [
			r["answer_text"], r["pay"]]
	_build_actions()


## Chapter 1 announcement (day-7 morning) and deadline-night resolution.
func _open_chapter_announce() -> void:
	_current_screen = "Chapter"
	_screen_title.text = "The Festival is coming!"
	_screen_body.text = "Townling's big festival is on day %d — and tickets cost €%d.\n\nCan you save that much in time? Every coin in your wallet and savings jar counts!\n\n— Aunt Vera" % [
		GameState.ch1_deadline, GameState.ch1_ticket()]
	_build_actions()
	if not _screen_open:
		_show_card()


func _open_chapter_result() -> void:
	var r: Dictionary = GameState.resolve_chapter1()
	if r.is_empty():
		return
	_current_screen = "ChapterResult"
	if r.get("success", false):
		_money_fx(-int(r.get("ticket", 0)))
		_float_icons("res://assets/ui/star.png", 6)
	if r.get("success", false):
		_screen_title.text = "FESTIVAL NIGHT! 🎉"
		_screen_body.text = "You saved €%d in time! Music, lights, and the best evening Townling has ever seen.\n\nThe string lights by the fountain are yours to keep." % r["ticket"]
	else:
		_screen_title.text = "The festival left without you…"
		_screen_body.text = "You needed €%d but didn't have it saved. It stings — and that's okay.\n\nAttempt 2: the next festival is on day %d. You know what to do now.\n\n— Aunt Vera" % [
			r["ticket"], r["next_deadline"]]
	_build_actions()
	if not _screen_open:
		_show_card()


func _after_chapter_result() -> void:
	_current_screen = "Evening"
	_open_evening()


## Spec §9: the mentor-ordered Rest Day card (Aunt Vera's first cameo).
func _open_rest_day() -> void:
	_current_screen = "RestDay"
	_screen_title.text = "Rest day — Aunt Vera's orders"
	var shift: Dictionary = GameState.econ.get("courier_shift", {})
	var missed := (int(shift.get("pay", 24)) + int(shift.get("tip", 4))) \
		* int(GameState.econ.get("slots_per_day", 3))
	_screen_body.text = "You ran yourself completely empty two days in a row, so today you rest. No work, no errands.\n\nThat's about €%d of pay you WON'T earn today. Dinner and sleep are cheaper than exhaustion!\n\n(Wellbeing +40)\n\n— Aunt Vera" % missed
	_build_actions()
	_show_card()


## Chapter 1 trophy: string lights over the fountain plaza, forever.
func _update_string_lights() -> void:
	if _lights_built or not GameState.ch1_done:
		return
	_lights_built = true
	var colors := [Color("e24b4a"), Color("f7cb60"), Color("7fb77f"), Color("8fc1e8"), Color("c9aee4")]
	for p in [[Vector3(2.55, GROUND_Y, 5.55), Vector3(3.45, GROUND_Y, 6.45)]]:
		var a: Vector3 = p[0]
		var b: Vector3 = p[1]
		for post_pos in [a, b]:
			_box(Vector3(0.035, 0.5, 0.035), Color("7a6a55"), post_pos)
		for i in 7:
			var t := (i + 1) / 8.0
			var pos := a.lerp(b, t)
			var sag := 0.08 * sin(t * PI)
			var bulb := MeshInstance3D.new()
			var bm := SphereMesh.new()
			bm.radius = 0.028
			bm.height = 0.056
			bulb.mesh = bm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = colors[i % colors.size()]
			mat.emission_enabled = true
			mat.emission = colors[i % colors.size()]
			mat.emission_energy_multiplier = 0.7
			bulb.material_override = mat
			bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			bulb.position = pos + Vector3(0, 0.48 - sag, 0)
			world.add_child(bulb)


# --- The dream on the diorama (design doc §8: dotted outline that fills) -----

const DREAM_CELLS := [Vector2i(6, 6), Vector2i(6, 0), Vector2i(0, 6)]

## Rebuild the monuments when the dream chain or progress bucket changes.
## Completed dreams stand gold forever; the active one is a ghost filling in.
func _update_dream_spot() -> void:
	var key := "%s|%s:%d:%s" % [
		",".join(PackedStringArray(GameState.completed_dreams)),
		GameState.dream_id, int(GameState.dream_progress() * 10.0),
		str(GameState.dream_complete())]
	if key == _dream_spot_key:
		return
	_dream_spot_key = key
	if _dream_spot != null:
		_dream_spot.queue_free()
		_dream_spot = null
	if GameState.dream_id == "" and GameState.completed_dreams.is_empty():
		return

	_dream_spot = Node3D.new()
	world.add_child(_dream_spot)

	# Past dreams: gold monuments on their corners.
	for i in GameState.completed_dreams.size():
		if i >= DREAM_CELLS.size():
			break
		var gold := StandardMaterial3D.new()
		gold.albedo_color = Color(0.95, 0.83, 0.5, 1.0)
		gold.roughness = 0.9
		gold.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		_build_dream_shape(str(GameState.completed_dreams[i]),
			Vector3(DREAM_CELLS[i].x * TILE, GROUND_Y, DREAM_CELLS[i].y * TILE), gold, "")

	# The active dream: ghost -> solid -> gold on its own corner.
	if GameState.dream_id == "":
		return
	var slot: int = mini(GameState.completed_dreams.size(), DREAM_CELLS.size() - 1)
	var origin := Vector3(DREAM_CELLS[slot].x * TILE, GROUND_Y, DREAM_CELLS[slot].y * TILE)
	var mat := StandardMaterial3D.new()
	if GameState.dream_complete():
		mat.albedo_color = Color(0.95, 0.83, 0.5, 1.0)   # solid gold — it's real!
	else:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1, 1, 1, 0.22 + 0.55 * GameState.dream_progress())
	mat.roughness = 0.9
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var tag_text := "DREAM COME TRUE!" if GameState.dream_complete() else "MY DREAM"
	_build_dream_shape(GameState.dream_id, origin, mat, tag_text)


## The little low-poly silhouette for a dream id, built at `origin`.
func _build_dream_shape(id: String, origin: Vector3, mat: Material, tag_text: String) -> void:
	var group := Node3D.new()
	group.position = origin
	_dream_spot.add_child(group)
	var prev := _dream_group
	_dream_group = group
	match id:
		"treehouse":
			_dream_mesh(_box_mesh(Vector3(0.12, 0.5, 0.12)), Vector3(0, 0.25, 0), mat)
			_dream_mesh(_box_mesh(Vector3(0.44, 0.05, 0.44)), Vector3(0, 0.52, 0), mat)
			_dream_mesh(_box_mesh(Vector3(0.3, 0.22, 0.3)), Vector3(0, 0.65, 0), mat)
			_dream_mesh(_prism_mesh(Vector3(0.36, 0.16, 0.36)), Vector3(0, 0.84, 0), mat)
		"puppy":
			_dream_mesh(_box_mesh(Vector3(0.34, 0.26, 0.34)), Vector3(0, 0.13, 0), mat)
			_dream_mesh(_prism_mesh(Vector3(0.4, 0.18, 0.4)), Vector3(0, 0.35, 0), mat)
		"ocean":
			_dream_mesh(_box_mesh(Vector3(0.5, 0.1, 0.2)), Vector3(0, 0.1, 0), mat)
			_dream_mesh(_box_mesh(Vector3(0.03, 0.34, 0.03)), Vector3(0, 0.32, 0), mat)
			_dream_mesh(_prism_mesh(Vector3(0.26, 0.24, 0.02)), Vector3(0.13, 0.32, 0), mat)
		"ramp":
			_dream_mesh(_prism_mesh(Vector3(0.3, 0.22, 0.36)), Vector3(-0.18, 0.11, 0), mat, 90.0)
			_dream_mesh(_prism_mesh(Vector3(0.3, 0.22, 0.36)), Vector3(0.18, 0.11, 0), mat, -90.0)

	if tag_text != "":
		var tag := Label3D.new()
		tag.text = tag_text
		tag.font = _font
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.pixel_size = 0.003
		tag.font_size = 30
		tag.modulate = Color("7a5410")
		tag.outline_size = 8
		tag.outline_modulate = Color(1, 1, 1, 0.9)
		tag.position = Vector3(0, 1.15, 0)
		group.add_child(tag)
	_dream_group = prev if prev != null else group


func _dream_mesh(mesh: Mesh, pos: Vector3, mat: Material, rot_deg: float = 0.0) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = deg_to_rad(rot_deg)
	_dream_group.add_child(mi)


func _box_mesh(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


func _prism_mesh(size: Vector3) -> PrismMesh:
	var m := PrismMesh.new()
	m.size = size
	return m


## A little scattered colour on the sidewalks (fixed, deterministic).
func _scatter_confetti() -> void:
	var spots := [
		[Vector3(0.4, 0, 2.3), Color("f0b8c8"), 15.0],
		[Vector3(2.3, 0, 1.72), Color("a8d8f0"), -20.0],
		[Vector3(4.7, 0, 2.25), Color("f7e8a3"), 40.0],
		[Vector3(5.6, 0, 1.8), Color("bfe3b0"), -10.0],
		[Vector3(1.6, 0, 4.28), Color("a8d8f0"), 30.0],
		[Vector3(3.8, 0, 4.2), Color("f0b8c8"), -35.0],
		[Vector3(5.2, 0, 4.3), Color("f7e8a3"), 10.0],
	]
	for s in spots:
		_box(Vector3(0.06, 0.004, 0.06), s[1], s[0] + Vector3(0, GROUND_Y, 0), s[2])


## Floating billboard name label at a world position (world-parented so it
## never inherits a scaled building's transform).
func _add_label_at(pos: Vector3, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = _font
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.0035
	label.font_size = 40
	label.outline_size = 10
	label.modulate = Color("1c1b19")
	label.outline_modulate = Color(1, 1, 1, 0.95)
	label.position = pos
	world.add_child(label)


func _setup_camera() -> void:
	# Kenney-style camera: narrow-fov perspective (fov 20 at distance ~30),
	# orbiting the diorama centre snow-globe style (yaw + zoom only).
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = 20.0
	_apply_camera()


func _cam_target_point() -> Vector3:
	return Vector3((COLS - 1) * TILE * 0.5, 0.8, (ROWS - 1) * TILE * 0.5)


func _apply_camera() -> void:
	# Elevation fixed at the isometric angle; yaw and distance are the dials.
	var t := _cam_target_point()
	var h := 0.7928 * _cam_dist
	var v := 0.6073 * _cam_dist
	camera.position = t + Vector3(cos(_cam_yaw) * h, v, sin(_cam_yaw) * h)
	camera.look_at(t, Vector3.UP)


# --- Interaction: tap a building -> open its screen -------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _screen_open:
		return
	# Zoom (wheel / pinch), bounded so the town always fills the view.
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cam_dist_target = clampf(_cam_dist_target - 2.0, 20.0, 42.0)
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cam_dist_target = clampf(_cam_dist_target + 2.0, 20.0, 42.0)
			return
	if event is InputEventMagnifyGesture:
		_cam_dist_target = clampf(_cam_dist_target / event.factor, 20.0, 42.0)
		return
	# Drag = orbit; a still press-release = tap (building pick).
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.double_click:
				_cam_yaw_target = 0.7853981634
				_cam_dist_target = 30.0
				_press_pos = Vector2.INF
				return
			_press_pos = event.position
			_orbit_drag = false
			return
		else:
			var was_drag := _orbit_drag
			var press := _press_pos
			_press_pos = Vector2.INF
			_orbit_drag = false
			if was_drag or press == Vector2.INF:
				return
			_pick_at(event.position)
			return
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_pos = event.position
			_orbit_drag = false
		else:
			var was_drag2 := _orbit_drag
			var press2 := _press_pos
			_press_pos = Vector2.INF
			_orbit_drag = false
			if not was_drag2 and press2 != Vector2.INF:
				_pick_at(event.position)
		return
	if (event is InputEventMouseMotion and _press_pos != Vector2.INF) \
			or event is InputEventScreenDrag:
		if _press_pos == Vector2.INF:
			return
		if not _orbit_drag and event.position.distance_to(_press_pos) > 14.0:
			_orbit_drag = true
		if _orbit_drag:
			_cam_yaw_target += event.relative.x * 0.006
		return


func _pick_at(pos: Vector2) -> void:
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
	# A friendly pop on the tapped building before its screen slides in.
	var bnode: Node3D = pick.get("node")
	if bnode != null:
		var base: Vector3 = bnode.scale
		var bt := bnode.create_tween()
		bt.tween_property(bnode, "scale", base * 1.1, 0.09) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		bt.tween_property(bnode, "scale", base, 0.14) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_current_screen = pick["name"]
	_screen_title.text = pick["name"]
	_screen_body.text = pick["blurb"]
	_build_actions()
	_show_card()


## Evening summary (spec §3): three simple lines, then the event slot, then sleep.
func _open_evening() -> void:
	if GameState.ch1_due_tonight():
		_open_chapter_result()
		return
	GameState.prepare_tonight()
	_current_screen = "Evening"
	_screen_title.text = "Day %d — Evening" % GameState.day
	var lines := "Earned  ↑  €%d\nSpent   ↓  €%d" % [
		GameState.earned_today, GameState.spent_today]
	if GameState.rent_due_tonight():
		lines += "\nRent    ↓  €%d  (due tonight)" % GameState.rent_amount()
	lines += "\nWallet  =  €%d" % GameState.wallet
	var wear := int(GameState._wb().get("day_wear", -10))
	if GameState.groceries_today == "":
		var hungry := int(GameState._wb().get("hungry_night", -15))
		lines += "\n\nOvernight sleep: no dinner — you won't sleep well!\nDay's wear %d, hungry night %d  →  %d energy" % [
			wear, hungry, wear + hungry]
	else:
		var sleep_gain := int(GameState._grocery_tier(GameState.groceries_today).get("sleep", 12))
		lines += "\n\nOvernight sleep: day's wear %d, dinner restores +%d (%s)  →  %+d energy" % [
			wear, sleep_gain, GameState.groceries_today, wear + sleep_gain]
	if GameState.dream_id != "" and not GameState.dream_complete():
		lines += "\nDream fund:  €%d / €%d" % [GameState.dream_saved, GameState.dream_cost()]
	_screen_body.text = lines
	_build_actions()
	_show_card()


func _show_card() -> void:
	_screen_open = true
	_screen.visible = true
	Sfx.play(SND_OPEN, -8.0)
	_size_card()
	var vp := get_viewport().get_visible_rect().size
	_card.position = Vector2(16.0, vp.y)
	_screen.modulate.a = 0.0
	var fade := _screen.create_tween()
	fade.tween_property(_screen, "modulate:a", 1.0, 0.16)
	var tween := create_tween()
	tween.tween_property(_card, "position:y", CARD_TOP + 14.0, 0.22) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_card, "position:y", CARD_TOP, 0.12) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _close_screen() -> void:
	if not _screen_open:
		return
	_screen_open = false
	var was := _current_screen
	_current_screen = ""
	Sfx.play(SND_CLOSE, -8.0)
	var vp := get_viewport().get_visible_rect().size
	var tween := create_tween()
	tween.tween_property(_card, "position:y", vp.y, 0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		_screen.visible = false
		# Dusk: when the last slot is spent, the evening summary follows
		# (a natural stopping point, spec §3).
		if was != "Evening" and GameState.slots_left <= 0:
			_open_evening()
	)


# --- Per-building actions ----------------------------------------------------

## Day-1 dream picker (spec §2 minute 2-3): install the pull before the grind.
func _open_dream_picker() -> void:
	_current_screen = "Dream"
	_screen_title.text = "Choose your dream!"
	_screen_body.text = "What are you saving up for? Everything you earn in Townling can bring it closer."
	_build_actions()
	_show_card()


func _build_actions() -> void:
	for child in _actions.get_children():
		child.queue_free()
	match _current_screen:
		"Dream":
			if GameState.dream_id == "" or GameState.dream_complete():
				for d in GameState.available_dreams():
					var db := _action_button("%s  ·  €%d" % [d.get("label", "?"), int(d.get("cost", 0))])
					var did: String = d.get("id", "")
					db.pressed.connect(func() -> void: _pick_dream(did))
			else:
				var go := _action_button("Let's go!")
				go.pressed.connect(_close_screen)
		"Workplace":
			if not GameState.can_work_today():
				_screen_body.text += "\n\nToday's shift is done — nice work! Extra coins? Check the Notice Board for gigs."
			var preview: Dictionary = GameState.shift_pay_preview()
			match str(preview.get("tier", "")):
				"thriving":
					_screen_body.text += "\n\nYou feel great — customers tip extra!"
				"tired":
					_screen_body.text += "\n\nYou're tired — shifts pay less until you rest."
				"exhausted":
					_screen_body.text += "\n\nYou're exhausted! Rest and a good dinner will fix your pay."
			var b := _action_button("Work a shift  ·  1 slot  ·  +€%d" % int(preview.get("amount", 0)))
			b.disabled = GameState.slots_left <= 0 or not GameState.can_work_today()
			b.pressed.connect(_do_shift)
		"Shop":
			for tier in GameState.econ.get("groceries", []):
				var cost := int(tier.get("cost", 0))
				var gb := _action_button("%s groceries  ·  1 slot  ·  −€%d" % [tier.get("label", "?"), cost])
				gb.disabled = (
					GameState.slots_left <= 0
					or GameState.groceries_today != ""
					or GameState.wallet < cost
				)
				var tid: String = tier.get("id", "")
				gb.pressed.connect(func() -> void: _do_groceries(tid))
			if GameState.groceries_today != "":
				_screen_body.text += "\n\nYou already shopped today."
		"Home":
			var days_left := 7 - ((GameState.day - 1) % 7 + 1)
			var rent_line := "Rent €%d is due tonight!" % GameState.rent_amount() \
				if GameState.rent_due_tonight() else \
				"Rent €%d due in %d day%s." % [GameState.rent_amount(), days_left, "" if days_left == 1 else "s"]
			_screen_body.text += "\n\n" + rent_line
			_screen_body.text += "\nNaps give energy now — tonight's sleep depends on dinner."
			if GameState.dream_id != "" and not GameState.dream_complete():
				_screen_body.text += "\nDream:  %s  €%d / €%d" % [
					GameState.dream_def().get("label", ""), GameState.dream_saved, GameState.dream_cost()]
			var r := _action_button("Nap & recharge  ·  1 slot  ·  +15 energy NOW")
			r.disabled = GameState.slots_left <= 0
			r.pressed.connect(_do_rest)
			if GameState.dream_id != "" and not GameState.dream_complete():
				var step := int(GameState.econ.get("dream_step", 25))
				var fd := _action_button("Put €%d toward your dream" % step)
				fd.disabled = GameState.wallet <= 0
				fd.pressed.connect(_do_fund_dream)
			elif GameState.dream_complete() and GameState.available_dreams().size() > 0:
				var nd := _action_button("Choose my NEXT dream!")
				nd.pressed.connect(_open_dream_picker)
		"Bank":
			_screen_body.text += "\n\nSavings jar:  €%d" % GameState.savings
			if GameState.ledger.size() > 0:
				_screen_body.text += "\n\nRecent activity:"
				var start: int = maxi(0, GameState.ledger.size() - 8)
				for i in range(GameState.ledger.size() - 1, start - 1, -1):
					var e: Dictionary = GameState.ledger[i]
					var amt := int(e.get("a", 0))
					_screen_body.text += "\nDay %d  ·  %s  %s€%d" % [
						int(e.get("d", 0)), e.get("t", "?"),
						"+" if amt >= 0 else "−", absi(amt)]
			var step := int(GameState.econ.get("savings_step", 10))
			var d := _action_button("Deposit €%d" % step)
			d.disabled = GameState.wallet < step
			d.pressed.connect(func() -> void: _do_bank(step, true))
			var w := _action_button("Withdraw €%d" % step)
			w.disabled = GameState.savings < step
			w.pressed.connect(func() -> void: _do_bank(step, false))
		"Evening":
			if GameState.tonight_event_id != "":
				var evb := _action_button("Something's happening outside…")
				evb.pressed.connect(_open_event)
			else:
				var s := _action_button("Sleep  💤  ·  start day %d" % (GameState.day + 1))
				s.pressed.connect(_do_sleep)
		"RestDay":
			var ok := _action_button("Okay, I'll rest…")
			ok.pressed.connect(_close_screen)
		"Event":
			var card: Dictionary = GameState.tonight_event()
			if card.is_empty():
				var zz := _action_button("Sleep  💤")
				zz.pressed.connect(_do_sleep)
			else:
				for choice in card.get("choices", []):
					var cb := _action_button(_event_choice_label(choice))
					var cost := -int(choice.get("wallet", 0))
					cb.disabled = cost > 0 and GameState.wallet < cost
					var cid: String = choice.get("id", "")
					cb.pressed.connect(func() -> void: _do_event_choice(cid))
		"Notice Board":
			if GameState.gigs_today.is_empty():
				_screen_body.text += "\n\nNo gigs left today — fresh ones tomorrow!"
			for gid in GameState.gigs_today:
				var g: Dictionary = GameState.gig_def(gid)
				if g.is_empty():
					continue
				if bool(g.get("quiz", false)):
					var qb := _action_button("%s  ·  1 slot  ·  answer to earn" % g.get("label", "?"))
					qb.disabled = GameState.slots_left <= 0
					qb.pressed.connect(_open_quiz)
				else:
					var gb := _action_button("%s  ·  1 slot  ·  +€%d" % [g.get("label", "?"), int(g.get("base", 0))])
					gb.disabled = GameState.slots_left <= 0
					var gid2: String = gid
					gb.pressed.connect(func() -> void: _do_gig(gid2))
		"Quiz":
			var q: Dictionary = GameState.quiz_question()
			var answers: Array = q.get("answers", [])
			for i in answers.size():
				var ab := _action_button(str(answers[i]))
				var idx: int = i
				ab.pressed.connect(func() -> void: _do_quiz_answer(idx))
		"Chapter":
			var okb := _action_button("I'm in! Let's save up!")
			okb.pressed.connect(_close_screen)
		"ChapterResult":
			var cb2 := _action_button("Continue")
			cb2.pressed.connect(_after_chapter_result)
		_:
			_screen_body.text += "\n\n(coming soon)"
	# Must-answer screens have no escape hatch (dream pick, live event).
	if _close_btn != null:
		var must_answer := (
			(_current_screen == "Dream" and GameState.dream_id == "")
			or (_current_screen == "Event" and GameState.tonight_event_id != "")
		)
		_close_btn.visible = not must_answer


func _action_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 72)
	b.add_theme_font_size_override("font_size", 28)
	_actions.add_child(b)
	return b


func _pick_dream(id: String) -> void:
	var ok := GameState.start_new_dream(id) if GameState.dream_complete() \
		else GameState.select_dream(id)
	if not ok:
		return
	Sfx.play(SND_OPEN, -8.0)
	_screen_body.text = "A %s! Wonderful choice.\n\nLook for the ghostly outline in town — every coin you put toward it makes it more real." % GameState.dream_def().get("label", "")
	_build_actions()


func _do_fund_dream() -> void:
	var r: Dictionary = GameState.fund_dream()
	if r.is_empty():
		return
	Sfx.play(SND_OPEN, -10.0)
	_money_fx(-int(r.get("added", 0)))
	if r.get("completed", false):
		_float_icons("res://assets/ui/star.png", 7)
		_screen_body.text = "YOU DID IT! Your %s is real — go look at it in town!\n\nYou saved €%d in %d days, €25 at a time. Small choices, big things.\n\n— Aunt Vera" % [
			GameState.dream_def().get("label", ""), GameState.dream_cost(), GameState.dream_days()]
	else:
		_screen_body.text = "€%d closer to your %s!\n\nDream fund:  €%d / €%d" % [
			r["added"], GameState.dream_def().get("label", ""),
			GameState.dream_saved, GameState.dream_cost()]
	_build_actions()


func _do_shift() -> void:
	var r: Dictionary = GameState.work_shift()
	if r.is_empty():
		return
	Sfx.play(SND_OPEN, -10.0)
	_money_fx(int(r.get("amount", 0)))
	match str(r.get("tier", "fine")):
		"thriving":
			_screen_body.text = "Deliveries done with a spring in your step!\n\n+€%d — including a €%d good-mood tip!" % [r["amount"], r["bonus"]]
		"tired":
			_screen_body.text = "Deliveries done… slowly. You're tired.\n\n+€%d (reduced pay). Some rest would help!" % r["amount"]
		"exhausted":
			_screen_body.text = "You dragged yourself through the shift.\n\n+€%d (exhausted pay). Rest and eat well tonight!" % r["amount"]
		_:
			_screen_body.text = "Deliveries done — nice work!\n\n+€%d into your wallet." % r["amount"]
	_build_actions()


func _do_groceries(tier_id: String) -> void:
	var r: Dictionary = GameState.buy_groceries(tier_id)
	if r.is_empty():
		return
	Sfx.play(SND_OPEN, -10.0)
	_money_fx(-int(r.get("cost", 0)))
	_screen_body.text = "%s groceries — the fridge is stocked.\n\n−€%d from your wallet." % [
		r["label"], r["cost"]]
	_build_actions()


func _do_rest() -> void:
	if not GameState.rest():
		return
	_float_icons("res://assets/ui/heart.png", 4)
	_screen_body.text = "A lovely nap: +15 energy right now.\n\nTonight's SLEEP is different — how well you sleep depends on dinner!"
	_build_actions()


func _do_bank(amount: int, into_savings: bool) -> void:
	var ok := GameState.deposit(amount) if into_savings else GameState.withdraw(amount)
	if not ok:
		return
	Sfx.play(SND_OPEN, -12.0)
	_money_fx(-amount if into_savings else amount)
	_screen_body.text = "Your coins are safe in the jar." if into_savings \
		else "Coins back in your pocket."
	_build_actions()


func _do_sleep() -> void:
	GameState.end_day()
	_close_screen()
	if GameState.forced_rest_today:
		_open_rest_day.call_deferred()
	elif GameState.ch1_announce_pending:
		GameState.ch1_announce_pending = false
		GameState.save_game()
		_open_chapter_announce.call_deferred()


# --- UI --------------------------------------------------------------------

func _setup_ui() -> void:
	var ui: CanvasLayer = $UI

	_screen = Control.new()
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen.visible = false
	_screen.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			# The dream picker and tonight's event must be answered, not dismissed.
			if _current_screen == "Dream" and GameState.dream_id == "":
				return
			if _current_screen == "Event" and GameState.tonight_event_id != "":
				return
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

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(72, 72)
	_close_btn.add_theme_font_size_override("font_size", 36)
	_close_btn.pressed.connect(_close_screen)
	header.add_child(_close_btn)

	_screen_body = Label.new()
	_screen_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_screen_body.add_theme_color_override("font_color", Color("7a5410"))
	_screen_body.add_theme_font_size_override("font_size", 30)
	col.add_child(_screen_body)

	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", 12)
	col.add_child(_actions)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)

	_size_card()

	# --- HUD: day, wallet, energy slots (top-right; the wallet is the single
	# always-visible number, design doc §13) ---------------------------------
	var hud := VBoxContainer.new()
	hud.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hud.offset_left = -340.0
	hud.offset_right = -20.0
	hud.offset_top = 16.0
	hud.add_theme_constant_override("separation", 4)
	ui.add_child(hud)

	_hud_day = Label.new()
	_hud_day.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_day.add_theme_color_override("font_color", Color("2c2c2a"))
	_hud_day.add_theme_font_size_override("font_size", 24)
	hud.add_child(_hud_day)

	var wallet_row := HBoxContainer.new()
	wallet_row.alignment = BoxContainer.ALIGNMENT_END
	wallet_row.add_theme_constant_override("separation", 8)
	hud.add_child(wallet_row)

	_hud_wallet = Label.new()
	_hud_wallet.add_theme_color_override("font_color", Color("7a5410"))
	_hud_wallet.add_theme_font_size_override("font_size", 34)
	wallet_row.add_child(_hud_wallet)
	wallet_row.add_child(_hud_icon("res://assets/ui/coin.png", 36))

	# Energy bolts (the day's 3 slots).
	var bolt_row := HBoxContainer.new()
	bolt_row.alignment = BoxContainer.ALIGNMENT_END
	bolt_row.add_theme_constant_override("separation", 2)
	hud.add_child(bolt_row)
	for i in int(GameState.econ.get("slots_per_day", 3)):
		var bolt := _hud_icon("res://assets/ui/bolt.png", 30)
		bolt_row.add_child(bolt)
		_hud_bolts.append(bolt)

	# Wellbeing: heart + bar.
	var heart_row := HBoxContainer.new()
	heart_row.alignment = BoxContainer.ALIGNMENT_END
	heart_row.add_theme_constant_override("separation", 6)
	hud.add_child(heart_row)
	_hud_heart_icon = _hud_icon("res://assets/ui/heart.png", 28)
	heart_row.add_child(_hud_heart_icon)
	_hud_heart = _hud_bar(Color("e24b4a"), Vector2(110, 14))
	heart_row.add_child(_hud_heart)

	# The dream: star + progress toward the goal.
	var dream_row := HBoxContainer.new()
	dream_row.alignment = BoxContainer.ALIGNMENT_END
	dream_row.add_theme_constant_override("separation", 6)
	hud.add_child(dream_row)
	dream_row.add_child(_hud_icon("res://assets/ui/star.png", 28))
	_hud_dream_label = Label.new()
	_hud_dream_label.add_theme_color_override("font_color", Color("7a5410"))
	_hud_dream_label.add_theme_font_size_override("font_size", 20)
	dream_row.add_child(_hud_dream_label)
	_hud_dream_bar = _hud_bar(Color("e7b24c"), Vector2(84, 14))
	dream_row.add_child(_hud_dream_bar)

	_hud_chapter = Label.new()
	_hud_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_chapter.add_theme_color_override("font_color", Color("6d5a8a"))
	_hud_chapter.add_theme_font_size_override("font_size", 18)
	hud.add_child(_hud_chapter)


func _hud_icon(path: String, px: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = load(path)
	icon.custom_minimum_size = Vector2(px, px)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _hud_bar(fill: Color, size: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = size
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.max_value = 100.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.19, 0.17, 0.35)
	bg.set_corner_radius_all(8)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar


## Exhausted state: the heart pulses for attention (visible consequence cue).
func _process(delta: float) -> void:
	var w := minf(delta * 10.0, 1.0)
	if absf(_cam_yaw - _cam_yaw_target) > 0.0005 or absf(_cam_dist - _cam_dist_target) > 0.01:
		_cam_yaw = lerp_angle(_cam_yaw, _cam_yaw_target, w)
		_cam_dist = lerpf(_cam_dist, _cam_dist_target, w)
		_apply_camera()
	_update_city_life(delta)
	if _hud_heart_icon == null:
		return
	if GameState.wellbeing < 30:
		_blink_time += delta
		_hud_heart_icon.modulate.a = 0.45 + 0.55 * absf(sin(_blink_time * 5.0))
	elif _hud_heart_icon.modulate.a != 1.0:
		_hud_heart_icon.modulate.a = 1.0


func _refresh_hud() -> void:
	if _hud_day == null:
		return
	_hud_day.text = "Day %d" % GameState.day
	_hud_wallet.text = "€%d" % GameState.wallet
	for i in _hud_bolts.size():
		_hud_bolts[i].modulate.a = 1.0 if i < GameState.slots_left else 0.2
	_hud_heart.value = float(GameState.wellbeing)
	var heart_fill := StyleBoxFlat.new()
	heart_fill.set_corner_radius_all(8)
	if GameState.wellbeing >= 60:
		heart_fill.bg_color = Color("7fb77f")
	elif GameState.wellbeing >= 30:
		heart_fill.bg_color = Color("e7b24c")
	else:
		heart_fill.bg_color = Color("e24b4a")
	_hud_heart.add_theme_stylebox_override("fill", heart_fill)
	if GameState.dream_id == "":
		_hud_dream_label.text = "pick a dream!"
		_hud_dream_bar.value = 0.0
	elif GameState.dream_complete():
		_hud_dream_label.text = "%s ✔ — new dream?" % GameState.dream_def().get("label", "")
		_hud_dream_bar.value = 100.0
	else:
		_hud_dream_label.text = "€%d/€%d" % [GameState.dream_saved, GameState.dream_cost()]
		_hud_dream_bar.value = GameState.dream_progress() * 100.0
	if GameState.ch1_active:
		_hud_chapter.text = "Festival €%d/€%d · day %d" % [
			GameState.ch1_progress(), GameState.ch1_ticket(), GameState.ch1_deadline]
	elif GameState.ch1_done:
		_hud_chapter.text = ""
	else:
		_hud_chapter.text = ""
	_update_dream_spot()
	_update_home_badge()
	_update_string_lights()


const CARD_TOP := 196.0

func _size_card() -> void:
	var vp := get_viewport().get_visible_rect().size
	var size := Vector2(vp.x - 32.0, vp.y - CARD_TOP - 32.0)
	_card.custom_minimum_size = size
	_card.size = size


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED and _card != null:
		_size_card()
		if _screen_open:
			_card.position = Vector2(16.0, CARD_TOP)


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
