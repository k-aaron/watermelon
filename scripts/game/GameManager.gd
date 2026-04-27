extends Node2D

signal score_changed(new_score)
signal game_over
signal game_started

@export var game_over_line_y: float = 330.0

var current_score: int = 0
var best_score: int = 0
var is_game_active: bool = true

@onready var score_label: Label = $UI/ScorePanel/VBoxContainer/CurrentScore
@onready var best_score_label: Label = $UI/ScorePanel/VBoxContainer/BestScore
@onready var game_over_dialog: AcceptDialog = $UI/GameOverDialog
@onready var fruit_spawner: Node2D = $GameArea/FruitSpawner
@onready var fruits_container: Node2D = $GameArea/Fruits

func _ready():
	load_best_score()
	setup_game()
	connect_signals()

func setup_game():
	current_score = 0
	is_game_active = true
	update_score_display()

func connect_signals():
	game_over_dialog.confirmed.connect(_on_restart_confirmed)
	$UI/GameControls/RestartButton.pressed.connect(_on_restart_button_pressed)
	$UI/GameControls/PauseButton.pressed.connect(_on_pause_button_pressed)

func add_score(points: int):
	if not is_game_active:
		return

	current_score += points
	emit_signal("score_changed", current_score)
	update_score_display()

	if current_score > best_score:
		best_score = current_score
		save_best_score()
		update_score_display()

func update_score_display():
	score_label.text = str(current_score)
	best_score_label.text = str(best_score)

func check_game_over():
	# 게임오버 체크를 위한 타이머 설정
	await get_tree().create_timer(2.0).timeout

	for fruit in fruits_container.get_children():
		if fruit.global_position.y <= game_over_line_y and fruit.linear_velocity.length() < 50:
			trigger_game_over()
			return

func trigger_game_over():
	if not is_game_active:
		return

	is_game_active = false
	emit_signal("game_over")
	game_over_dialog.popup_centered()

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

func restart_game():
	for fruit in fruits_container.get_children():
		fruit.queue_free()

	current_score = 0
	is_game_active = true
	update_score_display()
	emit_signal("game_started")

func _on_restart_confirmed():
	restart_game()

func _on_restart_button_pressed():
	restart_game()

func _on_pause_button_pressed():
	get_tree().paused = !get_tree().paused
	var button = $UI/GameControls/PauseButton
	if get_tree().paused:
		button.text = "계속"
	else:
		button.text = "일시정지"