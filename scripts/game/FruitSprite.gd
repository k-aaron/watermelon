extends Node2D

var radius: float = 20.0
var base_color: Color = Color.RED

func setup(r: float, c: Color) -> void:
	radius = r
	base_color = c
	queue_redraw()

func _draw() -> void:
	var segs: int = maxi(24, int(radius * 1.5))

	# 그림자
	draw_circle(Vector2(2.5, 4.0), radius, Color(0, 0, 0, 0.18))

	# 본체
	draw_circle(Vector2.ZERO, radius, base_color)

	# 테두리 (어두운 림)
	draw_arc(Vector2.ZERO, radius - 1.0, 0.0, TAU, segs, base_color.darkened(0.32), 2.5)

	# 광택 하이라이트 (큰)
	draw_circle(
		Vector2(-radius * 0.22, -radius * 0.28),
		radius * 0.30,
		Color(1.0, 1.0, 1.0, 0.38)
	)
	# 광택 하이라이트 (작은 반사점)
	draw_circle(
		Vector2(-radius * 0.13, -radius * 0.38),
		radius * 0.11,
		Color(1.0, 1.0, 1.0, 0.72)
	)
