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
	check(gs.wellbeing == 90, "rest +20 wellbeing")
	check(gs.slots_left == 0, "0 slots at dusk")
	check(gs.work_shift().is_empty(), "no shift with 0 slots")

	check(not gs.rent_due_tonight(), "no rent on day 1")
	gs.end_day()
	check(gs.day == 2 and gs.slots_left == 3, "day 2 fresh slots")
	check(gs.earned_today == 0 and gs.groceries_today == "", "day counters reset")
	check(gs.wellbeing == 85, "overnight: drift -5, normal food +0")

	# Fast-forward to day 7 (no food those nights: -5 drift -10 hungry).
	while gs.day < 7:
		gs.end_day()
	check(gs.wellbeing == 10, "5 hungry nights: 85 - 75 = 10")
	check(gs.rent_due_tonight(), "rent due day 7")
	var before: int = gs.wallet
	gs.end_day()
	check(gs.wallet == before - 60, "rent €60 charged")
	check(gs.day == 8, "day 8 after payday night")
	check(gs.wellbeing == 0, "wellbeing clamps at 0")

	# Rent pushed the wallet negative (48 - 60): allowed by design (debt path).
	check(gs.wallet == -12, "wallet may go negative from rent")

	# Tired penalty: below threshold the shift pays 80%.
	var tired_r: Dictionary = gs.work_shift()
	check(tired_r.get("tired", false), "shift reports tired")
	check(tired_r.get("amount", 0) == 22, "tired shift pays €22 (80%)")

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

	if failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("%d FAILURES" % failures)
		quit(1)
