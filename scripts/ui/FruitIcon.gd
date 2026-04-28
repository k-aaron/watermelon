extends Control

var radius: float = 20.0
var base_color: Color = Color.RED

func setup(r: float, c: Color) -> void:
	radius = r
	base_color = c
	custom_minimum_size = Vector2(r * 2.0 + 8.0, r * 2.0 + 8.0)
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var segs: int = maxi(16, int(radius * 1.2))
	draw_circle(center + Vector2(1.5, 2.5), radius, Color(0, 0, 0, 0.2))
	draw_circle(center, radius, base_color)
	draw_arc(center, radius - 1.0, 0.0, TAU, segs, base_color.darkened(0.3), 2.0)
	draw_circle(center + Vector2(-radius * 0.22, -radius * 0.28), radius * 0.28, Color(1, 1, 1, 0.4))
	draw_circle(center + Vector2(-radius * 0.14, -radius * 0.36), radius * 0.10, Color(1, 1, 1, 0.7))
