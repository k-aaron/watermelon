extends Node2D

signal game_over
signal game_started

@export var game_over_line_y: float = 75.0

var is_game_active: bool = true
var score_manager: Node
var audio_manager: Node
var game_over_checking: bool = false
var _muted: bool = false

# 게임오버 라인 색상 체크 쓰로틀
var _line_check_timer: float = 0.0
const LINE_CHECK_INTERVAL: float = 0.1

var combo_label: Label

@onready var score_label: Label = $UI/LeftPanel/ScoreSection/CurrentScore
@onready var best_score_label: Label = $UI/LeftPanel/ScoreSection/BestScore
@onready var game_over_dialog: AcceptDialog = $UI/GameOverDialog
@onready var fruit_spawner: Node2D = $GameArea/FruitSpawner
@onready var fruits_container: Node2D = $GameArea/Fruits
@onready var game_over_line: ColorRect = $GameArea/GameOverLine

func _ready():
	score_manager = preload("res://scripts/managers/ScoreManager.gd").new()
	add_child(score_manager)
	audio_manager = preload("res://scripts/managers/AudioManager.gd").new()
	add_child(audio_manager)
	setup_game()
	connect_signals()

func setup_game():
	is_game_active = true
	update_score_display()
	setup_combo_label()

func setup_combo_label():
	combo_label = Label.new()
	combo_label.position = Vector2(370, 200)
	combo_label.add_theme_font_size_override("font_size", 28)
	combo_label.modulate = Color.GOLD
	combo_label.visible = false
	add_child(combo_label)

func connect_signals():
	game_over_dialog.confirmed.connect(_on_restart_confirmed)
	$UI/LeftPanel/ButtonSection/RestartButton.pressed.connect(_on_restart_button_pressed)
	$UI/LeftPanel/ButtonSection/MuteButton.pressed.connect(_on_mute_button_pressed)
	score_manager.score_changed.connect(_on_score_changed)
	score_manager.best_score_updated.connect(_on_best_score_updated)
	score_manager.combo_updated.connect(_on_combo_updated)

func _process(delta):
	_line_check_timer += delta
	if _line_check_timer >= LINE_CHECK_INTERVAL:
		_line_check_timer = 0.0
		_update_game_over_line_color()

# ScoreManager가 콤보를 전담 — GameManager는 점수만 전달
func add_score(points: int):
	if not is_game_active:
		return
	score_manager.add_score(points)

func _update_game_over_line_color():
	if not is_game_active or not game_over_line:
		return
	for fruit in fruits_container.get_children():
		if is_instance_valid(fruit) and fruit.global_position.y <= game_over_line_y + 50:
			game_over_line.color = Color.RED
			return
	game_over_line.color = Color(1, 0.25, 0.25, 0.85)

func update_score_display():
	score_label.text = str(score_manager.get_current_score())
	best_score_label.text = str(score_manager.get_best_score())

func _on_score_changed(new_score: int):
	score_label.text = str(new_score)

func _on_best_score_updated(new_best: int):
	best_score_label.text = str(new_best)

func _on_combo_updated(count: int):
	if count > 1:
		combo_label.text = "COMBO x%d" % count
		combo_label.visible = true
	else:
		combo_label.visible = false

func check_game_over():
	if game_over_checking or not is_game_active:
		return
	game_over_checking = true

	await get_tree().create_timer(1.0).timeout
	if not is_game_active:
		game_over_checking = false
		return

	var candidates: Array = []
	for fruit in fruits_container.get_children():
		if is_instance_valid(fruit) and fruit.global_position.y <= game_over_line_y:
			if fruit.linear_velocity.length() < 100:
				candidates.append(fruit)

	if candidates.size() > 0:
		await get_tree().create_timer(1.0).timeout
		for fruit in candidates:
			if is_instance_valid(fruit) and is_game_active:
				if fruit.global_position.y <= game_over_line_y and fruit.linear_velocity.length() < 80:
					trigger_game_over()
					return

	game_over_checking = false

func trigger_game_over():
	if not is_game_active:
		return
	is_game_active = false
	audio_manager.play_sfx(audio_manager.SoundType.GAME_OVER)
	emit_signal("game_over")
	var final_score: int = score_manager.get_current_score()
	var best: int = score_manager.get_best_score()
	game_over_dialog.dialog_text = "최종 점수: %d\n최고 점수: %d" % [final_score, best]
	game_over_dialog.popup_centered()

func restart_game():
	for fruit in fruits_container.get_children():
		fruit.queue_free()
	score_manager.reset_score()
	is_game_active = true
	game_over_checking = false
	combo_label.visible = false
	update_score_display()
	emit_signal("game_started")

func _on_restart_confirmed():
	restart_game()

func _on_restart_button_pressed():
	restart_game()

func _on_mute_button_pressed():
	_muted = !_muted
	audio_manager.set_master_volume(0.0 if _muted else 1.0)
	$UI/LeftPanel/ButtonSection/MuteButton.text = "🔇 음악" if _muted else "🔊 음악"
