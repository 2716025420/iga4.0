class_name TerminalProjection
extends RefCounted

## One physical device from Overview. Only the screen's contents are reprojected.
## Live controls use the same mapping; no alternate device can appear on a page change.
const TARGET := [[145,120],[1525,120],[1555,818],[121,818]]
const SOURCES := {
	"overview":[[145,120],[1525,120],[1555,818],[121,818]],
	"zodiac":[[115,103],[1554,103],[1568,842],[106,842]],
	"cards":[[145,120],[1525,120],[1555,818],[121,818]],
	"journal":[[145,118],[1527,118],[1555,818],[121,818]],
	"contacts":[[128,111],[1544,111],[1565,818],[114,818]],
	"inventory":[[145,120],[1525,120],[1555,818],[121,818]]
}

const PLATES := {
	"overview": [
		[
			385,
			281,
			733,
			225
		],
		[
			1135,
			281,
			383,
			225
		],
		[
			383,
			536,
			549,
			109
		],
		[
			953,
			536,
			569,
			109
		],
		[
			383,
			665,
			549,
			110
		],
		[
			953,
			665,
			569,
			110
		]
	],
	"zodiac": [
		[
			355,
			271,
			166,
			166
		],
		[
			533.5,
			271,
			166,
			166
		],
		[
			712,
			271,
			166,
			166
		],
		[
			890.5,
			271,
			166,
			166
		],
		[
			355,
			448,
			166,
			166
		],
		[
			533.5,
			448,
			166,
			166
		],
		[
			712,
			448,
			166,
			166
		],
		[
			890.5,
			448,
			166,
			166
		],
		[
			355,
			625,
			166,
			166
		],
		[
			533.5,
			625,
			166,
			166
		],
		[
			712,
			625,
			166,
			166
		],
		[
			890.5,
			625,
			166,
			166
		],
		[
			1078,
			271,
			478,
			521
		]
	],
	"cards": [
		[
			385,
			294,
			217,
			223
		],
		[
			619,
			294,
			217,
			223
		],
		[
			853,
			294,
			217,
			223
		],
		[
			385,
			534,
			217,
			223
		],
		[
			619,
			534,
			217,
			223
		],
		[
			853,
			534,
			217,
			223
		],
		[
			1092,
			290,
			430,
			470
		]
	],
	"journal": [
		[
			389,
			290,
			256,
			54
		],
		[
			662,
			290,
			251,
			54
		],
		[
			388,
			361,
			715,
			400
		],
		[
			1121,
			361,
			400,
			400
		]
	],
	"contacts": [
		[
			389,
			287,
			383,
			134
		],
		[
			389,
			438,
			383,
			134
		],
		[
			389,
			589,
			383,
			134
		],
		[
			799,
			286,
			728,
			438
		]
	],
	"inventory": [
		[
			388,
			283,
			164,
			54
		],
		[
			567,
			283,
			160,
			54
		],
		[
			741,
			283,
			164,
			54
		],
		[
			918,
			283,
			163,
			54
		],
		[
			1107,
			354,
			411,
			354
		]
	]
}

static func _points(values: Array) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for p in values: result.append(Vector2(p[0],p[1])*Vector2(1920,1080)/Vector2(1672,941))
	return result

static func _quad(points: Array[Vector2]) -> Array:
	var p0 := points[0]
	var p1 := points[1]
	var p2 := points[2]
	var p3 := points[3]
	var dx1 := p1.x-p2.x
	var dx2 := p3.x-p2.x
	var dx3 := p0.x-p1.x+p2.x-p3.x
	var dy1 := p1.y-p2.y
	var dy2 := p3.y-p2.y
	var dy3 := p0.y-p1.y+p2.y-p3.y
	var g := 0.0
	var h := 0.0
	if absf(dx3)+absf(dy3) > 0.00001:
		var denominator := dx1*dy2-dx2*dy1
		g = (dx3*dy2-dx2*dy3)/denominator
		h = (dx1*dy3-dx3*dy1)/denominator
	return [p1.x-p0.x+g*p1.x,p3.x-p0.x+h*p3.x,p0.x,p1.y-p0.y+g*p1.y,p3.y-p0.y+h*p3.y,p0.y,g,h,1.0]

static func _inverse(m: Array) -> Array:
	var a: float = m[0]
	var b: float = m[1]
	var c: float = m[2]
	var d: float = m[3]
	var e: float = m[4]
	var f: float = m[5]
	var g: float = m[6]
	var h: float = m[7]
	var i: float = m[8]
	var inverse := [e*i-f*h,c*h-b*i,b*f-c*e,f*g-d*i,a*i-c*g,c*d-a*f,d*h-e*g,b*g-a*h,a*e-b*d]
	var determinant: float = a*inverse[0]+b*inverse[3]+c*inverse[6]
	for index in inverse.size(): inverse[index] /= determinant
	return inverse

static func _multiply(a: Array, b: Array) -> Array:
	var result := []
	for row in 3:
		for col in 3:
			var value := 0.0
			for k in 3: value += float(a[row*3+k])*float(b[k*3+col])
			result.append(value)
	return result

