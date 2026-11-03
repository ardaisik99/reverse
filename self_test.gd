extends SceneTree

const P = preload("res://puzzle.gd")
var failures := 0
var had_save := false
var saved_file := ""

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	had_save = FileAccess.file_exists("user://reverse_save_v1.json")
	if had_save:
		saved_file = FileAccess.get_file_as_string("user://reverse_save_v1.json")
	check(P.evaluate([2, 3, 4], [0, 2]) == [20, 1], "LTR example")
	check(P.evaluate([2, 3, 4], [0, 2], true) == [14, 1], "RTL must reverse operator order")
	check(P.evaluate([8, 4, 2], [3, 3]) == [1, 1], "division LTR")
	check(P.evaluate([8, 4, 2], [3, 3], true) == [1, 16], "division RTL exact rational")
	check(P.evaluate([5, 2, 3], [1, 2]) == [9, 1], "no multiplication precedence")
	check(P.evaluate([5, 2, 3], [1, 2], true) == [1, 1], "subtraction operand direction")
	check(P.evaluate([3, 0], [3]).is_empty(), "division by zero")
	check(P.rational(-4, -6) == [2, 3], "reduced rational sign")
	for seed_value in range(40):
		for current in range(1, 73):
			var puzzle: Dictionary = P.generate(current, seed_value * 1557 + current)
			check(P.solved(puzzle.solution, puzzle.solution_ops, puzzle), "generated solution %d seed %d" % [current, seed_value])
			check(not P.solved(puzzle.initial, puzzle.initial_ops, puzzle), "initial must be unsolved %d seed %d" % [current, seed_value])
			check(puzzle.solution.size() == 3 + (current - 1) / 18, "progressive length")
			var source: Array = puzzle.solution.duplicate()
			var initial: Array = puzzle.initial.duplicate()
			source.sort()
			initial.sort()
			check(source == initial, "number multiset preserved")
			check(puzzle == P.generate(current, seed_value * 1557 + current), "deterministic generation")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	check(game.screen == "home", "home boots")
	game.save_data.motion = false
	game._start("campaign", 1)
	await process_frame
	game.op_buttons[0].grab_focus()
	game._game_help()
	await process_frame
	check(not game.op_buttons[0].has_focus(), "modal removes background focus")
	check(game.overlay.is_ancestor_of(root.gui_get_focus_owner()), "modal receives keyboard focus")
	var before_ops: Array = game.operators.duplicate()
	game._tap_op(0)
	game._tap_number(0)
	game._undo()
	game._reset()
	game._hint()
	check(game.moves == 0 and game.operators == before_ops and game.selected == -1, "modal blocks every gameplay action")
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.physical_keycode = KEY_ENTER
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame
	check(game.moves == 0 and game.operators == before_ops, "Enter cannot operate game while modal is open")
	check(not is_instance_valid(game.overlay), "Enter activates modal action")
	for current in [1, 19, 37, 55, 72]:
		game._start("campaign", current)
		await process_frame
		await process_frame
		check(game.body.get_combined_minimum_size().x <= game.size.x, "no horizontal overflow at level %d" % current)
		var guard := 0
		while not game.completed and guard < 20:
			game._hint()
			guard += 1
		check(game.screen == "result", "hints lead to valid completion level %d" % current)
		var frozen: float = game._elapsed()
		await process_frame
		check(game._elapsed() == frozen, "completed time frozen")
	game._start("daily", 31)
	var daily_puzzle: Dictionary = game.puzzle.duplicate(true)
	game._start("daily", 31)
	check(game.puzzle == daily_puzzle, "same date same daily puzzle")
	game._start_blitz()
	game.blitz_started -= 61000
	game._tap_op(0)
	check(game.screen == "blitz_result", "blitz expires before late input")
	game.duel_seed = 12345
	game.duel_round = 1
	game.duel_turn = 0
	game.duel_scores = [0, 0]
	game._start("duel", 6)
	var first_puzzle: Dictionary = game.puzzle.duplicate(true)
	game.numbers = game.puzzle.solution.duplicate()
	game.operators = game.puzzle.solution_ops.duplicate()
	game._check_win()
	check(game.screen == "handoff" and game.duel_turn == 1, "duel private handoff")
	game._start("duel", 6)
	check(game.puzzle == first_puzzle, "duel equal puzzle")
	game.numbers = game.puzzle.solution.duplicate()
	game.operators = game.puzzle.solution_ops.duplicate()
	game._check_win()
	check(game.screen == "duel_result", "duel round result")
	game._show_home()
	game._levels()
	await process_frame
	check(game.screen == "levels", "level selection")
	game._show_home()
	game._settings()
	game._close_modal()
	game._tutorial()
	game._close_modal()
	game.queue_free()
	await process_frame
	if had_save:
		var save_file := FileAccess.open("user://reverse_save_v1.json", FileAccess.WRITE)
		if save_file != null:
			save_file.store_string(saved_file)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://reverse_save_v1.json"))
	print("REVERSE: 2880 generated puzzles, exact directional arithmetic, UI modes and completion tests; failures=", failures)
	quit(0 if failures == 0 else 1)
