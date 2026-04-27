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

	generate_next_fruit()
	update_fruit_preview()

	can_drop = false
	await get_tree().create_timer(0.5).timeout
	can_drop = true

func create_fruit(type: int) -> RigidBody2D:
	var fruit = RigidBody2D.new()
	fruit.name = "Fruit_" + str(type)

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

	# 과일 타입 저장
	fruit.set_meta("fruit_type", type)
	fruit.set_meta("fruit_size", size)

	return fruit

func generate_next_fruit():
	next_fruit_type = randi() % 5  # 처음 5개 과일 타입만

func update_fruit_preview():
	fruit_preview.color = FRUIT_COLORS[next_fruit_type]