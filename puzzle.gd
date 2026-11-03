class_name ReversePuzzle
extends RefCounted

const SYMBOLS = ["+", "−", "×", "÷"]

static func gcd(a: int, b: int) -> int:
	a = absi(a)
	b = absi(b)
	while b != 0:
		var r: int = a % b
		a = b
		b = r
	return maxi(a, 1)

static func rational(n: int, d: int) -> Array:
	if d == 0:
		return []
	if d < 0:
		n = -n
		d = -d
	var common: int = gcd(n, d)
	return [n / common, d / common]

static func evaluate(numbers: Array, operators: Array, backwards: bool = false) -> Array:
	if numbers.is_empty() or operators.size() != numbers.size() - 1:
		return []
	var ns: Array = numbers.duplicate()
	var ops: Array = operators.duplicate()
	if backwards:
		ns.reverse()
		ops.reverse()
	var value: Array = [int(ns[0]), 1]
	for i in range(ops.size()):
		var b: int = int(ns[i + 1])
		match int(ops[i]):
			0: value = rational(int(value[0]) + b * int(value[1]), int(value[1]))
			1: value = rational(int(value[0]) - b * int(value[1]), int(value[1]))
			2: value = rational(int(value[0]) * b, int(value[1]))
			3: value = rational(int(value[0]), int(value[1]) * b)
			_: return []
		if value.is_empty() or absi(int(value[0])) > 100000000:
			return []
	return value

static func format_value(value: Array) -> String:
	if value.is_empty():
		return "—"
	return str(value[0]) if int(value[1]) == 1 else "%s/%s" % [value[0], value[1]]

static func solved(numbers: Array, operators: Array, puzzle: Dictionary) -> bool:
	return evaluate(numbers, operators) == puzzle.left and evaluate(numbers, operators, true) == puzzle.right

static func generate(level: int, seed_value: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value >= 0 else level * 9187 + 4121
	var count: int = mini(6, 3 + (level - 1) / 18)
	var allowed: Array = [0, 2]
	if level >= 13:
		allowed = [0, 1, 2]
	if level >= 55:
		allowed = [0, 1, 2, 3]
	var ns: Array = []
	var ops: Array = []
	var left: Array = []
	var right: Array = []
	for attempt in range(10000):
		ns.clear()
		ops.clear()
		for i in range(count):
			ns.append(rng.randi_range(1, 9))
		for i in range(count - 1):
			ops.append(allowed[rng.randi_range(0, allowed.size() - 1)])
		left = evaluate(ns, ops)
		right = evaluate(ns, ops, true)
		if not left.is_empty() and not right.is_empty() and left != right and int(left[1]) == 1 and int(right[1]) == 1 and absi(int(left[0])) < 3000 and absi(int(right[0])) < 3000:
			break
	if level == 1 and seed_value < 0:
		ns = [2, 3, 4]
		ops = [0, 2]
		left = [20, 1]
		right = [14, 1]
	var initial: Array = ns.duplicate()
	for i in range(count - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: int = int(initial[i])
		initial[i] = initial[j]
		initial[j] = temp
	var start_ops: Array = []
	for i in range(count - 1):
		start_ops.append(allowed[rng.randi_range(0, allowed.size() - 1)])
	var puzzle: Dictionary = {"solution": ns.duplicate(), "solution_ops": ops.duplicate(), "initial": initial, "initial_ops": start_ops, "left": left, "right": right, "allowed": allowed, "level": level}
	if solved(initial, start_ops, puzzle):
		start_ops[0] = allowed[(allowed.find(start_ops[0]) + 1) % allowed.size()]
	return puzzle
