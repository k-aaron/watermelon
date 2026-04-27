extends RigidBody2D

var fruit_spawner: Node2D
var merge_timer: float = 0.0
var can_check_merge: bool = false

func _ready():
	# 충돌 감지 설정
	contact_monitor = true
	max_contacts_reported = 10

	# 드롭 후 잠시 대기 후 병합 체크 활성화
	await get_tree().create_timer(0.2).timeout
	can_check_merge = true

func _process(delta):
	if merge_timer > 0:
		merge_timer -= delta

func _integrate_forces(state):
	if not can_check_merge or merge_timer > 0:
		return

	# 충돌하는 모든 바디 검사
	for i in range(state.get_contact_count()):
		var contact_body = state.get_contact_collider_object(i)
		if contact_body and contact_body != self:
			check_merge_with(contact_body)

func check_merge_with(other_body):
	if not other_body.has_meta("fruit_type"):
		return

	var my_type: int = get_meta("fruit_type", -1)
	var other_type: int = other_body.get_meta("fruit_type", -1)

	# 같은 타입의 과일이고 병합 가능한 경우
	if my_type == other_type and my_type >= 0 and my_type < 10:  # 수박은 병합 불가
		if get_meta("can_merge", false) and other_body.get_meta("can_merge", false):
			# 병합 쿨다운 설정
			merge_timer = 0.1
			if other_body.has_method("set_meta"):
				other_body.set_meta("merge_timer", 0.1)

			# 병합 실행
			if fruit_spawner:
				fruit_spawner.call_deferred("merge_fruits", self, other_body)

func set_merge_cooldown():
	merge_timer = 0.5
	can_check_merge = false
	await get_tree().create_timer(0.5).timeout
	can_check_merge = true