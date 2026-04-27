extends Node2D

signal fruit_dropped(fruit)

@export var spawn_height: float = 100.0
@export var container_left: float = 50.0
@export var container_right: float = 430.0

var next_fruit_type: int = 0
var can_drop: bool = true
var drop_preview_line: Line2D

# 병합 중인 쌍을 추적해 중복 병합 방지
var _merging_pairs: Dictionary = {}

# 타입별 캐시 (매 생성마다 재할당 방지)
var _cached_shapes: Array = []
var _cached_material: PhysicsMaterial

@onready var game_manager: Node2D = get_parent().get_parent()
@onready var fruits_container: Node2D = get_parent().get_node("Fruits")
@onready var fruit_preview: ColorRect = $"../../UI/HUDPanel/NextFruitSection/FruitPreview"
@onready var fruit_name_label: Label = $"../../UI/HUDPanel/NextFruitSection/FruitNameLabel"

const FRUIT_NAMES = [
	"체리", "딸기", "포도", "귤", "감",
	"사과", "배", "복숭아", "파인애플", "멜론", "수박"
]

const FRUIT_COLORS = [
	Color.RED,
	Color.PINK,
	Color.PURPLE,
	Color.ORANGE,
	Color.ORANGE_RED,
	Color.CRIMSON,
	Color.YELLOW,
	Color.LIGHT_PINK,
	Color.GOLD,
	Color.LIGHT_GREEN,
	Color.DARK_GREEN
]

const FRUIT_SIZES = [20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70]
const FRUIT_SCORES = [1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66]

func _ready():
	_build_cache()
	setup_preview_line()
	generate_next_fruit()
	update_fruit_preview()

func _build_cache():
	_cached_material = PhysicsMaterial.new()
	_cached_material.bounce = 0.3
	_cached_material.friction = 0.8

	_cached_shapes.resize(FRUIT_SIZES.size())
	for i in range(FRUIT_SIZES.size()):
		var shape = CircleShape2D.new()
		shape.radius = FRUIT_SIZES[i] / 2.0
		_cached_shapes[i] = shape

func setup_preview_line():
	drop_preview_line = Line2D.new()
	drop_preview_line.width = 2.0
	drop_preview_line.default_color = Color(1, 1, 0, 0.6)
	drop_preview_line.add_point(Vector2.ZERO)
	drop_preview_line.add_point(Vector2(0, 600))
	add_child(drop_preview_line)

func _input(event):
	if not can_drop or not game_manager.is_game_active:
		return

	if event is InputEventMouseMotion:
		update_drop_preview(event.position.x)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		drop_fruit_at(event.position.x)

func update_drop_preview(x_position: float):
	var fruit_radius: float = float(FRUIT_SIZES[next_fruit_type]) / 2.0
	var clamped_x = clamp(x_position, container_left + fruit_radius, container_right - fruit_radius)
	var local_x = clamped_x - global_position.x
	drop_preview_line.set_point_position(0, Vector2(local_x, 0))
	drop_preview_line.set_point_position(1, Vector2(local_x, 600))

func drop_fruit_at(x_position: float):
	if not can_drop:
		return

	var fruit_radius: float = float(FRUIT_SIZES[next_fruit_type]) / 2.0
	var clamped_x = clamp(x_position, container_left + fruit_radius, container_right - fruit_radius)
	var fruit = create_fruit(next_fruit_type)
	fruit.global_position = Vector2(clamped_x, global_position.y)

	fruits_container.add_child(fruit)
	emit_signal("fruit_dropped", fruit)

	game_manager.audio_manager.play_sfx(game_manager.audio_manager.SoundType.DROP)
	game_manager.check_game_over()

	generate_next_fruit()
	update_fruit_preview()

	can_drop = false
	await get_tree().create_timer(0.3).timeout
	can_drop = true

func create_fruit(type: int) -> RigidBody2D:
	var fruit = RigidBody2D.new()
	fruit.name = "Fruit_" + str(type)
	fruit.mass = 1.0 + (type * 0.2)
	fruit.gravity_scale = 1.0
	fruit.linear_damp = 0.1
	fruit.physics_material_override = _cached_material

	var size = FRUIT_SIZES[type]
	var sprite = preload("res://scripts/game/FruitSprite.gd").new()
	sprite.setup(size / 2.0, FRUIT_COLORS[type])
	fruit.add_child(sprite)

	var collision = CollisionShape2D.new()
	collision.shape = _cached_shapes[type]
	fruit.add_child(collision)

	fruit.set_meta("fruit_type", type)
	fruit.set_meta("can_merge", true)
	fruit.set_script(preload("res://scripts/game/Fruit.gd"))
	fruit.fruit_spawner = self

	return fruit

