extends Node
## Townling game state — the client-side simulation core (design doc §18:
## the whole economy runs on-device, offline-first).
##
## First slice of the moment/day loop (spec §2–§3): a day gives 3 energy
## slots; a shift, a shopping trip or a rest costs one slot; micro-actions
## (bank deposits) are free. Evening closes the day; every 7th day charges
## rent. Wellbeing, salary/payday, gigs, skills and events come next.
##
## Tunables live in res://data/economy.json — data, not code.

signal changed

const ECONOMY_PATH := "res://data/economy.json"
const SAVE_PATH := "user://townling_save.json"

var econ: Dictionary = {}

var wallet: int = 0
var savings: int = 0
var day: int = 1
var slots_left: int = 3
var earned_today: int = 0
var spent_today: int = 0
var groceries_today: String = ""  # grocery tier id bought today ("" = none)
var wellbeing: int = 70           # 0-100 (spec §9); low wellbeing reduces pay
var dream_id: String = ""         # the dream (design doc §8) — "" until chosen
var dream_saved: int = 0          # coins put toward the dream so far

## Disable to keep unit tests from touching user:// saves.
var autosave: bool = true


func _ready() -> void:
	load_economy()
	if not load_game():
		init_new()


func load_economy() -> void:
	var f := FileAccess.open(ECONOMY_PATH, FileAccess.READ)
	if f == null:
		push_error("economy.json missing")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		econ = parsed


func init_new() -> void:
	wallet = int(econ.get("starter_wallet", 50))
	savings = 0
	day = 1
	slots_left = int(econ.get("slots_per_day", 3))
	earned_today = 0
	spent_today = 0
	groceries_today = ""
	wellbeing = int(_wb().get("start", 70))
	dream_id = ""
	dream_saved = 0
	_after_change()


# --- Slot actions -----------------------------------------------------------

## Work a Courier shift: one slot, instant pay + tip (spec §2 day-1 values).
func work_shift() -> Dictionary:
	if slots_left <= 0:
		return {}
	var shift: Dictionary = econ.get("courier_shift", {})
	var amount := int(shift.get("pay", 24)) + int(shift.get("tip", 4))
	var tired := wellbeing < int(_wb().get("low_threshold", 30))
	if tired:
		amount = int(amount * float(_wb().get("low_pay_mult", 0.8)))
	slots_left -= 1
	wallet += amount
	earned_today += amount
	_after_change()
	return {"amount": amount, "tired": tired}


## Buy groceries (one tier per day): one slot.
func buy_groceries(tier_id: String) -> Dictionary:
	if slots_left <= 0 or groceries_today != "":
		return {}
	var tier := _grocery_tier(tier_id)
	if tier.is_empty():
		return {}
	var cost := int(tier.get("cost", 0))
	if wallet < cost:
		return {}
	slots_left -= 1
	wallet -= cost
	spent_today += cost
	groceries_today = tier_id
	_after_change()
	return {"cost": cost, "label": tier.get("label", tier_id)}


## Rest: one slot; refills wellbeing (spec §9 — rest is a resource).
func rest() -> bool:
	if slots_left <= 0:
		return false
	slots_left -= 1
	wellbeing = clampi(wellbeing + int(_wb().get("rest_gain", 20)), 0, 100)
	_after_change()
	return true


# --- Micro-actions (free) ---------------------------------------------------

func deposit(amount: int) -> bool:
	if amount <= 0 or wallet < amount:
		return false
	wallet -= amount
	savings += amount
	_after_change()
	return true


func withdraw(amount: int) -> bool:
	if amount <= 0 or savings < amount:
		return false
	savings -= amount
	wallet += amount
	_after_change()
	return true


# --- The dream (design doc §8: the reason to earn) ----------------------------

func select_dream(id: String) -> bool:
	if dream_id != "" or _dream_def(id).is_empty():
		return false
	dream_id = id
	dream_saved = 0
	_after_change()
	return true


func dream_def() -> Dictionary:
	return _dream_def(dream_id)


func dream_cost() -> int:
	return int(dream_def().get("cost", 0))


func dream_progress() -> float:
	var cost := dream_cost()
	return 0.0 if cost == 0 else clampf(float(dream_saved) / float(cost), 0.0, 1.0)


func dream_complete() -> bool:
	return dream_id != "" and dream_saved >= dream_cost() and dream_cost() > 0


## Put coins toward the dream (design doc §8: money is the bridge to it).
func fund_dream() -> Dictionary:
	if dream_id == "" or dream_complete():
		return {}
	var step := int(econ.get("dream_step", 25))
	var amount: int = mini(step, mini(dream_cost() - dream_saved, wallet))
	if amount <= 0:
		return {}
	wallet -= amount
	dream_saved += amount
	spent_today += amount
	_after_change()
	return {"added": amount, "completed": dream_complete()}


func _dream_def(id: String) -> Dictionary:
	for d in econ.get("dreams", []):
		if d.get("id", "") == id:
			return d
	return {}


# --- Day cycle ---------------------------------------------------------------

## Whether tonight's summary will include rent (every 7th day).
func rent_due_tonight() -> bool:
	return day % 7 == 0


func rent_amount() -> int:
	return int(econ.get("rent_weekly", 60))


## Close the day: overnight wellbeing (drift + tonight's food), rent on
## day 7/14/…, then the next morning.
func end_day() -> void:
	var delta := int(_wb().get("daily_drift", -5))
	if groceries_today == "":
		delta -= int(econ.get("no_food_penalty", 10))
	else:
		delta += int(_grocery_tier(groceries_today).get("wellbeing", 0))
	wellbeing = clampi(wellbeing + delta, 0, 100)
	if rent_due_tonight():
		wallet -= rent_amount()
	day += 1
	slots_left = int(econ.get("slots_per_day", 3))
	earned_today = 0
	spent_today = 0
	groceries_today = ""
	_after_change()


# --- Helpers / persistence ---------------------------------------------------

func _wb() -> Dictionary:
	return econ.get("wellbeing", {})


func _grocery_tier(tier_id: String) -> Dictionary:
	for tier in econ.get("groceries", []):
		if tier.get("id", "") == tier_id:
			return tier
	return {}


func _after_change() -> void:
	if autosave:
		save_game()
	changed.emit()


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"version": 1,
		"wallet": wallet, "savings": savings, "day": day,
		"slots_left": slots_left, "earned_today": earned_today,
		"spent_today": spent_today, "groceries_today": groceries_today,
		"wellbeing": wellbeing, "dream_id": dream_id, "dream_saved": dream_saved,
	}))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	wallet = int(parsed.get("wallet", 50))
	savings = int(parsed.get("savings", 0))
	day = int(parsed.get("day", 1))
	slots_left = int(parsed.get("slots_left", 3))
	earned_today = int(parsed.get("earned_today", 0))
	spent_today = int(parsed.get("spent_today", 0))
	groceries_today = str(parsed.get("groceries_today", ""))
	wellbeing = int(parsed.get("wellbeing", 70))
	dream_id = str(parsed.get("dream_id", ""))
	dream_saved = int(parsed.get("dream_saved", 0))
	changed.emit()
	return true
