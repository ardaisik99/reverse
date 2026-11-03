extends Control

const P = preload("res://puzzle.gd")
const INK = Color("243449")
const CREAM = Color("f6f0df")
const PAPER = Color("fffaf0")
const GOLD = Color("e9ba61")
const CORAL = Color("e67d65")
const SAGE = Color("83a98b")
const MUTED = Color("78828a")
const SAVE_PATH = "user://reverse_save_v1.json"

var screen := "home"
var scroll: ScrollContainer
var center: CenterContainer
var body: VBoxContainer
var overlay: Control
var audio_player: AudioStreamPlayer
var tones: Dictionary = {}
var save_data: Dictionary = {"stars": {}, "unlocked": 1, "sound": true, "motion": true, "blitz_best": 0, "daily": {}}
var mode := "campaign"
var level := 1
var puzzle: Dictionary = {}
var numbers: Array = []
var operators: Array = []
var history: Array = []
var selected := -1
var moves := 0
var hints := 0
var started := 0
var paused_at := 0
var pause_total := 0
var completed := false
var finished_elapsed := 0.0
var daily_date := ""
var clock_label: Label
var move_label: Label
var feedback: Label
var target_labels: Array = []
var result_labels: Array = []
var number_buttons: Array = []
var op_buttons: Array = []
var inline_ops: Array = []
var blitz_started := 0
var blitz_score := 0
var blitz_count := 0
var blitz_chain := 0
var blitz_seed := 0
var duel_round := 1
var duel_turn := 0
var duel_scores: Array = [0, 0]
var duel_times: Array = [0.0, 0.0]
var duel_seed := 0
var share_status: Label

func _ready() -> void:
	_load_save()
	var theme_new := Theme.new()
	theme_new.default_font_size = 20
	theme = theme_new
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	resized.connect(_layout)
	_show_home()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), CREAM)
	draw_circle(Vector2(size.x + 35, 85), 155, Color("eedfc4"))
	draw_circle(Vector2(-60, size.y - 70), 160, Color("e5e6d4"))
	for row in range(7):
		for col in range(3):
			draw_circle(Vector2(size.x - 42 + col * 15, size.y - 170 + row * 15), 2, Color("d4cfbd"))

func _layout() -> void:
	queue_redraw()
	if is_instance_valid(center):
		center.custom_minimum_size = size
	if is_instance_valid(body):
		body.custom_minimum_size.x = minf(500, size.x - 36)

func _screen(next_screen: String) -> void:
	screen = next_screen
	if is_instance_valid(scroll):
		remove_child(scroll)
		scroll.queue_free()
	if is_instance_valid(overlay):
		overlay.queue_free()
		overlay = null
	scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	center.add_child(body)
	_layout()
	_space(body, 20)
	if bool(save_data.motion):
		body.modulate.a = 0.0
		create_tween().tween_property(body, "modulate:a", 1.0, 0.18)

func _box(color: Color, radius: int = 22, shadow: int = 5) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color(0.14, 0.20, 0.28, 0.12)
	style.shadow_size = 0
	style.shadow_offset = Vector2(0, shadow)
	# A bottom border makes tactile tiles without expensive textures.
	style.border_width_bottom = shadow
	style.border_color = color.darkened(0.16)
	return style

func _label(text_value: String, font_size: int = 20, color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _text(parent: Node, text_value: String, font_size: int = 20, color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := _label(text_value, font_size, color, align)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _space(parent: Node, height: int = 10) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	parent.add_child(spacer)

func _button(parent: Node, title: String, action: Callable, color: Color = PAPER, height: int = 60, font_size: int = 20) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = height
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", _box(color, 18))
	button.add_theme_stylebox_override("hover", _box(color.lightened(0.07), 18))
	button.add_theme_stylebox_override("pressed", _box(color.darkened(0.06), 18, 1))
	var focus := _box(color, 18)
	focus.border_width_left = 3
	focus.border_width_right = 3
	focus.border_width_top = 3
	focus.border_color = INK
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", CREAM if color == INK else INK)
	button.add_theme_color_override("font_hover_color", CREAM if color == INK else INK)
	button.add_theme_color_override("font_pressed_color", CREAM if color == INK else INK)
	button.add_theme_color_override("font_focus_color", CREAM if color == INK else INK)
	button.add_theme_font_size_override("font_size", font_size)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(func():
		_tone(480)
		action.call()
	)
	parent.add_child(button)
	if is_instance_valid(overlay) and overlay.is_ancestor_of(button) and not bool(overlay.get_meta("focus_claimed", false)):
		button.grab_focus()
		overlay.set_meta("focus_claimed", true)
	return button

func _panel(parent: Node, color: Color = PAPER) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(color))
	parent.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 10)
	panel.add_child(contents)
	return contents

