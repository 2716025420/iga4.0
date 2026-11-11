class_name SchoolPaperSurface
extends Control

## Quiet paper edges and abstract school objects, drawn at their actual proportions.
var fill := Color("#F8F3E8")
var accent := Color("#A5BEB0")
var motif := ""
var outlined := true
var ink := Color(0.26, 0.31, 0.39, 0.38)

static func create(parent: Control, node_name: String, rect: Rect2, color: Color = Color("#F8F3E8"), drawing: String = "") -> SchoolPaperSurface:
	var paper := SchoolPaperSurface.new()
	paper.name = node_name
	paper.fill = color
	paper.motif = drawing
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(paper)
	DaylightUI.place(paper, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	return paper

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED: queue_redraw()

func _poly(points: Array, color: Color, edge: bool = false) -> void:
	var packed := PackedVector2Array()
	for point in points: packed.append(Vector2(point[0], point[1]) * size)
	draw_colored_polygon(packed, color)
	if edge:
		packed.append(packed[0])
		draw_polyline(packed, ink, 1.15, true)

func _line(a: Vector2, b: Vector2, color: Color, width: float = 1.2) -> void:
	draw_line(a * size, b * size, color, width, true)

func _draw() -> void:
	_poly([[0.002,0.008],[0.985,0.002],[0.998,0.018],[0.994,0.992],[0.016,0.998],[0.001,0.98]], Color(0.31,0.34,0.4,0.07))
	_poly([[0,0.004],[0.982,0],[0.997,0.015],[0.99,0.983],[0.014,0.989],[0.002,0.972]], fill, outlined)
	if motif == "ticket":
		for index in 12:
			_line(Vector2(0.19,0.05+index*0.074),Vector2(0.19,0.082+index*0.074),ink,1.0)
	elif motif == "map": _draw_map()
	elif motif != "": _draw_object()

func _draw_map() -> void:
	var route := [Vector2(0.13,0.83),Vector2(0.40,0.83),Vector2(0.40,0.53),Vector2(0.80,0.53),Vector2(0.80,0.22)]
	for index in route.size()-1: draw_dashed_line(route[index]*size,route[index+1]*size,Color("#B3AAA2"),2.2,9.0,true)
	_poly([[0.11,0.14],[0.47,0.12],[0.48,0.33],[0.12,0.35]],Color("#C6D5DC"),true)
	_poly([[0.13,0.11],[0.45,0.10],[0.49,0.14],[0.10,0.17]],Color("#A6BBC9"))
	_poly([[0.59,0.17],[0.88,0.18],[0.87,0.38],[0.59,0.37]],Color("#DAC7BA"),true)
	_poly([[0.12,0.46],[0.30,0.45],[0.31,0.63],[0.12,0.64]],Color("#D6D0B6"),true)
	_poly([[0.53,0.65],[0.88,0.66],[0.88,0.86],[0.53,0.85]],Color("#B9CCBB"),true)
	for x in [0.18,0.29,0.40]:
		_poly([[x,0.20],[x+0.035,0.20],[x+0.035,0.25],[x,0.25]],Color("#EFF1E9"))
	for tree in [Vector2(0.17,0.75),Vector2(0.88,0.46),Vector2(0.48,0.43),Vector2(0.49,0.91)]:
		_line(tree+Vector2(0,0.02),tree+Vector2(0,0.09),ink)
		_poly([[tree.x-0.036,tree.y+0.03],[tree.x-0.045,tree.y-0.02],[tree.x+0.004,tree.y-0.06],[tree.x+0.047,tree.y-0.008],[tree.x+0.027,tree.y+0.04]],Color("#9EB9A1"))
	for point in [route[0],route[2],route[4]]:
		draw_circle(point*size,7,Color("#FAF5EA"))
		draw_arc(point*size,7,0,TAU,24,Color("#9A879C"),1.7,true)

func _draw_object() -> void:
	match motif:
		"chest", "merchant":
			_poly([[0.25,0.40],[0.73,0.40],[0.76,0.78],[0.24,0.77]],accent,true)
			_poly([[0.23,0.30],[0.76,0.28],[0.79,0.42],[0.21,0.43]],accent.lightened(0.22),true)
			_poly([[0.46,0.39],[0.54,0.39],[0.54,0.56],[0.46,0.56]],Color("#EAD5A7"),true)
		"rest":
			_line(Vector2(0.28,0.56),Vector2(0.72,0.56),accent,16)
			_line(Vector2(0.26,0.70),Vector2(0.75,0.70),accent,12)
			for x in [0.32,0.68]: _line(Vector2(x,0.56),Vector2(x,0.84),ink,3)
			_poly([[0.12,0.41],[0.25,0.16],[0.39,0.42]],Color("#B3C9B2"))
		"npc":
			draw_circle(Vector2(0.51,0.31)*size,minf(size.x,size.y)*0.12,Color("#D8BCAE"))
			_poly([[0.32,0.49],[0.65,0.48],[0.75,0.80],[0.24,0.80]],accent,true)
			_poly([[0.56,0.59],[0.77,0.55],[0.81,0.72],[0.59,0.76]],Color("#F2E7CC"),true)
		"story":
			_poly([[0.25,0.25],[0.77,0.21],[0.76,0.79],[0.26,0.82]],Color("#F6EAD0"),true)
			for y in [0.39,0.50,0.61]: _line(Vector2(0.36,y),Vector2(0.65,y-0.014),ink)
		"exit":
			for x in [0.25,0.72]: _line(Vector2(x,0.22),Vector2(x,0.80),accent,13)
			_line(Vector2(0.25,0.24),Vector2(0.73,0.24),accent,14)
			_line(Vector2(0.36,0.62),Vector2(0.65,0.62),ink,3)
			_line(Vector2(0.54,0.52),Vector2(0.65,0.62),ink,3)
			_line(Vector2(0.54,0.72),Vector2(0.65,0.62),ink,3)
		_:
			_poly([[0.30,0.31],[0.66,0.29],[0.73,0.71],[0.25,0.73]],accent,true)
			_poly([[0.37,0.15],[0.59,0.14],[0.65,0.33],[0.32,0.34]],accent.lightened(0.2),true)
			for x in [0.41,0.56]: draw_circle(Vector2(x,0.24)*size,3,ink)
			for x in [0.35,0.60]: _line(Vector2(x,0.70),Vector2(x,0.86),ink,4)
