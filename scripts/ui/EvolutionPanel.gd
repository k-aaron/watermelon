extends CanvasLayer

const FRUIT_NAMES: Array = ["체리","딸기","포도","귤","감","사과","배","복숭아","파인애플","멜론","수박"]
const FRUIT_COLORS: Array = [
	Color.RED, Color.PINK, Color.PURPLE, Color.ORANGE, Color.ORANGE_RED,
	Color.CRIMSON, Color.YELLOW, Color.LIGHT_PINK, Color.GOLD, Color.LIGHT_GREEN, Color.DARK_GREEN
]
const FRUIT_SIZES: Array = [30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130]
const FRUIT_SCORES: Array = [1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66]

# 행 배치: [행1 인덱스], [행2 인덱스], [행3 인덱스]
const ROWS: Array = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10]]

func _ready() -> void:
	layer = 10
	_build()

func _build() -> void:
	# 우측 하단 상시 표시 패널
	var panel := PanelContainer.new()
	panel.position = Vector2(700, 148)
	panel.custom_minimum_size = Vector2(260, 388)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	# ── 타이틀 ──────────────────────────────
	var title := Label.new()
	title.text = "진화의 고리"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# ── 과일 행 ─────────────────────────────
	for row_idx in range(ROWS.size()):
		var row: Array = ROWS[row_idx]
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 0)
		vbox.add_child(hbox)

		for j in range(row.size()):
			var fruit_idx: int = row[j]
			hbox.add_child(_make_fruit_cell(fruit_idx))

			if j < row.size() - 1:
				var arrow := Label.new()
				arrow.text = "→"
				arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				arrow.add_theme_font_size_override("font_size", 10)
				arrow.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				hbox.add_child(arrow)

		if row_idx < ROWS.size() - 1:
			var row_arrow := Label.new()
			row_arrow.text = "↓"
			row_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row_arrow.add_theme_font_size_override("font_size", 10)
			row_arrow.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			vbox.add_child(row_arrow)

	# ── 구분선 + 설명 ────────────────────────
	vbox.add_child(HSeparator.new())

	var hint := Label.new()
	hint.text = "같은 과일끼리 합쳐져요!"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	vbox.add_child(hint)

func _make_fruit_cell(idx: int) -> Control:
	var cell := VBoxContainer.new()
	cell.alignment = BoxContainer.ALIGNMENT_CENTER
	cell.add_theme_constant_override("separation", 1)

	# 사이드바용 소형 아이콘 (크기 비례 유지, 축소)
	var display_radius: float = 9.0 + float(idx) * 1.1

	var icon := preload("res://scripts/ui/FruitIcon.gd").new()
	icon.setup(display_radius, FRUIT_COLORS[idx])
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = FRUIT_NAMES[idx]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 8)
	cell.add_child(name_lbl)

	var score_lbl := Label.new()
	score_lbl.text = "+%d" % FRUIT_SCORES[idx]
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_size_override("font_size", 7)
	score_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	cell.add_child(score_lbl)

	return cell
