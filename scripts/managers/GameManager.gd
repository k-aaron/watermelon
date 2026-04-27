extends Node2D

signal game_over
signal game_started

@export var game_over_line_y: float = 330.0

var is_game_active: bool = true
var score_manager: Node
var audio_manager: Node
var game_over_checking: bool = false

@onready var score_label: Label = $UI/ScorePanel/VBoxContainer/CurrentScore
@onready var best_score_label: Label = $UI/ScorePanel/VBoxContainer/BestScore
@onready var game_over_dialog: AcceptDialog = $UI/GameOverDialog
@onready var fruit_spawner: Node2D = $GameArea/FruitSpawner
@onready var fruits_container: Node2D = $GameArea/Fruits

func _ready():
	# ScoreManager 생성 및 설정
	score_manager = preload("res://scripts/managers/ScoreManager.gd").new()
	add_child(score_manager)

	# AudioManager 생성 및 설정
	audio_manager = preload("res://scripts/managers/AudioManager.gd").new()
	add_child(audio_manager)

	setup_game()
	connect_signals()

func setup_game():
	is_game_active = true
	update_score_display()

func connect_signals():
	game_over_dialog.confirmed.connect(_on_restart_confirmed)
	$UI/GameControls/RestartButton.pressed.connect(_on_restart_button_pressed)
	$UI/GameControls/PauseButton.pressed.connect(_on_pause_button_pressed)

	# ScoreManager 시그널 연결
	score_manager.score_changed.connect(_on_score_changed)
	score_manager.best_score_updated.connect(_on_best_score_updated)

func add_score(points: int):
	if not is_game_active:
		return

	score_manager.add_score(points)

func update_score_display():
	score_label.text = str(score_manager.get_current_score())
	best_score_label.text = str(score_manager.get_best_score())

# ScoreManager 시그널 핸들러들
func _on_score_changed(new_score: int):
	score_label.text = str(new_score)

func _on_best_score_updated(new_best_score: int):
	best_score_label.text = str(new_best_score)

func check_game_over():
	# 중복 체크 방지
	if game_over_checking or not is_game_active:
		return

	game_over_checking = true

	# 잠시 대기 후 체크 (과일이 정착될 시간)
	await get_tree().create_timer(1.0).timeout

	# 게임이 여전히 활성 상태인지 확인
	if not is_game_active:
		game_over_checking = false
		return

	# 게임오버 라인을 넘은 과일 체크
	var fruits_over_line = []
	for fruit in fruits_container.get_children():
		if fruit and is_instance_valid(fruit):
			if fruit.global_position.y <= game_over_line_y:
				# 속도가 느리거나 멈춘 과일만 체크 (떨어지는 중이 아닌)
				if fruit.linear_velocity.length() < 100:
					fruits_over_line.append(fruit)

	# 라인을 넘은 과일이 있고, 잠시 더 대기 후에도 여전히 넘어있으면 게임오버
	if fruits_over_line.size() > 0:
		await get_tree().create_timer(1.0).timeout

		# 다시 한번 확인
		for fruit in fruits_over_line:
			if fruit and is_instance_valid(fruit) and is_game_active:
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
	game_over_dialog.popup_centered()


func restart_game():
	for fruit in fruits_container.get_children():
		fruit.queue_free()

	score_manager.reset_score()
	is_game_active = true
	game_over_checking = false
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