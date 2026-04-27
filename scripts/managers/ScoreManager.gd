extends Node

signal score_changed(new_score)
signal best_score_updated(new_best_score)

var current_score: int = 0
var best_score: int = 0
var combo_multiplier: float = 1.0
var combo_count: int = 0
var combo_timer: float = 0.0

const COMBO_TIMEOUT = 3.0  # 콤보 유지 시간
const COMBO_BONUS = 0.5    # 콤보당 보너스 배율

func _ready():
	load_best_score()

func _process(delta):
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			reset_combo()

func add_score(base_points: int):
	# 콤보 시스템 적용
	var final_points = int(base_points * combo_multiplier)
	current_score += final_points

	# 콤보 증가
	combo_count += 1
	combo_multiplier = 1.0 + (combo_count * COMBO_BONUS)
	combo_timer = COMBO_TIMEOUT

	emit_signal("score_changed", current_score)

	# 최고 점수 확인
	if current_score > best_score:
		best_score = current_score
		save_best_score()
		emit_signal("best_score_updated", best_score)

func reset_combo():
	combo_count = 0
	combo_multiplier = 1.0
	combo_timer = 0.0

func reset_score():
	current_score = 0
	reset_combo()
	emit_signal("score_changed", current_score)

func get_current_score() -> int:
	return current_score

func get_best_score() -> int:
	return best_score

func get_combo_info() -> Dictionary:
	return {
		"count": combo_count,
		"multiplier": combo_multiplier,
		"timer": combo_timer
	}

func load_best_score():
	var save_file = FileAccess.open("user://best_score.save", FileAccess.READ)
	if save_file:
		best_score = save_file.get_32()
		save_file.close()
	else:
		best_score = 0

func save_best_score():
	var save_file = FileAccess.open("user://best_score.save", FileAccess.WRITE)
	save_file.store_32(best_score)
	save_file.close()