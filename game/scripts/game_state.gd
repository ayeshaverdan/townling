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
const EVENTS_PATH := "res://data/events.json"
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
var zero_days: int = 0            # consecutive days ended at wellbeing 0
var forced_rest_today: bool = false  # spec §9: mentor-ordered Rest Day
var ledger: Array = []            # money activity: {d: day, t: label, a: +/-amount}

# Evening event slot (spec §12: fixed slot, surprising content).
var events: Dictionary = {}       # events.json parsed
var tonight_event_id: String = "" # card queued for tonight ("" = quiet night)
var tonight_prepared_day: int = 0 # idempotence guard for prepare_tonight()
var pending_events: Array = []    # deferred consequences: {id, day}
var last_event_id: String = ""    # avoid immediate repeats
var rng := RandomNumberGenerator.new()

const LEDGER_MAX := 40

## Disable to keep unit tests from touching user:// saves.
var autosave: bool = true


func _ready() -> void:
	load_economy()
	load_events()
	rng.randomize()
	if not load_game():
		init_new()


func load_events() -> void:
	var f := FileAccess.open(EVENTS_PATH, FileAccess.READ)
	if f == null:
		push_error("events.json missing")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		events = parsed


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
	zero_days = 0
	forced_rest_today = false
	ledger = []
	tonight_event_id = ""
	tonight_prepared_day = 0
	pending_events = []
	last_event_id = ""
	_after_change()


# --- Slot actions -----------------------------------------------------------

## Work a Courier shift: one slot, instant pay + tip (spec §2 day-1 values).
func work_shift() -> Dictionary:
	if slots_left <= 0:
		return {}
	var preview := shift_pay_preview()
	var amount := int(preview.get("amount", 0))
	slots_left -= 1
	wallet += amount
	earned_today += amount
	_log("Courier shift", amount)
	_after_change()
	return {"amount": amount, "tier": preview.get("tier", "fine"),
		"bonus": preview.get("bonus", 0)}


## What a shift pays RIGHT NOW, given wellbeing (spec §9 pay tiers,
## v1.1 amendment: thriving/fine/tired/exhausted — legible cause and effect).
func shift_pay_preview() -> Dictionary:
	var shift: Dictionary = econ.get("courier_shift", {})
	var base := int(shift.get("pay", 24)) + int(shift.get("tip", 4))
	var tier := pay_tier()
	var amount := int(base * float(tier.get("mult", 1.0))) + int(tier.get("bonus", 0))
	return {"amount": amount, "tier": tier.get("label", "fine"),
		"bonus": int(tier.get("bonus", 0))}


func pay_tier() -> Dictionary:
	for tier in _wb().get("pay_tiers", []):
		if wellbeing >= int(tier.get("min", 0)):
			return tier
	return {"mult": 1.0, "bonus": 0, "label": "fine"}


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
	_log("%s groceries" % tier.get("label", tier_id), -cost)
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
	_log("Into savings jar", -amount)
	_after_change()
	return true


func withdraw(amount: int) -> bool:
	if amount <= 0 or savings < amount:
		return false
	savings -= amount
	wallet += amount
	_log("From savings jar", amount)
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
	_log("Dream fund", -amount)
	_after_change()
	return {"added": amount, "completed": dream_complete()}


func _dream_def(id: String) -> Dictionary:
	for d in econ.get("dreams", []):
		if d.get("id", "") == id:
			return d
	return {}


# --- Evening events (spec §10/§12) --------------------------------------------

## Decide tonight's card at dusk. Idempotent per day. Order of precedence:
## day-1 scripted kindness -> due deferred consequence -> random draw.
func prepare_tonight() -> void:
	if tonight_prepared_day == day:
		return
	tonight_prepared_day = day
	tonight_event_id = ""
	if day == 1:
		tonight_event_id = "found_coin"  # spec §2: night one never punishes
		return
	for i in pending_events.size():
		if int(pending_events[i].get("day", 0)) <= day:
			tonight_event_id = str(pending_events[i].get("id", ""))
			pending_events.remove_at(i)
			return
	if rng.randf() >= float(events.get("nightly_chance", 0.4)):
		return
	var want_shock := rng.randf() < float(events.get("negative_share", 0.6))
	var pool: Array = []
	for card in events.get("cards", []):
		if not bool(card.get("pool", true)):
			continue
		if card.get("id", "") == last_event_id:
			continue
		var is_shock: bool = card.get("type", "") == "shock"
		if is_shock == want_shock:
			pool.append(card)
	if pool.is_empty():
		return
	tonight_event_id = str(pool[rng.randi_range(0, pool.size() - 1)].get("id", ""))


