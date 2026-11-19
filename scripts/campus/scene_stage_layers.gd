class_name SceneStageLayers
extends Control

## 5-layer modular scene stage + realtime period lighting + optional 2340x1080 blueprint guide overlay.
## Layer 0: Shared Sky (day / dusk / redmoon)
## Layer 1: Clean Cel Midground Architecture & Path
## Layer 2: Dynamic Resident / Story Actors (Slot A + Slot B)
## Layer 3: Foreground Occluders (true alpha PNG or procedural geometry, hiding lower body naturally)
## Layer 4: Managed externally by SceneHUDLayout (dock, top-right bar, minimal NPC bubbles)

const DESIGN := Vector2(1920.0, 1080.0)
const WIDE_RECT := Rect2(-210.0, 0.0, 2340.0, 1080.0)
const WIDE_ORIGIN := Vector2(210.0, 0.0)
const WIDE_EXTEND_PAD := 180.0
const STAGED_ROOT := "res://assets/ui/scene_reset/staged/"
const WIDE_EXTEND_SHADER_CODE := """shader_type canvas_item;
uniform float pad_ratio = 0.06666667;
varying vec4 v_tint;
void vertex() {
	v_tint = COLOR;
}
void fragment() {
	float span = max(0.0001, 1.0 - 2.0 * pad_ratio);
	float mx = (UV.x - pad_ratio) / span;
	if (mx < 0.0) {
		mx = -mx;
	} else if (mx > 1.0) {
		mx = 2.0 - mx;
	}
	mx = clamp(mx, 0.0005, 0.9995);
	COLOR = texture(TEXTURE, vec2(mx, UV.y)) * v_tint;
}
"""
static var _wide_extend_shader: Shader

const SHARED_SKY_PATHS := {
	"day": STAGED_ROOT + "shared/sky_arete_day_wide.png",
	"dusk": STAGED_ROOT + "shared/sky_arete_dusk_wide.png",
	"redmoon": STAGED_ROOT + "shared/sky_arete_redmoon_wide.png"
}

const SCENE_BLUEPRINTS := {
	"rooftop": {
		"stage_key": "rooftop",
		"title": "教学楼天台",
		"indoor": false,
		"edge_day": "#98D2F2",
		"edge_dusk": "#E5A577",
		"edge_night": "#1B2846",
		"slot_a": {
			"mode": "standing",
			"rect": [930, 250, 310, 710],
			"bubble_anchor": [1085, 215],
			"label": "SLOT A · 时段轮驻同伴"
		},
		"slot_b": {
			"mode": "standing",
			"rect": [1360, 265, 300, 690],
			"bubble_anchor": [1510, 230],
			"label": "SLOT B · 谈心 / 主线事件位"
		},
		"occlusion_rects": [
			[1380, 770, 510, 310]
		],
		"occlusion_note": "前景原木遮阳桌边沿 + 天台近景花箱"
	},
	"shop": {
		"stage_key": "shop",
		"title": "校园商店",
		"indoor": true,
		"edge_day": "#EAE2D3",
		"edge_dusk": "#DECAB2",
		"edge_night": "#28334A",
		"slot_a": {
			"mode": "counter",
			"rect": [1155, 205, 495, 745],
			"bubble_anchor": [1402, 175],
			"label": "SLOT A · 唐小满（前景柜台遮挡腰部）"
		},
		"slot_b": {
			"mode": "standing",
			"rect": [600, 270, 310, 690],
			"bubble_anchor": [755, 240],
			"label": "SLOT B · 预留来访同学站位"
		},
		"occlusion_rects": [
			[0, 660, 1920, 420]
		],
		"occlusion_note": "全宽前景原木收银柜台 y=660..1080（实时遮挡店员下半身）"
	},
	"gym": {
		"stage_key": "gym",
		"title": "体育馆",
		"indoor": true,
		"edge_day": "#DCE8F2",
		"edge_dusk": "#D7C9BA",
		"edge_night": "#23304A",
		"slot_a": {
			"mode": "standing",
			"rect": [1240, 260, 310, 700],
			"bubble_anchor": [1395, 225],
			"label": "SLOT A · 柳宇龙（木地板地坪线）"
		},
		"slot_b": {
			"mode": "standing",
			"rect": [710, 285, 290, 650],
			"bubble_anchor": [855, 250],
			"label": "SLOT B · 选拔赛裁判 / 挑战对手位"
		},
		"occlusion_rects": [
			[1460, 760, 440, 320],
			[400, 865, 360, 215]
		],
		"occlusion_note": "右下整备长椅与卡匣箱 + 擂台前景低护栏"
	},
	"library": {
		"stage_key": "library",
		"title": "图书馆",
		"indoor": true,
		"edge_day": "#E4DFD4",
		"edge_dusk": "#DAC6B0",
		"edge_night": "#222E47",
		"slot_a": {
			"mode": "counter",
			"rect": [500, 240, 470, 705],
			"bubble_anchor": [735, 205],
			"label": "SLOT A · 林知夏（弧形借书台遮挡下身）"
		},
		"slot_b": {
			"mode": "counter",
			"rect": [1185, 255, 470, 705],
			"bubble_anchor": [1420, 218],
			"label": "SLOT B · 黄秋枫主线窗边书桌位"
		},
		"occlusion_rects": [
			[455, 670, 560, 410],
			[1150, 720, 540, 360]
		],
		"occlusion_note": "左中弧形木借书台 + 右中窗边双人自习桌"
	},
	"arete_coast_test": {
		"stage_key": "coast",
		"title": "阿瑞忒沿海公路",
		"indoor": false,
		"edge_day": "#8FD1F3",
		"edge_dusk": "#E5A073",
		"edge_night": "#1A2644",
		"slot_a": {
			"mode": "standing",
			"rect": [860, 275, 290, 665],
			"bubble_anchor": [1005, 240],
			"label": "SLOT A · 随行同伴散步位"
		},
		"slot_b": {
			"mode": "standing",
			"rect": [1250, 285, 285, 650],
			"bubble_anchor": [1392, 250],
			"label": "SLOT B · 偶遇 / 红月预警位"
		},
		"occlusion_rects": [
			[980, 795, 940, 285]
		],
		"occlusion_note": "右前白色海滨安全护栏 + 石阶栏杆"
	},
	"old_park": {
		"stage_key": "old_park",
		"title": "旧公园",
		"indoor": false,
		"edge_day": "#95D0EF",
		"edge_dusk": "#DF956A",
		"edge_night": "#1B243E",
		"slot_a": {
			"mode": "standing",
			"rect": [590, 280, 290, 660],
			"bubble_anchor": [735, 245],
			"label": "SLOT A · 自由态随行同伴位"
		},
		"slot_b": {
			"mode": "counter",
			"rect": [930, 240, 470, 705],
			"bubble_anchor": [1165, 205],
			"label": "SLOT B · 黄秋枫主线红枫长椅位"
		},
		"occlusion_rects": [
			[870, 725, 520, 355]
		],
		"occlusion_note": "中景红枫长椅靠背/扶手 + 近景红枫垂枝（右后街角设发光汽水贩卖机）"
	},
	"arete_beach_test": {
		"stage_key": "beach",
		"title": "阿瑞忒海滩",
		"indoor": false,
		"edge_day": "#8DD0F2",
		"edge_dusk": "#E59D72",
		"edge_night": "#192440",
		"slot_a": {
			"mode": "standing",
			"rect": [870, 275, 290, 665],
			"bubble_anchor": [1015, 240],
			"label": "SLOT A · 随行同伴栈桥位"
		},
		"slot_b": {
			"mode": "standing",
			"rect": [1310, 285, 285, 650],
			"bubble_anchor": [1452, 250],
			"label": "SLOT B · 主线海滨事件预留位"
		},
		"occlusion_rects": [
			[380, 790, 680, 290]
		],
		"occlusion_note": "前景木栈桥护栏柱与近景沙滩礁石"
	}
}

