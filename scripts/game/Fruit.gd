extends RigidBody2D

var fruit_spawner: Node2D
var merge_timer: float = 0.0
var can_check_merge: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	# 드롭 후 잠시 대기 후 병합 체크 활성화
	await get_tree().create_timer(0.2).timeout
	can_check_merge = true

func _process(delta):
	if merge_timer > 0:
		merge_timer -= delta

func _on_body_entered(other_body: RigidBody2D):
	if not can_check_merge or merge_timer > 0:
		return

	if not other_body.has_meta("fruit_type"):
		return

	var my_type = get_meta("fruit_type", -1)
	var other_type = other_body.get_meta("fruit_type", -1)

	# 같은 타입의 과일이고 병합 가능한 경우
	if my_type == other_type and my_type >= 0:
		if get_meta("can_merge", false) and other_body.get_meta("can_merge", false):
			# 병합 쿨다운 설정
			merge_timer = 0.1
			other_body.set_meta("merge_timer", 0.1)

			# 병합 실행
			if fruit_spawner:
				fruit_spawner.merge_fruits(self, other_body)

func set_merge_cooldown():
	merge_timer = 0.5
	can_check_merge = false
	await get_tree().create_timer(0.5).timeout
	can_check_merge = true