func _row(parent: Node, separation: int = 10) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", separation)
	parent.add_child(row)
	return row

func _show_home() -> void:
	completed = true
	_screen("home")
	var header := _row(body)
	var mini_title := _label("KÜÇÜK İŞLEMLER, BÜYÜK FİKİRLER", 13, MUTED)
	mini_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(mini_title)
	_button(header, "☰", _settings, PAPER, 42, 22).size_flags_horizontal = Control.SIZE_SHRINK_END
	_space(body, 2)
	var brand := _label("REVERSE", 66, INK, HORIZONTAL_ALIGNMENT_CENTER)
	brand.add_theme_constant_override("outline_size", 0)
	body.add_child(brand)
	_text(body, "İki yön. Tek çözüm.", 22, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var art := _panel(body, INK)
	_text(art, "→   20                  14   ←", 24, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var tiles := _row(art, 8)
	tiles.alignment = BoxContainer.ALIGNMENT_CENTER
	for item in [["2", GOLD], ["+", INK], ["3", CORAL], ["×", INK], ["4", SAGE]]:
		var tile := _label(item[0], 32, CREAM if item[1] == INK else INK, HORIZONTAL_ALIGNMENT_CENTER)
		tile.custom_minimum_size = Vector2(66 if item[1] != INK else 34, 68)
		if item[1] != INK:
			tile.add_theme_stylebox_override("normal", _box(item[1], 15, 4))
		tiles.add_child(tile)
	_text(art, "Sayıları değiştir, iki hedefi birden bul.", 15, Color("d0d6d9"), HORIZONTAL_ALIGNMENT_CENTER)
	var progress := _row(body)
	var total_stars := 0
	for value in save_data.stars.values():
		total_stars += int(value)
	var star_label := _label("★  %d / 216" % total_stars, 18, INK)
	star_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.add_child(star_label)
	progress.add_child(_label("72 BÖLÜMLÜK YOLCULUK", 13, MUTED))
	_button(body, "DEVAM ET     →     BÖLÜM %02d" % int(save_data.unlocked), func(): _start("campaign", int(save_data.unlocked)), GOLD, 74, 22)
	var modes := _row(body)
	_button(modes, "GÜNLÜK\nHerkes için aynı", func(): _start("daily", 31), SAGE, 86, 18)
	_button(modes, "BLITZ\n60 saniye, tam gaz", _start_blitz, CORAL, 86, 18)
	_button(body, "1v1 DÜELLO     ·     AYNI CİHAZDA", _duel_intro, INK, 62, 18)
	var bottom := _row(body)
	_button(bottom, "Bölümler", _levels, PAPER, 52, 17)
	_button(bottom, "Nasıl oynanır?", _tutorial, PAPER, 52, 17)
	_text(body, "İşlem önceliği yok. Her yönde sırayla hesapla.", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_space(body, 22)

func _daily_key() -> String:
	return Time.get_date_string_from_system(true)

func _daily_seed() -> int:
	return int(_daily_key().replace("-", "")) * 103 + 7

func _start(next_mode: String, next_level: int) -> void:
	mode = next_mode
	level = clampi(next_level, 1, 72)
	var seed_value := -1
	if mode == "daily":
		daily_date = _daily_key()
		seed_value = _daily_seed()
	elif mode == "blitz":
		seed_value = blitz_seed + blitz_count * 1523
	elif mode == "duel":
		seed_value = duel_seed + duel_round * 1777
	puzzle = P.generate(level, seed_value)
	numbers = puzzle.initial.duplicate()
	operators = puzzle.initial_ops.duplicate()
	history.clear()
	selected = -1
	moves = 0
	hints = 0
	completed = false
	finished_elapsed = 0.0
	started = Time.get_ticks_msec()
	pause_total = 0
	paused_at = 0
	_build_game()

func _start_blitz() -> void:
	blitz_started = Time.get_ticks_msec()
	blitz_score = 0
	blitz_count = 0
	blitz_chain = 0
	blitz_seed = int(Time.get_unix_time_from_system()) % 2000000000
	_start("blitz", 1)

func _mode_title() -> String:
	match mode:
		"daily": return "GÜNLÜK  ·  " + daily_date
		"blitz": return "BLITZ  ·  %d PUAN  ·  ×%d" % [blitz_score, _multiplier()]
		"duel": return "RAUNT %d/3  ·  OYUNCU %d" % [duel_round, duel_turn + 1]
	return "BÖLÜM %02d / 72" % level

func _build_game() -> void:
	_screen("game")
	var head := _row(body)
	_button(head, "‹", _exit_game, PAPER, 46, 28).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var name_label := _label("REVERSE", 27, INK, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	_button(head, "?", _game_help, PAPER, 46, 22).size_flags_horizontal = Control.SIZE_SHRINK_END
	_text(body, _mode_title(), 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var stats := _row(body)
	move_label = _label("0 HAMLE", 18, INK)
	move_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(move_label)
	clock_label = _label("01:00" if mode == "blitz" else "00:00", 18, INK, HORIZONTAL_ALIGNMENT_RIGHT)
	stats.add_child(clock_label)
	var targets := _row(body, 12)
	target_labels.clear()
	result_labels.clear()
	for i in range(2):
		var target_panel := PanelContainer.new()
		target_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target_panel.add_theme_stylebox_override("panel", _box(SAGE if i == 0 else CORAL, 22))
		targets.add_child(target_panel)
		var target_content := VBoxContainer.new()
		target_content.add_theme_constant_override("separation", 4)
		target_panel.add_child(target_content)
		_text(target_content, "SOLDAN SAĞA  →" if i == 0 else "←  SAĞDAN SOLA", 13, INK, HORIZONTAL_ALIGNMENT_CENTER)
		var value := _text(target_content, P.format_value(puzzle.left if i == 0 else puzzle.right), 40, INK, HORIZONTAL_ALIGNMENT_CENTER)
		target_labels.append(value)
		var live := _text(target_content, "", 15, INK, HORIZONTAL_ALIGNMENT_CENTER)
		result_labels.append(live)
	_space(body, 6)
	_text(body, "İKİ HEDEFİ DE YAKALA", 16, INK, HORIZONTAL_ALIGNMENT_CENTER)
	var board := _panel(body)
	board.add_theme_constant_override("separation", 18)
	_text(board, "→   soldan sağa hesapla   →", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var equation := _row(board, 3 if numbers.size() > 4 else 7)
	equation.alignment = BoxContainer.ALIGNMENT_CENTER
	number_buttons.clear()
	op_buttons.clear()
	inline_ops.clear()
	var tile_width: int = 48 if numbers.size() >= 5 else (64 if numbers.size() == 4 else 86)
	for i in range(numbers.size()):
		var index: int = i
		var button := _button(equation, str(numbers[i]), func(): _tap_number(index), GOLD if i % 2 == 0 else Color("edd9ac"), 78, 30 if numbers.size() <= 4 else 25)
		button.custom_minimum_size.x = tile_width
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tile_style := _box(GOLD if i % 2 == 0 else Color("edd9ac"), 15)
		tile_style.content_margin_left = 3
		tile_style.content_margin_right = 3
		button.add_theme_stylebox_override("normal", tile_style)
		var hover_style := tile_style.duplicate()
		hover_style.bg_color = GOLD.lightened(0.14)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", hover_style)
		number_buttons.append(button)
		if i < operators.size():
			if numbers.size() >= 5:
				var sign := _label(P.SYMBOLS[operators[i]], 23, INK, HORIZONTAL_ALIGNMENT_CENTER)
				equation.add_child(sign)
				inline_ops.append(sign)
			else:
				var op_button := _button(equation, P.SYMBOLS[operators[i]], func(): _tap_op(index), PAPER, 62, 26)
				op_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				op_button.custom_minimum_size.x = 38
				var op_style := _box(PAPER, 10, 0)
				op_style.content_margin_left = 1
				op_style.content_margin_right = 1
				op_button.add_theme_stylebox_override("normal", op_style)
				op_button.add_theme_stylebox_override("hover", op_style)
				op_button.add_theme_stylebox_override("pressed", op_style)
				op_buttons.append(op_button)
	_text(board, "←   sağdan sola hesapla   ←", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	if numbers.size() >= 5:
		var operator_row := _row(board, 8)
		for i in range(operators.size()):
			var index: int = i
			var op_button := _button(operator_row, "%d. %s" % [i + 1, P.SYMBOLS[operators[i]]], func(): _tap_op(index), Color("e7e7d8"), 50, 19)
			var op_style := _box(Color("e7e7d8"), 12, 3)
			op_style.content_margin_left = 5
			op_style.content_margin_right = 5
			op_button.add_theme_stylebox_override("normal", op_style)
			op_buttons.append(op_button)
	feedback = _text(body, "Yer değiştirmek için iki sayıya dokun.", 17, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	feedback.custom_minimum_size.y = 50
	var helpers := _row(body)
	_button(helpers, "↶  Geri", _undo, PAPER, 58, 17)
	_button(helpers, "↺  Sıfırla", _reset, PAPER, 58, 17)
	var hint_button := _button(helpers, "✦  İpucu", _hint, PAPER, 58, 17)
	if mode == "duel":
		hint_button.disabled = true
		hint_button.tooltip_text = "Düelloda iki oyuncu da ipucusuz oynar."
	var tip := _panel(body, Color("e7e7d8"))
	_text(tip, "ÖNCE YÖNÜ SEÇ", 13, INK)
	_text(tip, "İşlem önceliği yok! Çarpma da toplama da sırayla. İşaretlere dokunarak işlemi değiştir.", 16, INK)
	if mode == "duel":
		_text(body, "Skor  %d : %d  ·  Diğer oyuncu ekrana bakmasın." % duel_scores, 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_space(body, 22)
	_update_board()

func _record() -> void:
	history.append({"numbers": numbers.duplicate(), "operators": operators.duplicate()})
	if history.size() > 200:
		history.pop_front()

func _tap_number(index: int) -> void:
	if completed or is_instance_valid(overlay) or _blitz_expired():
		return
	if selected < 0:
		selected = index
		feedback.text = "%s seçildi. Şimdi başka bir sayıya dokun." % numbers[index]
	elif selected == index:
		selected = -1
		feedback.text = "Yer değiştirmek için iki sayıya dokun."
	else:
		_record()
		var temp: int = int(numbers[selected])
		numbers[selected] = numbers[index]
		numbers[index] = temp
		selected = -1
		moves += 1
		feedback.text = "Sayılar yer değiştirdi. İşaretleri de değiştirebilirsin."
	_update_board()
	_check_win()

func _tap_op(index: int) -> void:
	if completed or is_instance_valid(overlay) or _blitz_expired():
		return
	_record()
	var allowed: Array = puzzle.allowed
	operators[index] = allowed[(allowed.find(operators[index]) + 1) % allowed.size()]
	selected = -1
	moves += 1
	feedback.text = "İşlem değişti. İki yöndeki sonucu takip et."
	_update_board()
	_check_win()

func _update_board() -> void:
	for i in range(number_buttons.size()):
		var button: Button = number_buttons[i]
		button.text = str(numbers[i])
		var style := _box(SAGE if selected == i else (GOLD if i % 2 == 0 else Color("edd9ac")), 15)
		style.content_margin_left = 3
		style.content_margin_right = 3
		if selected == i:
			style.border_width_top = 3
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_color = INK
		button.add_theme_stylebox_override("normal", style)
	for i in range(op_buttons.size()):
		op_buttons[i].text = "%d. %s" % [i + 1, P.SYMBOLS[operators[i]]] if numbers.size() >= 5 else P.SYMBOLS[operators[i]]
	for i in range(inline_ops.size()):
		inline_ops[i].text = P.SYMBOLS[operators[i]]
	for i in range(2):
		var value: Array = P.evaluate(numbers, operators, i == 1)
		var match_target: bool = value == (puzzle.left if i == 0 else puzzle.right)
		result_labels[i].text = ("✓  " if match_target else "Şimdi: ") + P.format_value(value)
		result_labels[i].modulate = Color.WHITE if match_target else Color(1, 1, 1, 0.75)
	move_label.text = "%d HAMLE" % moves

func _undo() -> void:
	if completed or is_instance_valid(overlay) or history.is_empty() or _blitz_expired():
		return
	var previous: Dictionary = history.pop_back()
	numbers = previous.numbers
	operators = previous.operators
	selected = -1
	moves += 1
	feedback.text = "Son değişiklik geri alındı."
	_update_board()

func _reset() -> void:
	if completed or is_instance_valid(overlay) or _blitz_expired():
		return
	_record()
	numbers = puzzle.initial.duplicate()
	operators = puzzle.initial_ops.duplicate()
	selected = -1
	moves += 1
	feedback.text = "Başlangıç dizilimine döndün."
	_update_board()

func _hint() -> void:
	if completed or is_instance_valid(overlay) or mode == "duel" or _blitz_expired():
		return
	_record()
	hints += 1
	moves += 1
	selected = -1
	for i in range(numbers.size()):
		if numbers[i] != puzzle.solution[i]:
			for j in range(i + 1, numbers.size()):
				if numbers[j] == puzzle.solution[i]:
					var temp: int = int(numbers[i])
					numbers[i] = numbers[j]
					numbers[j] = temp
					feedback.text = "Bir sayıyı doğru konuma taşıdık."
					_update_board()
					_check_win()
					return
	for i in range(operators.size()):
		if operators[i] != puzzle.solution_ops[i]:
			operators[i] = puzzle.solution_ops[i]
			feedback.text = "Bir işlem işaretini düzelttik."
			_update_board()
			_check_win()
			return

func _elapsed() -> float:
	if completed:
		return finished_elapsed
	var now: int = paused_at if paused_at > 0 else Time.get_ticks_msec()
	return maxf(0, float(now - started - pause_total) / 1000.0)

func _time_string(seconds: float) -> String:
	var whole: int = maxi(0, int(ceil(seconds)))
	return "%02d:%02d" % [whole / 60, whole % 60]

func _process(_delta: float) -> void:
	if screen != "game" or completed:
		return
	if mode == "blitz":
		var remaining: float = 60.0 - float(Time.get_ticks_msec() - blitz_started) / 1000.0
		clock_label.text = _time_string(remaining)
		clock_label.add_theme_color_override("font_color", CORAL if remaining <= 10 else INK)
		if remaining <= 0:
			_blitz_end()
	else:
		clock_label.text = _time_string(_elapsed())

func _blitz_expired() -> bool:
	if mode == "blitz" and Time.get_ticks_msec() - blitz_started >= 60000:
		_blitz_end()
		return true
	return false

func _check_win() -> void:
	if completed or not P.solved(numbers, operators, puzzle):
		return
	finished_elapsed = _elapsed()
	completed = true
	_tone(750)
	if mode == "blitz":
		blitz_count += 1
		blitz_chain = blitz_chain + 1 if hints == 0 else 0
		blitz_score += 100 * _multiplier()
		_start("blitz", mini(54, 1 + (blitz_count / 3) * 6))
		feedback.text = "+%d puan! %d bulmaca çözdün." % [100 * _multiplier(), blitz_count]
		return
	if mode == "duel":
		_duel_solved()
		return
	var elapsed: float = _elapsed()
	var stars: int = 3 if hints == 0 and moves <= numbers.size() * 3 and elapsed <= 90 else (2 if hints <= 1 and moves <= numbers.size() * 6 else 1)
	if mode == "campaign":
		var key := str(level)
		save_data.stars[key] = maxi(int(save_data.stars.get(key, 0)), stars)
		save_data.unlocked = maxi(int(save_data.unlocked), mini(72, level + 1))
	else:
		var key := daily_date
		var old: Dictionary = save_data.daily.get(key, {})
		if old.is_empty() or moves < int(old.moves) or (moves == int(old.moves) and elapsed < float(old.time)):
			save_data.daily[key] = {"moves": moves, "time": elapsed, "hints": hints}
	_save()
	_show_result(stars, elapsed)

func _multiplier() -> int:
	return mini(5, 1 + blitz_chain / 3)

func _show_result(stars: int, elapsed: float) -> void:
	_screen("result")
	_text(body, "İKİ YÖN DE TAM İSABET", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_text(body, "Harika çözüm!", 45, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(body, "★".repeat(stars) + "☆".repeat(3 - stars), 60, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var summary := _panel(body)
	_text(summary, "%d hamle   ·   %s   ·   %d ipucu" % [moves, _time_string(elapsed), hints], 21, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(summary, _equation_text(), 27, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(summary, "→ %s          %s ←" % [P.format_value(puzzle.left), P.format_value(puzzle.right)], 23, SAGE, HORIZONTAL_ALIGNMENT_CENTER)
	_text(body, "3 yıldız: ipucusuz, 90 saniye içinde ve en fazla %d hamle.\n2 yıldız: en fazla 1 ipucu ve %d hamle." % [numbers.size() * 3, numbers.size() * 6], 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	if mode == "campaign" and level < 72:
		_button(body, "SONRAKİ BÖLÜM  →", func(): _start("campaign", level + 1), GOLD, 72, 22)
	elif mode == "campaign":
		_text(body, "72 bölüm tamamlandı. REVERSE ustasısın!", 23, INK, HORIZONTAL_ALIGNMENT_CENTER)
		_button(body, "BÖLÜMLERE GİT", _levels, GOLD)
	else:
		var best: Dictionary = save_data.daily.get(daily_date, {})
		_text(body, "Günün en iyi sonucun: %d hamle · %s" % [int(best.get("moves", moves)), _time_string(float(best.get("time", elapsed)))], 17, INK, HORIZONTAL_ALIGNMENT_CENTER)
		_button(body, "SONUCUMU PAYLAŞ", _share, SAGE)
		share_status = _text(body, "Günlük bulmaca UTC 00.00'da yenilenir.", 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var actions := _row(body)
	_button(actions, "Tekrar oyna", func(): _start(mode, level), PAPER)
	_button(actions, "Ana menü", _show_home, PAPER)
	_space(body, 24)

func _equation_text() -> String:
	var parts: Array[String] = []
	for i in range(numbers.size()):
		parts.append(str(numbers[i]))
		if i < operators.size():
			parts.append(P.SYMBOLS[operators[i]])
	return " ".join(parts)

func _share() -> void:
	var text_value := "REVERSE · %s\nİki yön, tek çözüm!\n%d hamle · %s · %d ipucu\n→ %s | %s ←" % [daily_date, moves, _time_string(_elapsed()), hints, P.format_value(puzzle.left), P.format_value(puzzle.right)]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("navigator.clipboard.writeText(" + JSON.stringify(text_value) + ")", true)
		share_status.text = "Sonuç panoya kopyalandı."
	else:
		DisplayServer.clipboard_set(text_value)
		share_status.text = "Sonuç panoya kopyalandı."

func _blitz_end() -> void:
	if completed and screen == "blitz_result":
		return
	completed = true
	save_data.blitz_best = maxi(int(save_data.blitz_best), blitz_score)
	_save()
	_screen("blitz_result")
	_text(body, "SÜRE DOLDU", 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_text(body, "Hızlı düşündün!", 41, INK, HORIZONTAL_ALIGNMENT_CENTER)
	var summary := _panel(body, CORAL)
	_text(summary, str(blitz_score), 82, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(summary, "PUAN  ·  %d BULMACA" % blitz_count, 20, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(body, "Kişisel rekorun: %d puan" % int(save_data.blitz_best), 24, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(body, "İpucusuz her 3 çözüm çarpanı artırır.\nEn yüksek çarpan ×5.", 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_button(body, "YENİDEN BLITZ  →", _start_blitz, GOLD, 72)
	_button(body, "Ana menü", _show_home)

func _modal(title: String, message: String) -> VBoxContainer:
	_set_background_focus(false)
	if is_instance_valid(overlay):
		overlay.queue_free()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.14, 0.20, 0.28, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var modal_center := CenterContainer.new()
	modal_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(modal_center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = minf(460, size.x - 40)
	panel.add_theme_stylebox_override("panel", _box(PAPER, 28))
	modal_center.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 16)
	panel.add_child(contents)
	_text(contents, title, 30, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(contents, message, 18, INK, HORIZONTAL_ALIGNMENT_CENTER)
	return contents

func _set_background_focus(enabled: bool) -> void:
	if not is_instance_valid(scroll):
		return
	for node in scroll.find_children("*", "Button", true, false):
		if not enabled and node.has_focus():
			node.release_focus()
		node.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE

func _close_modal() -> void:
	if is_instance_valid(overlay):
		overlay.queue_free()
		overlay = null
	_set_background_focus(true)
	if paused_at > 0:
		pause_total += Time.get_ticks_msec() - paused_at
		paused_at = 0

func _pause() -> void:
	if mode != "blitz" and mode != "duel" and paused_at == 0:
		paused_at = Time.get_ticks_msec()

func _exit_game() -> void:
	_pause()
	var contents := _modal("Bir mola mı?", "Bu bulmacadaki değişiklikler kaybolacak." + ("\nBlitz süresi işlemeye devam eder." if mode == "blitz" else ""))
	_button(contents, "OYUNA DÖN", _close_modal, GOLD)
	_button(contents, "Ana menüye çık", _show_home)

func _game_help() -> void:
	_pause()
	var contents := _modal("İki yönden düşün", "1. İki sayıya dokunarak yerlerini değiştir.\n2. İşaretlere dokunarak işlemi değiştir.\n3. Her yönde işlemleri sırayla yap.\n4. İki sonuç da renkli hedeflere eşit olsun.\n\n2 + 3 × 4\n→ (2 + 3) × 4 = 20\n← (4 × 3) + 2 = 14" + ("\n\nBlitz saati durmaz!" if mode == "blitz" else ""))
	_button(contents, "ANLADIM", _close_modal, GOLD)

func _tutorial() -> void:
	var contents := _modal("REVERSE nasıl oynanır?", "Aynı dizi, iki farklı yol.\n\n2 + 3 × 4\nSoldan: (2 + 3) × 4 = 20\nSağdan: (4 × 3) + 2 = 14\n\nİşlem önceliği uygulanmaz. Sayıları takas et, işlemleri değiştir. İki hedefi aynı anda bul!\n\nİlerledikçe 4, 5, 6 sayı; çıkarma ve bölme açılır. İpuçları yıldızını etkiler.")
	_button(contents, "İLK BULMACAYI DENE", func(): _start("campaign", 1), GOLD)
	_button(contents, "Menüye dön", _close_modal)

func _settings() -> void:
	var contents := _modal("Oyun ayarları", "İlerleme bu cihazda otomatik saklanır.")
	var sound_button: Button
	sound_button = _button(contents, "Ses: " + ("Açık" if bool(save_data.sound) else "Kapalı"), func():
		save_data.sound = not bool(save_data.sound)
		_save()
		_settings()
	)
	_button(contents, "Hareket: " + ("Açık" if bool(save_data.motion) else "Azaltılmış"), func():
		save_data.motion = not bool(save_data.motion)
		_save()
		_settings()
	)
	_text(contents, "Günlük bulmaca çevrimdışı çalışır. Sonuç karşılaştırması paylaşım metniyle yapılır. Düello aynı cihazda iki kişiliktir.", 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_button(contents, "TAMAM", _close_modal, GOLD)

func _levels() -> void:
	_screen("levels")
	var head := _row(body)
	_button(head, "‹ Geri", _show_home, PAPER, 48, 17).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_text(head, "72 BÖLÜM", 27, INK, HORIZONTAL_ALIGNMENT_CENTER).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text(body, "3 sayıdan 6 sayıya, adım adım ustalaş.", 17, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	for chapter in range(4):
		_text(body, "%02d  /  %d SAYI" % [chapter + 1, chapter + 3], 19, INK)
		var grid := GridContainer.new()
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		body.add_child(grid)
		for k in range(18):
			var current: int = chapter * 18 + k + 1
			var stars: int = int(save_data.stars.get(str(current), 0))
			var unlocked: bool = current <= int(save_data.unlocked)
			var title: String = "%02d\n%s" % [current, "★".repeat(stars) if stars > 0 else ("·" if unlocked else "—")]
			var button := _button(grid, title, func(): _start("campaign", current), GOLD if current == int(save_data.unlocked) else PAPER, 70, 16)
			button.disabled = not unlocked
			button.custom_minimum_size.x = 67
	_space(body, 24)

func _duel_intro() -> void:
	var contents := _modal("Yan yana, kafa kafaya", "AYNI CİHAZDA 1v1 DÜELLO\n\n3 raunt. Her rauntta iki oyuncu aynı bulmacayı sırayla çözer. Daha kısa sürede çözen 1 puan alır. Eşitlikte ikisine de 1 puan.\n\nDiğer oyuncu oynarken ekrana bakma. İpuçları kapalıdır. Hazır olduğunda cihazı sıradaki oyuncuya ver.")
	_button(contents, "DÜELLOYU BAŞLAT", func():
		duel_round = 1
		duel_turn = 0
		duel_scores = [0, 0]
		duel_times = [0.0, 0.0]
		duel_seed = int(Time.get_unix_time_from_system()) % 2000000000
		_duel_handoff()
	, GOLD)
	_button(contents, "Vazgeç", _close_modal)

func _duel_handoff() -> void:
	_screen("handoff")
	_text(body, "RAUNT %d / 3" % duel_round, 17, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_text(body, "OYUNCU %d" % (duel_turn + 1), 50, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(body, "Cihaz şimdi sende.", 27, INK, HORIZONTAL_ALIGNMENT_CENTER)
	var note := _panel(body, SAGE)
	_text(note, "Diğer oyuncu ekrana bakmasın.\nHazır olduğunda süre başlayacak.", 22, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(body, "Skor  %d : %d" % duel_scores, 25, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_button(body, "HAZIRIM  →", func(): _start("duel", 6 + (duel_round - 1) * 14), GOLD, 76)
	_button(body, "Düellodan çık", _show_home)

func _duel_solved() -> void:
	duel_times[duel_turn] = _elapsed()
	if duel_turn == 0:
		duel_turn = 1
		_duel_handoff()
		return
	var equal: bool = absf(float(duel_times[0]) - float(duel_times[1])) < 0.01
	if equal:
		duel_scores[0] += 1
		duel_scores[1] += 1
	elif float(duel_times[0]) < float(duel_times[1]):
		duel_scores[0] += 1
	else:
		duel_scores[1] += 1
	_screen("duel_result")
	_text(body, "RAUNT %d TAMAMLANDI" % duel_round, 17, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var title: String = "Berabere!" if equal else "Oyuncu %d kazandı!" % (1 if float(duel_times[0]) < float(duel_times[1]) else 2)
	_text(body, title, 36, INK, HORIZONTAL_ALIGNMENT_CENTER)
	var stats := _panel(body)
	_text(stats, "%d  :  %d" % duel_scores, 72, INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(stats, "Oyuncu 1: %.2f sn\nOyuncu 2: %.2f sn" % duel_times, 23, INK, HORIZONTAL_ALIGNMENT_CENTER)
	if duel_round < 3:
		_button(body, "SONRAKİ RAUNT  →", func():
			duel_round += 1
			duel_turn = 0
			_duel_handoff()
		, GOLD, 72)
	else:
		var winner: String = "Düello berabere!" if duel_scores[0] == duel_scores[1] else "Düello şampiyonu: Oyuncu %d" % (1 if duel_scores[0] > duel_scores[1] else 2)
		_text(body, winner, 24, INK, HORIZONTAL_ALIGNMENT_CENTER)
		_button(body, "YENİ DÜELLO", _duel_intro, GOLD, 72)
	_button(body, "Ana menü", _show_home)

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in save_data:
			if parsed.has(key) and typeof(parsed[key]) == typeof(save_data[key]):
				save_data[key] = parsed[key]
		# JSON represents integer values as floats.
		if parsed.get("unlocked") is float or parsed.get("unlocked") is int:
			save_data.unlocked = clampi(int(parsed.unlocked), 1, 72)
		if parsed.get("blitz_best") is float or parsed.get("blitz_best") is int:
			save_data.blitz_best = maxi(0, int(parsed.blitz_best))

func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(save_data))

func _tone(frequency: int) -> void:
	if not bool(save_data.sound):
		return
	if not tones.has(frequency):
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = 22050
		var buffer := PackedByteArray()
		var samples := 1543
		buffer.resize(samples * 2)
		for i in range(samples):
			var envelope: float = sin(float(i) / samples * PI) * pow(1.0 - float(i) / samples, 2)
			var sample_value: int = int(sin(float(i) * TAU * frequency / 22050.0) * 5000 * envelope)
			buffer.encode_s16(i * 2, sample_value)
		wav.data = buffer
		tones[frequency] = wav
	audio_player.stream = tones[frequency]
	audio_player.play()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and screen == "game" and not completed and mode != "blitz" and mode != "duel":
		_pause()
		var contents := _modal("Hazır olduğunda devam", "Oyun duraklatıldı. Süren korunuyor.")
		_button(contents, "DEVAM ET", _close_modal, GOLD)
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if screen == "game":
			_exit_game()
		else:
			_show_home()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(overlay):
			_close_modal()
		elif screen == "game":
			_exit_game()
		else:
			_show_home()
	if screen == "game" and not is_instance_valid(overlay) and event is InputEventKey:
		if event.keycode == KEY_Z:
			_undo()
		elif event.keycode == KEY_H:
			_hint()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
			var index: int = int(event.keycode - KEY_1)
			if index < numbers.size():
				_tap_number(index)