var location_id := ""
var blueprint: Dictionary = {}
var show_guides := false
var force_sky_mode := ""

var layer0_sky: Control
var layer1_midground: Control
var layer2_actors: Control
var layer3_foreground: Control
var blueprint_overlay: Control

var _sky_tex_rect: TextureRect
var _sky_canvas: _SkyBlueprintCanvas
var _midground_tex_rect: TextureRect
var _midground_canvas: _MidgroundBlueprintCanvas
var _foreground_tex_rect: TextureRect
var _foreground_canvas: _ForegroundBlueprintCanvas
var _guide_canvas: _BlueprintGuideCanvas

var _slots: Dictionary = {}


static func has_staged_blueprint(place_id: String) -> bool:
	return SCENE_BLUEPRINTS.has(place_id)


static func blueprint_for(place_id: String) -> Dictionary:
	if SCENE_BLUEPRINTS.has(place_id):
		return SCENE_BLUEPRINTS[place_id]
	return {}


static func actor_rect(place_id: String, slot_key: String) -> Rect2:
	if not SCENE_BLUEPRINTS.has(place_id):
		return Rect2(900, 250, 320, 720)
	var bp: Dictionary = SCENE_BLUEPRINTS[place_id]
	var slot_cfg: Dictionary = bp.get(slot_key, {})
	var arr: Array = slot_cfg.get("rect", [900, 250, 320, 720])
	return Rect2(float(arr[0]), float(arr[1]), float(arr[2]), float(arr[3]))


static func bubble_anchor(place_id: String, slot_key: String) -> Vector2:
	if not SCENE_BLUEPRINTS.has(place_id):
		return Vector2(1060, 220)
	var bp: Dictionary = SCENE_BLUEPRINTS[place_id]
	var slot_cfg: Dictionary = bp.get(slot_key, {})
	var arr: Array = slot_cfg.get("bubble_anchor", [1060, 220])
	return Vector2(float(arr[0]), float(arr[1]))


func configure(target_location_id: String, guides_visible: bool = false) -> void:
	location_id = target_location_id
	show_guides = guides_visible
	blueprint = SCENE_BLUEPRINTS.get(location_id, {}).duplicate(true)
	if is_inside_tree():
		_rebuild_layers()


func _ready() -> void:
	size = DESIGN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if blueprint.is_empty() and location_id != "":
		blueprint = SCENE_BLUEPRINTS.get(location_id, {}).duplicate(true)
	_rebuild_layers()


func _rebuild_layers() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_slots.clear()
	if blueprint.is_empty():
		return
	var stage_key := str(blueprint.get("stage_key", location_id))
	var indoor := bool(blueprint.get("indoor", false))

	# Layer 0: Shared Sky
	layer0_sky = Control.new()
	layer0_sky.name = "Layer0_Sky"
	layer0_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer0_sky)
	DaylightUI.place(layer0_sky, WIDE_RECT.position.x, WIDE_RECT.position.y, WIDE_RECT.size.x, WIDE_RECT.size.y)

	_sky_canvas = _SkyBlueprintCanvas.new()
	_sky_canvas.name = "SkyProcedural"
	_sky_canvas.indoor = indoor
	_sky_canvas.export_clip = show_guides
	layer0_sky.add_child(_sky_canvas)
	DaylightUI.place(_sky_canvas, 0.0, 0.0, WIDE_RECT.size.x, WIDE_RECT.size.y)

	_sky_tex_rect = TextureRect.new()
	_sky_tex_rect.name = "SkyTexture"
	_sky_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sky_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_sky_tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer0_sky.add_child(_sky_tex_rect)
	_place_wide_texture_rect(_sky_tex_rect)

	# Layer 1: Midground Architecture & Paths
	layer1_midground = Control.new()
	layer1_midground.name = "Layer1_Midground"
	layer1_midground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer1_midground)
	DaylightUI.place(layer1_midground, WIDE_RECT.position.x, WIDE_RECT.position.y, WIDE_RECT.size.x, WIDE_RECT.size.y)

	var mid_path := "%s%s/%s_midground_wide.png" % [STAGED_ROOT, stage_key, stage_key]
	if ResourceLoader.exists(mid_path):
		_midground_tex_rect = TextureRect.new()
		_midground_tex_rect.name = "MidgroundTexture"
		_midground_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_midground_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_midground_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_midground_tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_midground_tex_rect.texture = load(mid_path) as Texture2D
		layer1_midground.add_child(_midground_tex_rect)
		_place_wide_texture_rect(_midground_tex_rect)
	else:
		_midground_canvas = _MidgroundBlueprintCanvas.new()
		_midground_canvas.name = "MidgroundBlueprint"
		_midground_canvas.stage_key = stage_key
		_midground_canvas.export_clip = show_guides
		layer1_midground.add_child(_midground_canvas)
		DaylightUI.place(_midground_canvas, 0.0, 0.0, WIDE_RECT.size.x, WIDE_RECT.size.y)

	# Layer 2: Dynamic Resident / Story Actors (Slot A & Slot B)
	layer2_actors = Control.new()
	layer2_actors.name = "Layer2_Actors"
	layer2_actors.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer2_actors)
	DaylightUI.place(layer2_actors, 0.0, 0.0, DESIGN.x, DESIGN.y)

	# Layer 3: Foreground Occluders (above actors!)
	layer3_foreground = Control.new()
	layer3_foreground.name = "Layer3_Foreground"
	layer3_foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer3_foreground)
	DaylightUI.place(layer3_foreground, WIDE_RECT.position.x, WIDE_RECT.position.y, WIDE_RECT.size.x, WIDE_RECT.size.y)

	var fg_path := "%s%s/%s_foreground_wide.png" % [STAGED_ROOT, stage_key, stage_key]
	if ResourceLoader.exists(fg_path):
		_foreground_tex_rect = TextureRect.new()
		_foreground_tex_rect.name = "ForegroundTexture"
		_foreground_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_foreground_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_foreground_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_foreground_tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_foreground_tex_rect.texture = load(fg_path) as Texture2D
		layer3_foreground.add_child(_foreground_tex_rect)
		_place_wide_texture_rect(_foreground_tex_rect)
	else:
		_foreground_canvas = _ForegroundBlueprintCanvas.new()
		_foreground_canvas.name = "ForegroundBlueprint"
		_foreground_canvas.stage_key = stage_key
		_foreground_canvas.export_clip = show_guides
		layer3_foreground.add_child(_foreground_canvas)
		DaylightUI.place(_foreground_canvas, 0.0, 0.0, WIDE_RECT.size.x, WIDE_RECT.size.y)

	# Blueprint Guide Overlay (used by v13 blueprint exporter)
	blueprint_overlay = Control.new()
	blueprint_overlay.name = "BlueprintGuideOverlay"
	blueprint_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blueprint_overlay.visible = show_guides
	add_child(blueprint_overlay)
	DaylightUI.place(blueprint_overlay, WIDE_RECT.position.x, WIDE_RECT.position.y, WIDE_RECT.size.x, WIDE_RECT.size.y)

	_guide_canvas = _BlueprintGuideCanvas.new()
	_guide_canvas.name = "GuideDrawer"
	_guide_canvas.blueprint = blueprint
	blueprint_overlay.add_child(_guide_canvas)
	DaylightUI.place(_guide_canvas, 0.0, 0.0, WIDE_RECT.size.x, WIDE_RECT.size.y)

	apply_period_lighting()