static func matrix(page: String) -> Array:
	return _multiply(_quad(_points(TARGET)),_inverse(_quad(_points(SOURCES[page]))))

static func project(m: Array, p: Vector2) -> Vector2:
	var denominator: float = float(m[6])*p.x+float(m[7])*p.y+float(m[8])
	return Vector2(float(m[0])*p.x+float(m[1])*p.y+float(m[2]),float(m[3])*p.x+float(m[4])*p.y+float(m[5]))/denominator

static func reset(host: Control) -> void:
	for surface in host.find_children("*","Node2D",true,false):
		if not surface.get_meta("terminal_projection",false): continue
		var control := surface.get_child(0) as Control
		var parent := surface.get_parent()
		var index := surface.get_index()
		surface.remove_child(control)
		parent.add_child(control)
		parent.move_child(control,index)
		control.position = surface.get_meta("source_position")
		parent.remove_child(surface)
		surface.queue_free()

static func apply(host: Control, page: String) -> void:
	var art := host.find_child("DeviceChassis",true,false) as TextureRect
	var canvas := art.get_parent()
	var shell := host.find_child("TerminalShell",true,false) as TextureRect
	if shell == null:
		shell = SchoolObjectUI.art(canvas,"TerminalShell","res://assets/ui/student_terminal/layouts/overview.png")
		shell.stretch_mode = TextureRect.STRETCH_SCALE
		canvas.move_child(shell,0)
	var forward := matrix(page)
	var backward := _inverse(forward)
	var shader := ShaderMaterial.new()
	shader.shader = load("res://assets/ui/student_terminal/screen_projection.gdshader")
	shader.set_shader_parameter("source_x",Vector3(backward[0],backward[1],backward[2]))
	shader.set_shader_parameter("source_y",Vector3(backward[3],backward[4],backward[5]))
	shader.set_shader_parameter("source_w",Vector3(backward[6],backward[7],backward[8]))
	var target := _points(TARGET)
	for index in 4: shader.set_shader_parameter(["corner_a","corner_b","corner_c","corner_d"][index],target[index])
	_set_plates(shader,PLATES[page])
	art.material = shader
	var paper := host.find_child("SharedScreenPaper",true,false) as TextureRect
	if paper == null:
		paper = SchoolObjectUI.art(canvas,"SharedScreenPaper","res://assets/ui/student_terminal/screen_paper.png")
		paper.stretch_mode = TextureRect.STRETCH_SCALE
		canvas.move_child(paper,1)
	var paper_shader := _fixed_shader()
	_set_plates(paper_shader,[[0,0,1672,941]])
	paper.material = paper_shader
	var navigation := host.find_child("SharedNavigationPlate",true,false) as TextureRect
	if navigation == null:
		navigation = SchoolObjectUI.art(canvas,"SharedNavigationPlate","res://assets/ui/student_terminal/layouts/overview.png")
		navigation.stretch_mode = TextureRect.STRETCH_SCALE
		canvas.move_child(navigation,2)
	var nav_shader := _fixed_shader()
	_set_plates(nav_shader,[[135,190,222,578]])
	nav_shader.set_shader_parameter("erase_nav_frames",true)
	navigation.material = nav_shader
	var body := host.find_child("Page",true,false)
	for child in canvas.get_children():
		if child is Control and child not in [art,shell,body,paper,navigation] and child.visible:
			_surface(child,[1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0] if child.get_meta("terminal_fixed_chrome",false) else forward)
	for child in body.get_children():
		if child is Control and child.visible: _surface(child,forward)
	host.set_meta("terminal_device_source",shell.texture.resource_path)
	host.set_meta("terminal_screen_quad",target)

static func _surface(control: Control, m: Array) -> void:
	var parent := control.get_parent()
	var index := control.get_index()
	var source := control.position
	var origin := project(m,source)
	var right := project(m,source+Vector2(control.size.x,0))
	var bottom := project(m,source+Vector2(0,control.size.y))
	var surface := Node2D.new()
	surface.name = "ScreenSurface_"+str(control.name)
	surface.set_meta("terminal_projection",true)
	surface.set_meta("source_position",source)
	parent.remove_child(control)
	parent.add_child(surface)
	parent.move_child(surface,index)
	surface.add_child(control)
	control.position = Vector2.ZERO
	surface.transform = Transform2D((right-origin)/maxf(1.0,control.size.x),(bottom-origin)/maxf(1.0,control.size.y),origin)


static func _set_plates(material: ShaderMaterial, regions: Array) -> void:
	var rectangles := PackedVector4Array()
	for region in regions: rectangles.append(Vector4(region[0],region[1],region[2],region[3]))
	material.set_shader_parameter("plates",rectangles)
	material.set_shader_parameter("plate_count",regions.size())

static func _fixed_shader() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = load("res://assets/ui/student_terminal/screen_projection.gdshader")
	result.set_shader_parameter("source_x",Vector3(1,0,0))
	result.set_shader_parameter("source_y",Vector3(0,1,0))
	result.set_shader_parameter("source_w",Vector3(0,0,1))
	var points := _points(TARGET)
	for index in 4: result.set_shader_parameter(["corner_a","corner_b","corner_c","corner_d"][index],points[index])
	return result
