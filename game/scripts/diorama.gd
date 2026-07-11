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
		var focus := Vector3(1.0, 0.7, 1.2)  # the Bank lot
		var dir := Vector3(1.0, 1.05, 1.0).normalized()
		camera.position = focus + dir * 11.0
		camera.look_at(focus, Vector3.UP)
	elif "--zoom2" in OS.get_cmdline_args():
		var focus2 := Vector3(3.0, 0.4, 5.0)  # south row: Home/Shop/Notice Board
		var dir2 := Vector3(1.0, 1.05, 1.0).normalized()
		camera.position = focus2 + dir2 * 12.0
		camera.look_at(focus2, Vector3.UP)
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
	sun.light_energy = 1.0
	sun.light_color = Color("fff1dc")     # gently golden, ~5000K
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.9
	sun.shadow_blur = 1.5

	# Single-sun setup; the counter-fill stays off.
	($Sun2 as DirectionalLight3D).visible = false

	var env := ($WorldEnvironment as WorldEnvironment).environment
	env.background_color = Color("c2c5aa")           # warm sage backdrop
	env.ambient_light_color = Color("c6c8bc")        # sage-grey fill, cooler than sun
	env.ambient_light_energy = 0.45
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
		Vector2i(5, 6), Vector2i(6, 6),
	]
	var tall := true
	for cell in tree_cells:
		_spawn("grass-trees-tall" if tall else "grass-trees", cell)
		tall = not tall

	# A fountain centrepiece in the front park, and a little sidewalk colour.
	_spawn("pavement-fountain", FOUNTAIN_CELL)
	_scatter_confetti()


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
	# Striped awning above the shopfront (front wall at z≈+0.5), angled down.
	var stripe_cols := [Color("8fd0a8"), Color("f5efdd")]
	for i in 6:
		var sx := -0.225 + i * 0.09
		_box(Vector3(0.088, 0.018, 0.24), stripe_cols[i % 2],
			origin + Vector3(sx, 0.40, 0.60), 0.0, 22.0)
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


func _add_label(building: Node3D, text: String, height: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = _font
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.0035
	label.font_size = 40
	label.outline_size = 10
	label.modulate = Color("1c1b19")
	label.outline_modulate = Color(1, 1, 1, 0.95)
	label.position = Vector3(0.0, height + 0.35, 0.0)
	building.add_child(label)


func _setup_camera() -> void:
	# Kenney-style camera: narrow-fov perspective (fov 20 at distance ~30)
	# instead of pure orthographic — reads isometric but keeps a whisper of
	# depth, matching the kit's own scene.
	var target := Vector3((COLS - 1) * TILE * 0.5, 0.8, (ROWS - 1) * TILE * 0.5)
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = 20.0
	var dir := Vector3(12.0, 13.0, 12.0).normalized()
	camera.position = target + dir * 30.0
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