func _place_wide_texture_rect(rect_node: TextureRect) -> void:
	if not is_instance_valid(rect_node):
		return
	if show_guides:
		rect_node.material = null
		DaylightUI.place(rect_node, 0.0, 0.0, WIDE_RECT.size.x, WIDE_RECT.size.y)
		return
	var total_w := WIDE_RECT.size.x + WIDE_EXTEND_PAD * 2.0
	DaylightUI.place(rect_node, -WIDE_EXTEND_PAD, 0.0, total_w, WIDE_RECT.size.y)
	if _wide_extend_shader == null:
		_wide_extend_shader = Shader.new()
		_wide_extend_shader.code = WIDE_EXTEND_SHADER_CODE
	var mat := rect_node.material as ShaderMaterial
	if mat == null or mat.shader != _wide_extend_shader:
		mat = ShaderMaterial.new()
		mat.shader = _wide_extend_shader
		rect_node.material = mat
	mat.set_shader_parameter("pad_ratio", WIDE_EXTEND_PAD / total_w)


func set_guides_visible(enabled: bool) -> void:
	show_guides = enabled
	if is_instance_valid(blueprint_overlay):
		blueprint_overlay.visible = enabled
	_place_wide_texture_rect(_sky_tex_rect)
	_place_wide_texture_rect(_midground_tex_rect)
	_place_wide_texture_rect(_foreground_tex_rect)
	if is_instance_valid(_sky_canvas):
		_sky_canvas.export_clip = enabled
		_sky_canvas.queue_redraw()
	if is_instance_valid(_midground_canvas):
		_midground_canvas.export_clip = enabled
		_midground_canvas.queue_redraw()
	if is_instance_valid(_foreground_canvas):
		_foreground_canvas.export_clip = enabled
		_foreground_canvas.queue_redraw()


func set_slot_actor(slot_key: String, texture_path: String, tooltip: String = "", callback: Callable = Callable()) -> TextureRect:
	if not is_instance_valid(layer2_actors) or not blueprint.has(slot_key):
		return null
	clear_slot(slot_key)
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		return null
	var slot_cfg: Dictionary = blueprint[slot_key]
	var rect := actor_rect(location_id, slot_key)
	var mode := str(slot_cfg.get("mode", "standing"))

	var holder := Control.new()
	holder.name = "ActorHolder_" + slot_key
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer2_actors.add_child(holder)
	DaylightUI.place(holder, rect.position.x, rect.position.y, rect.size.x, rect.size.y)

	if mode == "standing":
		DaylightUI.soft_ground_shadow(holder, "FootShadow", Vector2(rect.size.x * 0.5 - 102.0, rect.size.y - 28.0), Vector2(204.0, 30.0))

	var sprite := TextureRect.new()
	sprite.name = "ActorSprite_" + slot_key
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.texture = load(texture_path) as Texture2D
	holder.add_child(sprite)
	DaylightUI.place(sprite, 0.0, 0.0, rect.size.x, rect.size.y)

	var hit_btn: Button = null
	if callback.is_valid():
		hit_btn = Button.new()
		hit_btn.name = "ActorHit_" + slot_key
		hit_btn.flat = true
		hit_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		hit_btn.focus_mode = Control.FOCUS_NONE
		if tooltip != "":
			hit_btn.tooltip_text = tooltip
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			hit_btn.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		holder.add_child(hit_btn)
		DaylightUI.place(hit_btn, rect.size.x * 0.14, 16.0, rect.size.x * 0.72, rect.size.y * 0.62)
		hit_btn.pressed.connect(callback)

	_slots[slot_key] = {"holder": holder, "sprite": sprite, "hit": hit_btn}
	return sprite


func set_slot_texture(slot_key: String, texture_path: String) -> void:
	if not _slots.has(slot_key) or texture_path == "" or not ResourceLoader.exists(texture_path):
		return
	var entry: Dictionary = _slots[slot_key]
	var sprite := entry.get("sprite") as TextureRect
	if is_instance_valid(sprite):
		sprite.texture = load(texture_path) as Texture2D


func set_slot_hit_enabled(enabled: bool) -> void:
	for entry in _slots.values():
		var hit_btn := (entry as Dictionary).get("hit") as Button
		if is_instance_valid(hit_btn):
			hit_btn.disabled = not enabled
			hit_btn.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func clear_slot(slot_key: String) -> void:
	if not _slots.has(slot_key):
		return
	var entry: Dictionary = _slots[slot_key]
	var holder := entry.get("holder") as Control
	if is_instance_valid(holder):
		if holder.get_parent() != null:
			holder.get_parent().remove_child(holder)
		holder.queue_free()
	_slots.erase(slot_key)


func resolved_sky_mode(period_override: String = "", red_moon: bool = false) -> String:
	if force_sky_mode in ["day", "dusk", "redmoon"]:
		return force_sky_mode
	var p := period_override if period_override != "" else DayCycle.period()
	if red_moon or (p == "night" and _is_redmoon_phase()):
		return "redmoon"
	if p == "night":
		return "redmoon"
	if location_id == "old_park" and not bool(GameState.story_flags.get("chapter_1_completed", false)) and p != "morning":
		return "dusk"
	if p == "afternoon":
		return "dusk" if location_id == "old_park" else "day"
	return "day"


func _is_redmoon_phase() -> bool:
	var next_node: String = GameState.next_phase_two_node()
	if next_node in ["n_dusk", "n_guard", "n_rescue", "n_robot", "n5_boss"]:
		return true
	return false