func generate_next_fruit():
	var current_score = 0
	if game_manager and game_manager.score_manager:
		current_score = game_manager.score_manager.get_current_score()

	var max_fruit_types: int
	if current_score >= 1000:
		max_fruit_types = 7
	elif current_score >= 500:
		max_fruit_types = 6
	else:
		max_fruit_types = 5

	next_fruit_type = randi() % max_fruit_types

func update_fruit_preview():
	fruit_preview.color = FRUIT_COLORS[next_fruit_type]
	fruit_name_label.text = FRUIT_NAMES[next_fruit_type]

func merge_fruits(fruit1: RigidBody2D, fruit2: RigidBody2D):
	if not is_instance_valid(fruit1) or not is_instance_valid(fruit2):
		return

	# 두 과일의 인스턴스 ID로 쌍 키 생성 (순서 무관)
	var id1 := fruit1.get_instance_id()
	var id2 := fruit2.get_instance_id()
	var pair_key: int = mini(id1, id2) * 1000000 + maxi(id1, id2)
	if _merging_pairs.has(pair_key):
		return
	_merging_pairs[pair_key] = true

	var type1: int = fruit1.get_meta("fruit_type", -1)
	var type2: int = fruit2.get_meta("fruit_type", -1)

	if type1 != type2 or type1 < 0 or type1 >= FRUIT_COLORS.size() - 1:
		_merging_pairs.erase(pair_key)
		return

	if not fruit1.get_meta("can_merge", false) or not fruit2.get_meta("can_merge", false):
		_merging_pairs.erase(pair_key)
		return

	var new_type: int = type1 + 1
	var merge_position: Vector2 = (fruit1.global_position + fruit2.global_position) / 2.0
	var avg_velocity: Vector2 = (fruit1.linear_velocity + fruit2.linear_velocity) / 2.0

	fruit1.set_meta("can_merge", false)
	fruit2.set_meta("can_merge", false)
	fruit1.queue_free()
	fruit2.queue_free()

	await get_tree().process_frame

	_merging_pairs.erase(pair_key)

	var new_fruit = create_fruit(new_type)
	new_fruit.global_position = merge_position
	new_fruit.linear_velocity = avg_velocity * 0.3
	new_fruit.scale = Vector2.ZERO
	fruits_container.add_child(new_fruit)
	new_fruit.set_merge_cooldown()

	# 스케일 팝 애니메이션
	var pop_tween = new_fruit.create_tween()
	pop_tween.tween_property(new_fruit, "scale", Vector2(1.25, 1.25), 0.12)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	pop_tween.tween_property(new_fruit, "scale", Vector2.ONE, 0.1)\
		.set_ease(Tween.EASE_IN_OUT)

	game_manager.add_score(FRUIT_SCORES[new_type])
	game_manager.audio_manager.play_sfx(game_manager.audio_manager.SoundType.MERGE)
	create_merge_effect(merge_position, new_type)
	create_merge_flash(merge_position, FRUIT_SIZES[new_type] / 2.0)

func create_merge_effect(merge_pos: Vector2, fruit_type: int):
	var main := get_parent().get_parent()
	var label := Label.new()
	label.text = "+" + str(FRUIT_SCORES[fruit_type])
	label.position = merge_pos - Vector2(22, 28)
	label.modulate = Color(1.0, 0.95, 0.2, 1.0)
	label.add_theme_font_size_override("font_size", 28)
	main.add_child(label)

	var tw := create_tween()
	tw.parallel().tween_property(label, "position", merge_pos - Vector2(22, 90), 0.75)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.75)
	tw.tween_callback(label.queue_free)

func create_merge_flash(merge_pos: Vector2, radius: float):
	var main := get_parent().get_parent()
	# 두 겹의 확장 원형 플래시
	for i in range(2):
		var flash := preload("res://scripts/game/FruitSprite.gd").new()
		flash.setup(radius * (0.8 + i * 0.4), Color(1.0, 1.0, 0.6, 0.7 - i * 0.25))
		flash.position = merge_pos
		main.add_child(flash)

		var tw := main.create_tween()
		tw.parallel().tween_property(flash, "scale", Vector2(2.8, 2.8), 0.35)\
			.set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.35)
		tw.tween_callback(flash.queue_free)
