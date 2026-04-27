extends Node2D

signal fruit_dropped(fruit)

@export var spawn_height: float = 100.0
@export var container_left: float = 160.0
@export var container_right: float = 560.0

var next_fruit_type: int = 0
var can_drop: bool = true
var drop_preview_line: Line2D

@onready var game_manager: Node2D = get_parent().get_parent()
@onready var fruits_container: Node2D = get_parent().get_node("Fruits")
@onready var fruit_preview: ColorRect = $"../../UI/NextFruit/VBoxContainer/FruitPreview"

const FRUIT_COLORS = [
	Color.RED,           # 체리
	Color.PINK,          # 딸기
	Color.PURPLE,        # 포도
	Color.ORANGE,        # 귤
	Color.ORANGE_RED,    # 감
	Color.CRIMSON,       # 사과
	Color.YELLOW,        # 배
	Color.LIGHT_PINK,    # 복숭아
	Color.GOLD,          # 파인애플
	Color.LIGHT_GREEN,   # 멜론
	Color.GREEN          # 수박
]

const FRUIT_SIZES = [20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70]

func _ready():
	setup_preview_line()
	generate_next_fruit()
	update_fruit_preview()

func setup_preview_line():
	drop_preview_line = Line2D.new()
	drop_preview_line.width = 2.0
	drop_preview_line.default_color = Color.YELLOW
	add_child(drop_preview_line)

func _input(event):
	if not can_drop or not game_manager.is_game_active:
		return

	if event is InputEventMouseMotion:
		update_drop_preview(event.position.x)
	elif event is InputEventMouseButton and event.pressed:
		drop_fruit_at(event.position.x)

func update_drop_preview(x_position: float):
	var clamped_x = clamp(x_position, container_left, container_right)
	var start_pos = Vector2(clamped_x - global_position.x, 0)
	var end_pos = Vector2(clamped_x - global_position.x, 400)

	drop_preview_line.clear_points()
	drop_preview_line.add_point(start_pos)
	drop_preview_line.add_point(end_pos)

func drop_fruit_at(x_position: float):
	if not can_drop:
		return

	var clamped_x = clamp(x_position, container_left, container_right)
	var fruit = create_fruit(next_fruit_type)
	fruit.global_position = Vector2(clamped_x, global_position.y)

	fruits_container.add_child(fruit)
	emit_signal("fruit_dropped", fruit)

	# 게임오버 체크 요청
	game_manager.check_game_over()

	generate_next_fruit()
	update_fruit_preview()

	can_drop = false
	await get_tree().create_timer(0.5).timeout
	can_drop = true

func create_fruit(type: int) -> RigidBody2D:
	var fruit = RigidBody2D.new()
	fruit.name = "Fruit_" + str(type)

	# 물리 속성 설정
	fruit.mass = 1.0 + (type * 0.2)  # 크기에 따른 질량 차이
	fruit.gravity_scale = 1.0
	fruit.linear_damp = 0.1  # 공기 저항

	# 스프라이트 설정
	var sprite = ColorRect.new()
	var size = FRUIT_SIZES[type]
	sprite.size = Vector2(size, size)
	sprite.position = Vector2(-size/2, -size/2)
	sprite.color = FRUIT_COLORS[type]
	fruit.add_child(sprite)

	# 충돌 설정
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = size / 2
	collision.shape = shape
	fruit.add_child(collision)

	# 물리 재질 설정
	var physics_material = PhysicsMaterial.new()
	physics_material.bounce = 0.3  # 탄성
	physics_material.friction = 0.8  # 마찰력
	fruit.physics_material_override = physics_material

	# 과일 타입 저장
	fruit.set_meta("fruit_type", type)
	fruit.set_meta("fruit_size", size)
	fruit.set_meta("can_merge", true)
	fruit.set_meta("merge_timer", 0.0)

	# 충돌 감지를 위한 스크립트 연결
	fruit.set_script(preload("res://scripts/game/Fruit.gd"))
	fruit.fruit_spawner = self

	return fruit

func generate_next_fruit():
	next_fruit_type = randi() % 5  # 처음 5개 과일 타입만

func update_fruit_preview():
	fruit_preview.color = FRUIT_COLORS[next_fruit_type]

func merge_fruits(fruit1: RigidBody2D, fruit2: RigidBody2D):
	if not fruit1 or not fruit2:
		return

	var type1 = fruit1.get_meta("fruit_type", -1)
	var type2 = fruit2.get_meta("fruit_type", -1)

	# 병합 조건 재확인
	if type1 != type2 or type1 < 0 or type1 >= FRUIT_COLORS.size() - 1:
		return

	if not fruit1.get_meta("can_merge", false) or not fruit2.get_meta("can_merge", false):
		return

	var new_type = type1 + 1

	# 새로운 위치 계산 (두 과일의 중점)
	var merge_position = (fruit1.global_position + fruit2.global_position) / 2

	# 기존 과일들을 병합 불가능 상태로 설정
	fruit1.set_meta("can_merge", false)
	fruit2.set_meta("can_merge", false)

	# 새로운 과일 생성
	var new_fruit = create_fruit(new_type)
	new_fruit.global_position = merge_position

	# 기존 과일의 속도를 새 과일에 적용
	var avg_velocity = (fruit1.linear_velocity + fruit2.linear_velocity) / 2
	new_fruit.linear_velocity = avg_velocity * 0.5  # 속도 감쇠

	# 컨테이너에 추가
	fruits_container.add_child(new_fruit)

	# 병합 쿨다운 설정
	new_fruit.set_merge_cooldown()

	# 점수 추가
	var score_points = (new_type + 1) * 10
	game_manager.add_score(score_points)

	# 기존 과일들 제거
	fruit1.queue_free()
	fruit2.queue_free()