func apply_period_lighting(period_override: String = "", red_moon: bool = false) -> void:
	if blueprint.is_empty():
		return
	var p := period_override if period_override != "" else DayCycle.period()
	var sky_mode := resolved_sky_mode(p, red_moon)
	var sky_path := str(SHARED_SKY_PATHS.get(sky_mode, ""))
	if is_instance_valid(_sky_tex_rect):
		if sky_path != "" and ResourceLoader.exists(sky_path):
			_sky_tex_rect.texture = load(sky_path) as Texture2D
			_sky_tex_rect.visible = true
			if is_instance_valid(_sky_canvas):
				_sky_canvas.visible = false
		else:
			_sky_tex_rect.visible = false
			if is_instance_valid(_sky_canvas):
				_sky_canvas.visible = true
				_sky_canvas.sky_mode = sky_mode
				_sky_canvas.queue_redraw()
	var indoor := bool(blueprint.get("indoor", false))
	var tint := Color.WHITE
	if sky_mode == "dusk":
		tint = Color(1.0, 0.94, 0.87) if indoor else Color(1.0, 0.90, 0.80)
	elif p == "afternoon" and not indoor:
		tint = Color(1.0, 0.97, 0.93)
	elif p == "night" or sky_mode == "redmoon":
		tint = Color(0.84, 0.86, 0.96) if indoor else Color(0.70, 0.72, 0.88)
	for layer in [layer1_midground, layer2_actors, layer3_foreground]:
		if is_instance_valid(layer):
			layer.modulate = tint
	if is_inside_tree() and get_tree().current_scene != null:
		var hud := get_tree().current_scene.find_child("SceneHUD", true, false)
		if is_instance_valid(hud) and hud.has_method("refresh_status"):
			hud.call("refresh_status")


func stage_edge_color() -> Color:
	if blueprint.is_empty():
		return Color("#DCEBF7")
	var p := DayCycle.period()
	if resolved_sky_mode(p) == "dusk":
		return Color(str(blueprint.get("edge_dusk", "#E5A577")))
	if p == "night":
		return Color(str(blueprint.get("edge_night", "#1E2B48")))
	return Color(str(blueprint.get("edge_day", "#A6D9F5")))


func primary_wide_texture() -> Texture2D:
	if is_instance_valid(_midground_tex_rect) and _midground_tex_rect.texture != null:
		return _midground_tex_rect.texture
	return null


class _SkyBlueprintCanvas:
	extends Control
	var sky_mode := "day"
	var indoor := false
	var export_clip := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var x0 := 0.0 if export_clip else -60.0
		var w := 2340.0 if export_clip else 2460.0
		var top_col := Color("#46B2F0")
		var mid_col := Color("#8ED7FB")
		var bot_col := Color("#E0F6FF")
		if sky_mode == "dusk":
			top_col = Color("#5A6EA8")
			mid_col = Color("#E89278")
			bot_col = Color("#FFE2AC")
		elif sky_mode == "redmoon":
			top_col = Color("#181E38")
			mid_col = Color("#342C52")
			bot_col = Color("#7A3E58")
		for i in 24:
			var t0 := float(i) / 24.0
			var t1 := float(i + 1) / 24.0
			var c := top_col.lerp(mid_col, t0 * 2.0) if t0 < 0.5 else mid_col.lerp(bot_col, (t0 - 0.5) * 2.0)
			draw_rect(Rect2(x0, t0 * 1080.0, w, (t1 - t0) * 1080.0 + 2.0), c)

		# Fluffy cel-shaded clouds (Blue Archive clear daylight signature)
		var cloud_fill := Color(1.0, 1.0, 1.0, 0.90) if sky_mode == "day" else (Color(1.0, 0.90, 0.80, 0.72) if sky_mode == "dusk" else Color(0.55, 0.36, 0.48, 0.45))
		var cloud_shade := Color(0.82, 0.93, 1.0, 0.65) if sky_mode == "day" else (Color(0.88, 0.65, 0.60, 0.55) if sky_mode == "dusk" else Color(0.32, 0.22, 0.38, 0.4))
		var clouds := [
			[380.0, 210.0, 1.15],
			[1090.0, 165.0, 1.35],
			[1820.0, 225.0, 1.1],
			[730.0, 310.0, 0.85],
			[1540.0, 295.0, 0.92]
		]
		for cl in clouds:
			var cx := float(cl[0])
			var cy := float(cl[1])
			var sc := float(cl[2])
			draw_circle(Vector2(cx - 56 * sc, cy + 16 * sc), 44 * sc, cloud_shade)
			draw_circle(Vector2(cx + 52 * sc, cy + 18 * sc), 40 * sc, cloud_shade)
			draw_circle(Vector2(cx, cy), 62 * sc, cloud_fill)
			draw_circle(Vector2(cx - 64 * sc, cy + 10 * sc), 44 * sc, cloud_fill)
			draw_circle(Vector2(cx + 60 * sc, cy + 12 * sc), 40 * sc, cloud_fill)
			draw_rect(Rect2(cx - 96 * sc, cy + 6 * sc, 192 * sc, 48 * sc), cloud_fill)

		if sky_mode == "redmoon" and not indoor:
			var moon_center := Vector2(1470.0, 200.0)
			draw_circle(moon_center, 118.0, Color(0.92, 0.32, 0.36, 0.18))
			draw_circle(moon_center, 74.0, Color(0.94, 0.38, 0.40, 0.34))
			draw_circle(moon_center, 46.0, Color("#F4B2B0"))
		elif sky_mode == "day" and not indoor:
			# Subtle Blue Archive style thin halo arcs in high sky
			draw_arc(Vector2(1580.0, 110.0), 210.0, 0.2, 2.7, 48, Color(1.0, 1.0, 1.0, 0.22), 2.0, true)
			draw_arc(Vector2(1580.0, 110.0), 140.0, 0.4, 2.9, 40, Color(1.0, 1.0, 1.0, 0.16), 1.5, true)


