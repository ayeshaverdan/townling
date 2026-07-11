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
	_after_change()


# --- Slot actions -----------------------------------------------------------

## Work a Courier shift: one slot, instant pay + tip (spec §2 day-1 values).
func work_shift() -> Dictionary:
	if slots_left <= 0:
		return {}
	var shift: Dictionary = econ.get("courier_shift", {})
	var amount := int(shift.get("pay", 24)) + int(shift.get("tip", 4))
	slots_left -= 1
	wallet += amount
	earned_today += amount
	_after_change()
	return {"amount": amount}


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


## Rest: one slot. (Refills wellbeing once the meter exists — spec §9.)
func rest() -> bool:
	if slots_left <= 0:
		return false
	slots_left -= 1
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


# --- Day cycle ---------------------------------------------------------------

## Whether tonight's summary will include rent (every 7th day).
func rent_due_tonight() -> bool:
	return day % 7 == 0


func rent_amount() -> int:
	return int(econ.get("rent_weekly", 60))


## Close the day: charge rent on day 7/14/…, then start the next morning.
func end_day() -> void:
	if rent_due_tonight():
		wallet -= rent_amount()
	day += 1
	slots_left = int(econ.get("slots_per_day", 3))
	earned_today = 0
	spent_today = 0
	groceries_today = ""
	_after_change()


# --- Helpers / persistence ---------------------------------------------------

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
	changed.emit()
	return true
