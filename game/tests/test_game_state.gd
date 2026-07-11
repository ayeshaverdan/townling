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

	var r: Dictionary = gs.work_shift()
	check(r.get("amount", 0) == 28, "shift pays €24+€4")
	check(gs.wallet == 78 and gs.slots_left == 2, "wallet 78, 2 slots after shift")

	var g: Dictionary = gs.buy_groceries("normal")
	check(g.get("cost", 0) == 30, "normal groceries €30")
	check(gs.wallet == 48 and gs.slots_left == 1, "wallet 48, 1 slot")
	check(gs.buy_groceries("cheap").is_empty(), "second groceries blocked")

	check(gs.rest(), "rest consumes last slot")
	check(gs.slots_left == 0, "0 slots at dusk")
	check(gs.work_shift().is_empty(), "no shift with 0 slots")

	check(not gs.rent_due_tonight(), "no rent on day 1")
	gs.end_day()
	check(gs.day == 2 and gs.slots_left == 3, "day 2 fresh slots")
	check(gs.earned_today == 0 and gs.groceries_today == "", "day counters reset")

	# Fast-forward to day 7 and check rent.
	while gs.day < 7:
		gs.end_day()
	check(gs.rent_due_tonight(), "rent due day 7")
	var before: int = gs.wallet
	gs.end_day()
	check(gs.wallet == before - 60, "rent €60 charged")
	check(gs.day == 8, "day 8 after payday night")

	# Rent pushed the wallet negative (48 - 60): allowed by design (debt path).
	check(gs.wallet == -12, "wallet may go negative from rent")

	# Bank micro-actions (fund the wallet first).
	gs.wallet = 100
	check(gs.deposit(10), "deposit €10")
	check(gs.savings == 10, "savings 10")
	check(not gs.withdraw(50), "over-withdraw blocked")
	check(gs.withdraw(10), "withdraw €10")

	# Insufficient funds.
	gs.wallet = 5
	check(gs.buy_groceries("cheap").is_empty(), "groceries blocked when broke")

	if failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("%d FAILURES" % failures)
		quit(1)
