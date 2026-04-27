extends Node

signal score_changed(new_score)
signal best_score_updated(new_best_score)
signal combo_updated(count)

var current_score: int = 0
var best_score: int = 0
var combo_count: int = 0
var combo_multiplier: float = 1.0
var combo_timer: float = 0.0

const COMBO_TIMEOUT := 2.5
const COMBO_BONUS := 0.15   # 콤보당 15% 보너스 (기존 50%에서 하향)
const MAX_COMBO_MULTIPLIER := 3.0

func _ready():
	load_best_score()

func _process(delta):
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			_reset_combo()

func add_score(base_points: int):
	var final_points := int(base_points * combo_multiplier)
	current_score += final_points

	combo_count += 1
	combo_multiplier = minf(1.0 + combo_count * COMBO_BONUS, MAX_COMBO_MULTIPLIER)
	combo_timer = COMBO_TIMEOUT

	emit_signal("score_changed", current_score)
	emit_signal("combo_updated", combo_count)

	if current_score > best_score:
		best_score = current_score
		save_best_score()
		emit_signal("best_score_updated", best_score)

func _reset_combo():
	combo_count = 0
	combo_multiplier = 1.0
	combo_timer = 0.0
	emit_signal("combo_updated", 0)

func reset_score():
	current_score = 0
	_reset_combo()
	emit_signal("score_changed", 0)

func get_current_score() -> int:
	return current_score

func get_best_score() -> int:
	return best_score

func load_best_score():
	var f := FileAccess.open("user://best_score.save", FileAccess.READ)
	if f:
		best_score = f.get_32()
		f.close()

func save_best_score():
	var f := FileAccess.open("user://best_score.save", FileAccess.WRITE)
	f.store_32(best_score)
	f.close()