func tonight_event() -> Dictionary:
	return _event_def(tonight_event_id)


## Apply a choice of tonight's card: wallet/wellbeing deltas, ledger entry,
## and possibly a deferred follow-up ("ignored problems return worse").
func resolve_event_choice(choice_id: String) -> Dictionary:
	var card := tonight_event()
	if card.is_empty():
		return {}
	for choice in card.get("choices", []):
		if choice.get("id", "") != choice_id:
			continue
		var dw := int(choice.get("wallet", 0))
		var dwb := int(choice.get("wellbeing", 0))
		wallet += dw
		if dw > 0:
			earned_today += dw
		elif dw < 0:
			spent_today += -dw
		wellbeing = clampi(wellbeing + dwb, 0, 100)
		if dw != 0:
			_log(str(choice.get("log", card.get("title", "Event"))), dw)
		var deferred := false
		if choice.has("defer"):
			var df: Dictionary = choice["defer"]
			if rng.randf() < float(df.get("chance", 0.0)):
				schedule_event(str(df.get("id", "")),
					day + rng.randi_range(int(df.get("min_days", 2)), int(df.get("max_days", 4))))
				deferred = true
		last_event_id = tonight_event_id
		tonight_event_id = ""
		_after_change()
		return {"wallet": dw, "wellbeing": dwb, "deferred": deferred}
	return {}


func schedule_event(id: String, on_day: int) -> void:
	pending_events.append({"id": id, "day": on_day})


func _event_def(id: String) -> Dictionary:
	if id == "":
		return {}
	for card in events.get("cards", []):
		if card.get("id", "") == id:
			return card
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
	# Sleep quality (spec §9 v1.2): the day wears you down; a night's sleep
	# restores you only as well as you ate. Hungry nights make things worse —
	# rest slots can top you up, but they can never replace dinner.
	var delta := int(_wb().get("day_wear", -10))
	if groceries_today == "":
		delta += int(_wb().get("hungry_night", -15))
	else:
		delta += int(_grocery_tier(groceries_today).get("sleep", 12))
	wellbeing = clampi(wellbeing + delta, 0, 100)
	if rent_due_tonight():
		wallet -= rent_amount()
		_log("Rent", -rent_amount())
	day += 1
	slots_left = int(econ.get("slots_per_day", 3))
	# Spec §9 caring floor: two straight days ended empty -> the mentor
	# orders a Rest Day. The cost is a whole day of earnings, not a bill.
	var fr: Dictionary = econ.get("forced_rest", {})
	if wellbeing == 0:
		zero_days += 1
	else:
		zero_days = 0
	forced_rest_today = zero_days >= int(fr.get("after_zero_days", 2))
	if forced_rest_today:
		slots_left = 0
		wellbeing = clampi(wellbeing + int(fr.get("recovery", 40)), 0, 100)
		zero_days = 0
	earned_today = 0
	spent_today = 0
	groceries_today = ""
	_after_change()


# --- Helpers / persistence ---------------------------------------------------

func _log(label: String, amount: int) -> void:
	ledger.append({"d": day, "t": label, "a": amount})
	while ledger.size() > LEDGER_MAX:
		ledger.pop_front()


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
		"zero_days": zero_days, "forced_rest_today": forced_rest_today,
		"ledger": ledger, "tonight_event_id": tonight_event_id,
		"tonight_prepared_day": tonight_prepared_day,
		"pending_events": pending_events, "last_event_id": last_event_id,
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
	zero_days = int(parsed.get("zero_days", 0))
	forced_rest_today = bool(parsed.get("forced_rest_today", false))
	ledger = parsed.get("ledger", [])
	tonight_event_id = str(parsed.get("tonight_event_id", ""))
	tonight_prepared_day = int(parsed.get("tonight_prepared_day", 0))
	pending_events = parsed.get("pending_events", [])
	last_event_id = str(parsed.get("last_event_id", ""))
	changed.emit()
	return true