class _MidgroundBlueprintCanvas:
	extends Control
	var stage_key := ""
	var export_clip := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _wx(x: float) -> float:
		return SceneStageLayers.WIDE_ORIGIN.x + x

	func _wrect(x: float, y: float, w: float, h: float) -> Rect2:
		return Rect2(SceneStageLayers.WIDE_ORIGIN.x + x, y, w, h)

	func _fill_rect_bordered(rect: Rect2, fill: Color, border: Color, bw: float = 2.5) -> void:
		draw_rect(rect, fill)
		if bw > 0.0:
			draw_rect(rect, border, false, bw)

	func _draw() -> void:
		var line := Color("#5F718A")
		match stage_key:
			"rooftop":
				_draw_rooftop(line)
			"shop":
				_draw_shop(line)
			"gym":
				_draw_gym(line)
			"library":
				_draw_library(line)
			"coast":
				_draw_coast(line)
			"old_park":
				_draw_old_park(line)
			"beach":
				_draw_beach(line)

	func _draw_rooftop(line: Color) -> void:
		# Distant bright turquoise bay & white lighthouse
		draw_rect(Rect2(0.0, 480.0, 2340.0, 120.0), Color("#7BD0EC"))
		draw_line(Vector2(0.0, 480.0), Vector2(2340.0, 480.0), Color("#CBEFFF"), 3.0)
		# White lighthouse silhouette on right horizon
		_fill_rect_bordered(_wrect(1640, 395, 34, 88), Color("#F8FBFF"), Color("#7896B2"), 2.0)
		draw_polygon(PackedVector2Array([Vector2(_wx(1635), 395), Vector2(_wx(1679), 395), Vector2(_wx(1657), 368)]), PackedColorArray([Color("#D96B59")]))
		# Distant city islands
		_fill_rect_bordered(_wrect(1280, 442, 72, 40), Color("#D2E6F5"), Color("#8EB1CE"), 1.5)
		_fill_rect_bordered(_wrect(1365, 424, 58, 58), Color("#DCEBF7"), Color("#8EB1CE"), 1.5)
		# Clean rooftop floor tiles (pale cool ceramic white-blue)
		var floor_rect := Rect2(-40.0 if not export_clip else 0.0, 560.0, 2420.0 if not export_clip else 2340.0, 520.0)
		draw_rect(floor_rect, Color("#EDF2F7"))
		for i in 12:
			var y := 560.0 + float(i) * 44.0
			draw_line(Vector2(floor_rect.position.x, y), Vector2(floor_rect.end.x, y), Color("#D2DEE9"), 2.0)
		for i in 16:
			var bx := -100.0 + float(i) * 180.0
			draw_line(Vector2(_wx(bx), 560.0), Vector2(_wx(bx - 160.0 + float(i) * 20.0), 1080.0), Color("#D6E2EC"), 2.0)
		# Back railing + concrete parapet
		_fill_rect_bordered(Rect2(floor_rect.position.x, 512.0, floor_rect.size.x, 50.0), Color("#D8E4EE"), line, 2.0)
		for rx in range(-180, 2140, 96):
			draw_line(Vector2(_wx(rx), 418.0), Vector2(_wx(rx), 512.0), Color("#7A98B5"), 3.0)
		draw_line(Vector2(floor_rect.position.x, 418.0), Vector2(floor_rect.end.x, 418.0), Color("#6D8DAB"), 4.0)
		draw_line(Vector2(floor_rect.position.x, 464.0), Vector2(floor_rect.end.x, 464.0), Color("#8BAAC6"), 2.0)
		# Stairwell rooftop cabin on left-mid (clean cel block)
		_fill_rect_bordered(_wrect(395, 220, 315, 340), Color("#F2F6FA"), line, 2.5)
		_fill_rect_bordered(_wrect(382, 200, 340, 26), Color("#C9D9E8"), line, 2.5)
		_fill_rect_bordered(_wrect(455, 325, 118, 235), Color("#90A9C2"), line, 2.5)
		_fill_rect_bordered(_wrect(476, 354, 76, 72), Color("#CBE8FA"), line, 2.0)
		# Beverage vending machine next to stairwell
		_fill_rect_bordered(_wrect(725, 355, 118, 205), Color("#FFFFFF"), line, 2.5)
		_fill_rect_bordered(_wrect(742, 376, 84, 92), Color("#9BE0F8"), Color("#4B80A2"), 2.0)
		draw_rect(_wrect(742, 488, 84, 18), Color("#E67B65"), true)
		# Midground clean wooden bench near railing
		_fill_rect_bordered(_wrect(1180, 500, 230, 26), Color("#D9B288"), Color("#7E6249"), 2.0)
		_fill_rect_bordered(_wrect(1204, 526, 22, 42), Color("#8A9AB0"), line, 2.0)
		_fill_rect_bordered(_wrect(1364, 526, 22, 42), Color("#8A9AB0"), line, 2.0)

	func _draw_shop(line: Color) -> void:
		# Bright warm cream-white interior walls & soft mint-sky dado with real cutout window to Layer 0 Sky
		var base := Rect2(-40.0 if not export_clip else 0.0, 0.0, 2420.0 if not export_clip else 2340.0, 1080.0)
		var win_rect := _wrect(1225, 150, 610, 325)
		draw_rect(Rect2(base.position.x, 0.0, base.size.x, 96.0), Color("#59B3C4"))
		draw_rect(Rect2(base.position.x, 96.0, base.size.x, 12.0), Color("#E6EFF4"))
		draw_rect(Rect2(base.position.x, 108.0, base.size.x, win_rect.position.y - 108.0), Color("#FAF6EE"))
		draw_rect(Rect2(base.position.x, win_rect.position.y, win_rect.position.x - base.position.x, 650.0 - win_rect.position.y), Color("#FAF6EE"))
		draw_rect(Rect2(win_rect.end.x, win_rect.position.y, base.end.x - win_rect.end.x, 650.0 - win_rect.position.y), Color("#FAF6EE"))
		draw_rect(Rect2(win_rect.position.x, win_rect.end.y, win_rect.size.x, 650.0 - win_rect.end.y), Color("#FAF6EE"))
		# Left refrigerated beverage cooler & stationery shelves
		var bottle_colors: Array[Color] = [Color("#F3895D"), Color("#7CCDF0"), Color("#A7DB7A"), Color("#F5C368"), Color("#76B1E6")]
		_fill_rect_bordered(_wrect(390, 155, 290, 535), Color("#E4F4FB"), Color("#5696B0"), 2.5)
		for row in 4:
			var sy := 185.0 + float(row) * 112.0
			_fill_rect_bordered(_wrect(408, sy, 254, 92), Color("#CBEAF8"), Color("#7AB1C8"), 1.5)
			for col in 5:
				_fill_rect_bordered(_wrect(422 + col * 46, sy + 26, 30, 62), bottle_colors[col], Color("#56748A"), 1.5)
		# Center back card & supply display shelf + chalkboard menu
		var box_colors: Array[Color] = [Color("#7CBCE0"), Color("#E68D77"), Color("#93C49A"), Color("#EBD180")]
		_fill_rect_bordered(_wrect(725, 160, 445, 515), Color("#F0E4CF"), Color("#9B8064"), 2.5)
		_fill_rect_bordered(_wrect(765, 185, 365, 128), Color("#2E4D45"), Color("#9C7B56"), 4.0)
		draw_rect(_wrect(790, 210, 145, 22), Color("#FCECB4"))
		draw_rect(_wrect(790, 244, 290, 14), Color("#CFE6D8"))
		draw_rect(_wrect(790, 270, 240, 14), Color("#CFE6D8"))
		for srow in 3:
			var ry := 335.0 + float(srow) * 105.0
			_fill_rect_bordered(_wrect(748, ry, 398, 84), Color("#FFFBF2"), Color("#C3B298"), 1.5)
			for box_i in 4:
				_fill_rect_bordered(_wrect(770 + box_i * 92, ry + 14, 68, 62), box_colors[box_i], Color("#6D7484"), 1.5)
		# Right sunlit storefront cutout window + neatly stacked delivery boxes (work zone)
		draw_rect(win_rect, Color(0.84, 0.95, 1.0, 0.14))
		draw_rect(win_rect, Color("#6394AF"), false, 4.0)
		draw_line(Vector2(_wx(1530), 150.0), Vector2(_wx(1530), 475.0), Color("#6394AF"), 4.0)
		_fill_rect_bordered(_wrect(1640, 485, 185, 175), Color("#E2BC8E"), Color("#98734A"), 2.0)
		_fill_rect_bordered(_wrect(1670, 390, 130, 95), Color("#EAC99D"), Color("#98734A"), 2.0)
		# Shop floor behind counter
		draw_rect(Rect2(base.position.x, 650.0, base.size.x, 430.0), Color("#EFE6D5"))

	func _draw_gym(line: Color) -> void:
		var base := Rect2(-40.0 if not export_clip else 0.0, 0.0, 2420.0 if not export_clip else 2340.0, 1080.0)
		# Arched daylight clerestory windows showing sky above
		draw_rect(Rect2(base.position.x, 165.0, base.size.x, 420.0), Color("#F2F6FA"))
		for wx in range(380, 1940, 210):
			draw_rect(_wrect(wx, 24, 172, 132), Color("#FFFFFF", 0.22), false, 6.0)
		draw_rect(Rect2(base.position.x, 156.0, base.size.x, 18.0), Color("#C9D6E4"))
		# Warm wood paneling dado
		_fill_rect_bordered(Rect2(base.position.x, 452.0, base.size.x, 128.0), Color("#DEC3A0"), Color("#9E7D5A"), 2.0)
		# Clean sunlit maple court floor
		draw_rect(Rect2(base.position.x, 580.0, base.size.x, 500.0), Color("#F0D3A6"))
		for i in 9:
			var y := 580.0 + float(i) * 56.0
			draw_line(Vector2(base.position.x, y), Vector2(base.end.x, y), Color("#DFBD8C"), 2.0)
		# Central visual focal point: Arete Shield-Arbitration Qualifier Arena Ring + overhead banner
		_fill_rect_bordered(_wrect(580, 210, 560, 130), Color("#1E3557"), Color("#4BA6DF"), 3.0)
		draw_rect(_wrect(604, 228, 512, 34), Color("#2F6FB3"))
		draw_rect(_wrect(625, 276, 470, 44), Color("#142742"))
		draw_arc(Vector2(_wx(860), 755.0), 255.0, 0.0, TAU, 48, Color("#56C2F0", 0.85), 8.0, true)
		draw_arc(Vector2(_wx(860), 755.0), 215.0, 0.0, TAU, 48, Color("#FFFFFF", 0.72), 4.0, true)
		draw_rect(_wrect(610, 568, 500, 18), Color("#6EB3E0"))
		# Right training tactics whiteboard & equipment rack
		_fill_rect_bordered(_wrect(1470, 300, 285, 195), Color("#FFFFFF"), Color("#567494"), 3.0)
		draw_arc(Vector2(_wx(1555), 375.0), 28.0, 0.0, TAU, 32, Color("#4BA6DF"), 3.0, true)
		draw_line(Vector2(_wx(1585), 375.0), Vector2(_wx(1685), 425.0), Color("#D85B48"), 3.0)
		_fill_rect_bordered(_wrect(1785, 360, 110, 215), Color("#90B6D4"), line, 2.0)

	func _draw_library(line: Color) -> void:
		var base := Rect2(-40.0 if not export_clip else 0.0, 0.0, 2420.0 if not export_clip else 2340.0, 1080.0)
		var win_rect := _wrect(1095, 130, 540, 490)
		# Sunlit vaulted ceiling & wall cutout around ocean-view window so Layer 0 Sky shines through
		draw_rect(Rect2(base.position.x, 0.0, base.size.x, 130.0), Color("#E3D8C6"))
		draw_rect(Rect2(base.position.x, 118.0, base.size.x, 12.0), Color("#CFC2AE"))
		draw_rect(Rect2(base.position.x, 130.0, win_rect.position.x - base.position.x, 505.0), Color("#F6F1E6"))
		draw_rect(Rect2(win_rect.end.x, 130.0, base.end.x - win_rect.end.x, 505.0), Color("#F6F1E6"))
		draw_rect(Rect2(win_rect.position.x, win_rect.end.y, win_rect.size.x, 635.0 - win_rect.end.y), Color("#F6F1E6"))
		# Large ocean-view floor-to-ceiling window (Slot B Huang Qiufeng backdrop!)
		draw_rect(win_rect, Color(0.82, 0.94, 1.0, 0.14))
		draw_rect(win_rect, Color("#8B6F52"), false, 6.0)
		draw_line(Vector2(_wx(1365), 130.0), Vector2(_wx(1365), 620.0), Color("#8B6F52"), 5.0)
		draw_line(Vector2(_wx(1095), 365.0), Vector2(_wx(1635), 365.0), Color("#8B6F52"), 4.0)
		# Left service wall shelves behind Lin Zhixia
		var book_colors: Array[Color] = [Color("#719EB8"), Color("#C86D5B"), Color("#7EA684"), Color("#DFBD72")]
		_fill_rect_bordered(_wrect(440, 175, 465, 460), Color("#D4AF85"), Color("#8B6B4A"), 2.5)
		for row in 3:
			var sy := 205.0 + float(row) * 115.0
			_fill_rect_bordered(_wrect(462, sy, 420, 88), Color("#B88E63"), Color("#7B5B3E"), 1.5)
			for b in 9:
				_fill_rect_bordered(_wrect(476 + b * 43, sy + 14, 30, 68), book_colors[b % 4], Color("#554A42"), 1.0)
		# Right tall bookshelves & magazine chronicle stand
		_fill_rect_bordered(_wrect(1675, 175, 225, 480), Color("#C99E70"), Color("#866544"), 2.5)
		_fill_rect_bordered(_wrect(1665, 485, 220, 240), Color("#EDF2F7"), Color("#7B95AE"), 2.5)
		# Quiet green-cream library floor
		draw_rect(Rect2(base.position.x, 635.0, base.size.x, 445.0), Color("#DCE9DE"))
		draw_line(Vector2(base.position.x, 635.0), Vector2(base.end.x, 635.0), Color("#92B09C"), 3.0)

	func _draw_coast(line: Color) -> void:
		var base := Rect2(-40.0 if not export_clip else 0.0, 0.0, 2420.0 if not export_clip else 2340.0, 1080.0)
		# Clear turquoise sea on right & distant coast headland
		draw_rect(Rect2(base.position.x, 485.0, base.size.x, 225.0), Color("#59C4EA"))
		draw_line(Vector2(base.position.x, 485.0), Vector2(base.end.x, 485.0), Color("#D2F5FF"), 3.0)
		draw_polygon(PackedVector2Array([Vector2(_wx(1120), 485), Vector2(_wx(1520), 420), Vector2(_wx(1980), 455), Vector2(_wx(2150), 485)]), PackedColorArray([Color("#8CC3A4")]))
		# Clean seaside promenade & asphalt curve
		draw_polygon(PackedVector2Array([
			Vector2(base.position.x, 660),
			Vector2(_wx(1260), 615),
			Vector2(base.end.x, 690),
			Vector2(base.end.x, 1080),
			Vector2(base.position.x, 1080)
		]), PackedColorArray([Color("#E8E1D3")]))
		# Y-junction left fork: red-maple park arch leading to Old Park
		_fill_rect_bordered(_wrect(395, 260, 235, 395), Color("#F0E6D6"), Color("#87735B"), 2.5)
		draw_circle(Vector2(_wx(512), 295.0), 108.0, Color("#D96248", 0.88))
		draw_circle(Vector2(_wx(440), 335.0), 76.0, Color("#E87F58", 0.88))
		_fill_rect_bordered(_wrect(455, 385, 118, 265), Color("#6C8E75"), Color("#4B6753"), 2.0)
		# Wooden promenade deck bench (Slot A)
		_fill_rect_bordered(_wrect(760, 625, 265, 32), Color("#C99E72"), Color("#785C40"), 2.0)
		# Right white stone stairs descending to Arete Beach
		for step in 5:
			var sy := 645.0 + float(step) * 32.0
			_fill_rect_bordered(_wrect(1445 + step * 14, sy, 310 - step * 18, 28), Color("#F4F0E8"), Color("#99A5B2"), 2.0)
		# Signpost at Y-junction
		_fill_rect_bordered(_wrect(1335, 455, 18, 210), Color("#7A92AC"), line, 2.0)
		_fill_rect_bordered(_wrect(1210, 470, 145, 40), Color("#F6E7CA"), Color("#8D6D4A"), 2.0)
		_fill_rect_bordered(_wrect(1345, 520, 155, 40), Color("#D8F2FA"), Color("#4A85A6"), 2.0)

	func _draw_old_park(line: Color) -> void:
		var base := Rect2(-40.0 if not export_clip else 0.0, 0.0, 2420.0 if not export_clip else 2340.0, 1080.0)
		# Park stone terrace & autumn lawn
		draw_rect(Rect2(base.position.x, 520.0, base.size.x, 560.0), Color("#DCE2C2"))
		draw_polygon(PackedVector2Array([
			Vector2(_wx(360), 615), Vector2(_wx(1760), 615), Vector2(base.end.x, 1080), Vector2(base.position.x, 1080)
		]), PackedColorArray([Color("#EAE2D4")]))
		# Clean stylized autumn maple & ginkgo canopies (soft flat cel shapes, no muddy noise)
		var trees: Array = [[540.0, 260.0, 175.0, Color("#DE6E4B")], [760.0, 215.0, 155.0, Color("#ECA154")], [1190.0, 210.0, 175.0, Color("#D85B43")], [1420.0, 280.0, 145.0, Color("#E7934F")]]
		for tree_entry in trees:
			var tree: Array = tree_entry
			var canopy: Color = tree[3] as Color
			_fill_rect_bordered(_wrect(float(tree[0]) - 22.0, float(tree[1]) + 85.0, 44.0, 290.0), Color("#7D5D49"), Color("#5B4334"), 2.0)
			draw_circle(Vector2(_wx(float(tree[0])), float(tree[1])), float(tree[2]), canopy)
			draw_circle(Vector2(_wx(float(tree[0]) - 70.0), float(tree[1]) + 45.0), float(tree[2]) * 0.65, canopy.lightened(0.08))
		# Distant park iron fence
		draw_rect(Rect2(base.position.x, 505.0, base.size.x, 16.0), Color("#637587"))
		# Story-critical corner orange soda vending machine on the right!
		_fill_rect_bordered(_wrect(1525, 385, 185, 365), Color("#FFFFFF"), line, 3.0)
		_fill_rect_bordered(_wrect(1548, 412, 138, 175), Color("#FFE9BE"), Color("#D9873B"), 2.5)
		for r in 3:
			for c in 4:
				draw_rect(_wrect(1560 + c * 30, 428 + r * 52, 20, 34), Color("#F08B42") if (r + c) % 2 == 0 else Color("#7ECAE8"))
		draw_rect(_wrect(1548, 608, 138, 30), Color("#EE8B47"))
		_fill_rect_bordered(_wrect(1552, 658, 130, 42), Color("#4E5F73"), line, 2.0)

	func _draw_beach(line: Color) -> void:
		var base := Rect2(-40.0 if not export_clip else 0.0, 0.0, 2420.0 if not export_clip else 2340.0, 1080.0)
		# Clear ocean & crisp white seafoam wave line
		draw_rect(Rect2(base.position.x, 470.0, base.size.x, 210.0), Color("#4BBCE8"))
		draw_rect(Rect2(base.position.x, 625.0, base.size.x, 55.0), Color("#8AE0F7"))
		draw_line(Vector2(base.position.x, 470.0), Vector2(base.end.x, 470.0), Color("#D2F5FF"), 3.0)
		draw_line(Vector2(base.position.x, 678.0), Vector2(base.end.x, 678.0), Color("#FFFFFF"), 6.0)
		# Clean sunlit pale sand
		draw_rect(Rect2(base.position.x, 680.0, base.size.x, 400.0), Color("#F7E8CC"))
		# Left-mid wooden pier deck extending toward sea
		_fill_rect_bordered(_wrect(395, 625, 495, 195), Color("#D6B185"), Color("#866647"), 2.5)
		for px in range(425, 890, 62):
			draw_line(Vector2(_wx(px), 625.0), Vector2(_wx(px), 820.0), Color("#B48C62"), 2.0)
		# Right stone return breakwater steps back to Coast
		for s in 5:
			_fill_rect_bordered(_wrect(1560 + s * 22, 690.0 - s * 24.0, 260, 28), Color("#EDEAE2"), Color("#8E9CAB"), 2.0)


