extends SceneTree
## Headless smoke test for GameState economy math.
## Run: godot --headless --path . -s res://tests/test_game_state.gd

var failures := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		failures += 1
		push_error("FAIL: " + what)
	else:
		print("ok: " + what)


func _init() -> void:
	var gs: Node = load("res://scripts/game_state.gd").new()
	gs.autosave = false
	gs.load_economy()
	gs.load_events()
	gs.init_new()

	check(gs.wallet == 50, "starter wallet €50")
	check(gs.slots_left == 3, "3 slots per day")
	check(gs.wellbeing == 70, "wellbeing starts at 70")
	check(gs.dream_id == "", "no dream chosen yet")

	var r: Dictionary = gs.work_shift()
	check(r.get("amount", 0) == 28, "shift pays €24+€4")
	check(gs.wallet == 78 and gs.slots_left == 2, "wallet 78, 2 slots after shift")

	var g: Dictionary = gs.buy_groceries("normal")
	check(g.get("cost", 0) == 30, "normal groceries €30")
	check(gs.wallet == 48 and gs.slots_left == 1, "wallet 48, 1 slot")
	check(gs.buy_groceries("cheap").is_empty(), "second groceries blocked")

	check(gs.rest(), "rest consumes last slot")
	check(gs.wellbeing == 85, "rest +15 wellbeing")
	check(gs.slots_left == 0, "0 slots at dusk")
	check(gs.work_shift().is_empty(), "no shift with 0 slots")

	check(not gs.rent_due_tonight(), "no rent on day 1")
	gs.end_day()
	check(gs.day == 2 and gs.slots_left == 3, "day 2 fresh slots")
	check(gs.earned_today == 0 and gs.groceries_today == "", "day counters reset")
	check(gs.wellbeing == 87, "overnight: wear -10, good sleep +12")

	# Fast-forward to day 7, eating normally each night (+2/night, capped).
	while gs.day < 7:
		gs.groceries_today = "normal"
		gs.end_day()
	check(gs.wellbeing == 97, "fed nights sustain you (87 + 5×2)")
	check(gs.rent_due_tonight(), "rent due day 7")
	var before: int = gs.wallet
	gs.end_day()
	check(gs.wallet == before - 60, "rent €60 charged")
	check(gs.day == 8, "day 8 after payday night")
	check(gs.wellbeing == 72, "hungry payday night: 97 - 25 (wear -10, hungry -15)")

	# Rent pushed the wallet negative (48 - 60): allowed by design (debt path).
	check(gs.wallet == -12, "wallet may go negative from rent")

	# Pay tiers (spec §9 v1.1): exhausted 80%, tired 90%, fine 100%, thriving +€4.
	gs.wellbeing = 0
	var tier_r: Dictionary = gs.work_shift()
	check(str(tier_r.get("tier", "")) == "exhausted", "wellbeing 0 -> exhausted")
	check(tier_r.get("amount", 0) == 22, "exhausted shift pays €22 (80%)")
	gs.wellbeing = 45
	check(gs.shift_pay_preview().get("amount", 0) == 25, "tired preview €25 (90%)")
	check(str(gs.pay_tier().get("label", "")) == "tired", "45 -> tired tier")
	gs.wellbeing = 70
	check(gs.shift_pay_preview().get("amount", 0) == 28, "fine preview €28 (100%)")
	gs.wellbeing = 85
	check(gs.shift_pay_preview().get("amount", 0) == 32, "thriving preview €32 (+€4 tip)")
	gs.wellbeing = 0

	# Bank micro-actions (fund the wallet first).
	gs.wallet = 100
	check(gs.deposit(10), "deposit €10")
	check(gs.savings == 10, "savings 10")
	check(not gs.withdraw(50), "over-withdraw blocked")
	check(gs.withdraw(10), "withdraw €10")

	# Insufficient funds.
	gs.wallet = 5
	check(gs.buy_groceries("cheap").is_empty(), "groceries blocked when broke")

	# The dream: select, fund in steps, complete.
	check(not gs.select_dream("nonsense"), "unknown dream rejected")
	check(gs.select_dream("puppy"), "dream selected")
	check(not gs.select_dream("ocean"), "dream cannot be swapped")
	check(gs.dream_cost() == 450, "puppy costs €450")
	gs.wallet = 460
	var f1: Dictionary = gs.fund_dream()
	check(f1.get("added", 0) == 25, "dream funded €25")
	check(gs.wallet == 435 and gs.dream_saved == 25, "wallet/dream ledgers move")
	var completed := false
	for i in 40:
		var fr: Dictionary = gs.fund_dream()
		if fr.get("completed", false):
			completed = true
			break
	check(completed, "dream completes")
	check(gs.dream_saved == 450 and gs.wallet == 10, "exact funding, €10 left")
	check(gs.fund_dream().is_empty(), "no funding past completion")
	check(gs.dream_progress() == 1.0, "progress 100%")

	# Forced Rest Day (spec §9): two days ended at 0 -> mentor floor.
	gs.zero_days = 0  # isolate from the day-7 zero-day above
	gs.wellbeing = 0
	gs.groceries_today = ""
	gs.end_day()
	check(gs.zero_days == 1 and not gs.forced_rest_today, "first empty day counted")
	gs.end_day()
	check(gs.forced_rest_today, "second empty day -> forced rest")
	check(gs.slots_left == 0, "rest day has no slots")
	check(gs.wellbeing == 40, "caring recovery +40")
	check(gs.zero_days == 0, "counter reset")
	gs.groceries_today = "normal"
	gs.end_day()
	check(not gs.forced_rest_today, "normal day after rest")
	check(gs.slots_left == 3, "slots back")

	# Ledger: every wallet movement is recorded and explained.
	check(gs.ledger.size() > 0, "ledger has entries")
	var rent_logged := false
	var shift_logged := false
	for e in gs.ledger:
		if e.get("t") == "Rent" and e.get("a") == -60:
			rent_logged = true
		if e.get("t") == "Courier shift":
			shift_logged = true
	check(rent_logged, "rent -60 explained in ledger")
	check(shift_logged, "shifts appear in ledger")
	for i in 60:
		gs._log("test", 1)
	check(gs.ledger.size() == 40, "ledger capped at 40")

	# Evening events: day-1 kindness, deferred consequences, choice effects.
	gs.init_new()
	gs.prepare_tonight()
	check(gs.tonight_event_id == "found_coin", "night one is the scripted kindness")
	gs.prepare_tonight()
	check(gs.tonight_event_id == "found_coin", "prepare is idempotent")
	var w0: int = gs.wallet
	var ev_r: Dictionary = gs.resolve_event_choice("take")
	check(ev_r.get("wallet", 0) == 5 and gs.wallet == w0 + 5, "found coin +€5")
	check(gs.tonight_event_id == "", "card resolved and cleared")

	# Deferred follow-up fires on its due evening (chance forced to 1).
	gs.end_day()
	gs.schedule_event("phone_broken", gs.day)
	gs.prepare_tonight()
	check(gs.tonight_event_id == "phone_broken", "deferred card takes the slot")
	gs.wallet = 100
	var pb: Dictionary = gs.resolve_event_choice("replace_now")
	check(pb.get("wallet", 0) == -90 and gs.wallet == 10, "worse repair costs €90")
	var pb_logged := false
	for e in gs.ledger:
		if e.get("t") == "Phone fix (worse)":
			pb_logged = true
	check(pb_logged, "event cost in ledger")

	# Choice with defer chance 1.0 always schedules the follow-up.
	gs.end_day()
	gs.schedule_event("phone_cracks", gs.day)
	gs.prepare_tonight()
	var card: Dictionary = gs.tonight_event()
	for c in card.get("choices", []):
		if c.get("id") == "live_with":
			c["defer"]["chance"] = 1.0
	gs.resolve_event_choice("live_with")
	check(gs.pending_events.size() == 1, "ignored problem scheduled to return")
	check(str(gs.pending_events[0].get("id")) == "phone_broken", "…as the worse card")

	# Rest cannot substitute for food: hungry day with a rest slot still sinks.
	gs.init_new()
	gs.wellbeing = 50
	gs.rest()
	check(gs.wellbeing == 65, "rest tops up +15")
	gs.groceries_today = ""
	gs.end_day()
	check(gs.wellbeing == 40, "hungry night -25 wipes the rest gain")

	if failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("%d FAILURES" % failures)
		quit(1)