class _ForegroundBlueprintCanvas:
	extends Control
	var stage_key := ""
	var export_clip := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _wx(x: float) -> float:
		return SceneStageLayers.WIDE_ORIGIN.x + x

	func _wrect(x: float, y: float, w: float, h: float) -> Rect2:
		return Rect2(SceneStageLayers.WIDE_ORIGIN.x + x, y, w, h)

	func _fill_rect_bordered(rect: Rect2, fill: Color, border: Color, bw: float = 2.5) -> void:
		draw_rect(rect, fill)
		if bw > 0.0:
			draw_rect(rect, border, false, bw)

	func _draw() -> void:
		match stage_key:
			"shop":
				# Full-width warm wooden shop counter occluding Tang Xiaoman's waist & below
				var x0 := -40.0 if not export_clip else 0.0
				var w := 2420.0 if not export_clip else 2340.0
				_fill_rect_bordered(Rect2(x0, 660.0, w, 46.0), Color("#DFB98C"), Color("#846242"), 3.0)
				_fill_rect_bordered(Rect2(x0, 706.0, w, 374.0), Color("#F4ECE0"), Color("#A79279"), 3.0)
				_fill_rect_bordered(_wrect(1080, 760, 760, 260), Color("#C99E72"), Color("#826142"), 2.5)
				# Counter props: tablet POS on left-center, orange soda display bottle on right
				_fill_rect_bordered(_wrect(1010, 565, 118, 95), Color("#EBF3F9"), Color("#567794"), 2.5)
				_fill_rect_bordered(_wrect(1660, 575, 42, 85), Color("#F29248"), Color("#9B5825"), 2.0)
				_fill_rect_bordered(_wrect(1714, 595, 58, 65), Color("#F6CA6B"), Color("#967432"), 2.0)
			"library":
				# Left-center curved reception desk (occludes Lin Zhixia lower body)
				_fill_rect_bordered(_wrect(460, 670, 540, 40), Color("#DFBA8F"), Color("#826142"), 3.0)
				_fill_rect_bordered(_wrect(470, 710, 520, 370), Color("#B88E63"), Color("#7B5B3E"), 3.0)
				_fill_rect_bordered(_wrect(540, 635, 130, 35), Color("#F8F3E8"), Color("#8A7A68"), 2.0)
				# Right-center window study table (occludes Huang Qiufeng lower body)
				_fill_rect_bordered(_wrect(1155, 720, 525, 34), Color("#E3C298"), Color("#866444"), 3.0)
				_fill_rect_bordered(_wrect(1195, 754, 34, 326), Color("#947252"), Color("#6C5139"), 2.0)
				_fill_rect_bordered(_wrect(1610, 754, 34, 326), Color("#947252"), Color("#6C5139"), 2.0)
			"rooftop":
				# Clean foreground wooden terrace table edge on bottom-right
				_fill_rect_bordered(_wrect(1410, 790, 480, 36), Color("#D8AE82"), Color("#7E5D40"), 3.0)
				_fill_rect_bordered(_wrect(1465, 826, 36, 254), Color("#8B6E52"), Color("#624B36"), 2.0)
				_fill_rect_bordered(_wrect(1805, 826, 36, 254), Color("#8B6E52"), Color("#624B36"), 2.0)
			"gym":
				# Bottom-right prep bench with card cassette case + foreground barrier lip
				_fill_rect_bordered(_wrect(1485, 785, 390, 42), Color("#D6AC7C"), Color("#7E5E3E"), 3.0)
				_fill_rect_bordered(_wrect(1540, 827, 280, 253), Color("#6C86A2"), Color("#4B627A"), 2.5)
				_fill_rect_bordered(_wrect(1560, 730, 125, 55), Color("#2D4669"), Color("#5696C8"), 2.5)
			"coast":
				# Foreground coastal guardrail on bottom-right
				draw_line(Vector2(_wx(1040), 860.0), Vector2(_wx(2130), 805.0), Color("#FFFFFF"), 10.0)
				draw_line(Vector2(_wx(1040), 860.0), Vector2(_wx(2130), 805.0), Color("#6D8CA8"), 2.5)
				for rx in range(1120, 2060, 220):
					_fill_rect_bordered(_wrect(rx, 835, 18, 245), Color("#F0F6FA"), Color("#6D8CA8"), 2.0)
			"old_park":
				# Foreground maple park bench back & armrest occluding Slot B
				_fill_rect_bordered(_wrect(895, 730, 485, 32), Color("#C98356"), Color("#78492E"), 3.0)
				_fill_rect_bordered(_wrect(895, 772, 485, 36), Color("#B8744B"), Color("#78492E"), 3.0)
				_fill_rect_bordered(_wrect(885, 718, 34, 362), Color("#4E5E6E"), Color("#323E4B"), 2.5)
				_fill_rect_bordered(_wrect(1355, 718, 34, 362), Color("#4E5E6E"), Color("#323E4B"), 2.5)
			"beach":
				# Foreground wooden pier railing posts on bottom-left
				draw_line(Vector2(_wx(380), 815.0), Vector2(_wx(940), 855.0), Color("#CFA679"), 10.0)
				for rx in range(420, 920, 145):
					_fill_rect_bordered(_wrect(rx, 790, 24, 290), Color("#B88B5D"), Color("#745435"), 2.0)


class _BlueprintGuideCanvas:
	extends Control
	var blueprint: Dictionary = {}

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if blueprint.is_empty():
			return
		var font := DaylightUI.bold_font()
		var ox := SceneStageLayers.WIDE_ORIGIN.x
		# 1. Outer 2340x1080 wide bleed border (green)
		draw_rect(Rect2(1.0, 1.0, 2338.0, 1078.0), Color("#2D9A72"), false, 4.0)
		# 2. Central 1920x1080 16:9 safe zone (red)
		draw_rect(Rect2(ox, 2.0, 1920.0, 1076.0), Color("#D84A3A"), false, 4.0)
		# 3. Left HUD Dock exclusion zone (x: 0..356 in 1920 space, extending to -210)
		draw_rect(Rect2(2.0, 2.0, ox + 356.0, 1076.0), Color(0.18, 0.34, 0.62, 0.22), true)
		draw_rect(Rect2(2.0, 2.0, ox + 356.0, 1076.0), Color("#2C5EB2"), false, 3.0)
		draw_multiline_string(font, Vector2(ox + 26.0, 110.0), "LEFT HUD DOCK\n(程序渲染 行动栏)\n禁止放关键主体", HORIZONTAL_ALIGNMENT_LEFT, 310.0, 24, -1, Color("#183668"))
		# 4. Top-Right HUD exclusion zone
		var tr_rect := Rect2(ox + 1084.0, 24.0, 808.0, 68.0)
		draw_rect(tr_rect, Color(0.18, 0.34, 0.62, 0.22), true)
		draw_rect(tr_rect, Color("#2C5EB2"), false, 3.0)
		draw_string(font, Vector2(tr_rect.position.x + 16.0, 68.0), "TOP-RIGHT HUD（体力 / 练习点 / 零用钱 / 地图 / 菜单）", HORIZONTAL_ALIGNMENT_LEFT, 780.0, 20, Color("#183668"))
		# 5. Bottom hint strip exclusion zone
		var bot_rect := Rect2(ox + 384.0, 1016.0, 1500.0, 44.0)
		draw_rect(bot_rect, Color(0.18, 0.34, 0.62, 0.18), true)
		draw_rect(bot_rect, Color("#2C5EB2"), false, 2.0)
		# 6. Slot A & Slot B boxes
		for slot_key in ["slot_a", "slot_b"]:
			if not blueprint.has(slot_key):
				continue
			var cfg: Dictionary = blueprint[slot_key]
			var arr: Array = cfg.get("rect", [0, 0, 100, 100])
			var r := Rect2(ox + float(arr[0]), float(arr[1]), float(arr[2]), float(arr[3]))
			var col := Color("#128C72") if slot_key == "slot_a" else Color("#D85540")
			draw_rect(r, Color(col, 0.12), true)
			draw_rect(r, col, false, 3.5)
			draw_string(font, Vector2(r.position.x + 8.0, r.position.y - 10.0), str(cfg.get("label", slot_key)), HORIZONTAL_ALIGNMENT_LEFT, 520.0, 20, col)
		# 7. Layer 3 Foreground occlusion markers
		for raw_occ in blueprint.get("occlusion_rects", []):
			var occ: Array = raw_occ
			var orr := Rect2(ox + float(occ[0]), float(occ[1]), float(occ[2]), float(occ[3]))
			draw_rect(orr, Color(0.76, 0.42, 0.14, 0.14), true)
			draw_rect(orr, Color("#C6651A"), false, 3.0)
		# 8. Header title tag inside safe stage
		var header_bg := Rect2(ox + 384.0, 24.0, 670.0, 68.0)
		draw_rect(header_bg, Color(1.0, 0.98, 0.92, 0.92), true)
		draw_rect(header_bg, Color("#D84A3A"), false, 2.5)
		draw_string(font, Vector2(header_bg.position.x + 18.0, 66.0), "BLUEPRINT 2340x1080 · %s (%s)" % [str(blueprint.get("title", "")), str(blueprint.get("stage_key", ""))], HORIZONTAL_ALIGNMENT_LEFT, 640.0, 22, Color("#202D44"))
