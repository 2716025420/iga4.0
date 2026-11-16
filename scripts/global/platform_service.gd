class_name PlatformService
extends Node

## Multi-platform viewport fitting, input-mode detection (PC vs Touch),
## cutout-safe rectangles, Android back handling, and zero-black-bar edge bleed.

signal input_mode_changed(touch_mode: bool)

const DESIGN := Vector2(1920.0, 1080.0)
const BLEED_SHADER_CODE := """shader_type canvas_item;
uniform vec4 tint = vec4(0.84, 0.80, 0.76, 1.0);
uniform float blur_radius = 0.012;
void fragment() {
	vec2 o = vec2(blur_radius, blur_radius * 1.4);
	vec4 sum = texture(TEXTURE, UV) * 0.28;
	sum += texture(TEXTURE, clamp(UV + vec2(o.x, 0.0), 0.002, 0.998)) * 0.18;
	sum += texture(TEXTURE, clamp(UV - vec2(o.x, 0.0), 0.002, 0.998)) * 0.18;
	sum += texture(TEXTURE, clamp(UV + vec2(0.0, o.y), 0.002, 0.998)) * 0.18;
	sum += texture(TEXTURE, clamp(UV - vec2(0.0, o.y), 0.002, 0.998)) * 0.18;
	vec3 dimmed = mix(sum.rgb, tint.rgb, 0.34);
	COLOR = vec4(dimmed, sum.a * tint.a);
}
"""

var touch_mode := false
var _bleed_shader: Shader

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	touch_mode = OS.get_name() in ["Android", "iOS"]
	# Headless dummy display has 0x0 window size, which expands 16:9 into a 1:1 1920x1920 canvas under EXPAND.
	if DisplayServer.get_name() == "headless" or DisplayServer.window_get_size() == Vector2i.ZERO:
		get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_set_touch_mode(true)
	elif event is InputEventKey and event.pressed and event.keycode != KEY_UNKNOWN:
		_set_touch_mode(false)
	elif (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device != -1:
		_set_touch_mode(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_dispatch_escape_back()

func _set_touch_mode(value: bool) -> void:
	if touch_mode == value:
		return
	touch_mode = value
	input_mode_changed.emit(touch_mode)

func _dispatch_escape_back() -> void:
	var pressed := InputEventKey.new()
	pressed.keycode = KEY_ESCAPE
	pressed.physical_keycode = KEY_ESCAPE
	pressed.pressed = true
	pressed.echo = false
	Input.parse_input_event(pressed)

func is_touch() -> bool:
	return touch_mode

func hint(pc_text: String, touch_text: String) -> String:
	return touch_text if touch_mode else pc_text

func safe_rect(viewport_size: Vector2 = Vector2.ZERO) -> Rect2:
	var extent := viewport_size
	if extent.x <= 0.0 or extent.y <= 0.0:
		extent = get_viewport().get_visible_rect().size
	if extent.x <= 0.0 or extent.y <= 0.0:
		extent = DESIGN
	var screen := Vector2(DisplayServer.window_get_size())
	var safe := DisplayServer.get_display_safe_area()
	if screen.x <= 0.0 or screen.y <= 0.0 or safe.size.x <= 0 or safe.size.y <= 0:
		return Rect2(Vector2.ZERO, extent)
	var scale_ratio := extent / screen
	var left := clampf(float(safe.position.x) * scale_ratio.x, 0.0, extent.x * 0.25)
	var top := clampf(float(safe.position.y) * scale_ratio.y, 0.0, extent.y * 0.25)
	var right := clampf(float(safe.end.x) * scale_ratio.x, left + 100.0, extent.x)
	var bottom := clampf(float(safe.end.y) * scale_ratio.y, top + 100.0, extent.y)
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))

func fit_stage(root: Control, stage: Control, edge_color: Color = Color("#EDE4D3"), edge_texture: Texture2D = null) -> void:
	if not is_instance_valid(root) or not is_instance_valid(stage):
		return
	var extent := root.size
	if extent.x <= 0.0 or extent.y <= 0.0:
		return
	var factor := minf(extent.x / DESIGN.x, extent.y / DESIGN.y)
	var stage_size := DESIGN * factor
	stage.scale = Vector2.ONE * factor
	stage.position = (extent - stage_size) / 2.0
	_sync_edge_bleed(root, stage, extent, stage_size, edge_color, edge_texture)

func fill_backdrop(root: Control, extent: Vector2, anchor: Control = null, edge_color: Color = Color("#EDE4D3"), edge_texture: Texture2D = null) -> void:
	if not is_instance_valid(root):
		return
	var factor := minf(extent.x / DESIGN.x, extent.y / DESIGN.y)
	var stage_size := DESIGN * factor
	var target := anchor if is_instance_valid(anchor) else (root.get_child(0) if root.get_child_count() > 0 else root)
	_sync_edge_bleed(root, target, extent, stage_size, edge_color, edge_texture)

func _sync_edge_bleed(root: Control, stage: Control, extent: Vector2, stage_size: Vector2, edge_color: Color, edge_texture: Texture2D) -> void:
	var needs_bleed := absf(extent.x - stage_size.x) > 2.0 or absf(extent.y - stage_size.y) > 2.0
	var bleed := root.get_node_or_null("_PlatformEdgeBleed") as Control
	if not needs_bleed:
		if is_instance_valid(bleed):
			bleed.visible = false
		return
	if not is_instance_valid(bleed):
		bleed = Control.new()
		bleed.name = "_PlatformEdgeBleed"
		bleed.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bleed.z_index = -100
		bleed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(bleed)
		var base := ColorRect.new()
		base.name = "Base"
		base.mouse_filter = Control.MOUSE_FILTER_IGNORE
		base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bleed.add_child(base)
		var cover := TextureRect.new()
		cover.name = "Cover"
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bleed.add_child(cover)
	bleed.z_index = -100
	var target_idx := stage.get_index() if stage != root and bleed.get_index() > stage.get_index() else maxi(0, (stage.get_index() - 1) if stage != root else 0)
	root.move_child(bleed, target_idx)
	bleed.visible = true
	var base_rect := bleed.get_node("Base") as ColorRect
	base_rect.color = edge_color
	base_rect.visible = edge_color.a > 0.001
	var cover_rect := bleed.get_node("Cover") as TextureRect
	cover_rect.texture = edge_texture
	cover_rect.visible = edge_texture != null
	if edge_texture != null:
		var mat := cover_rect.material as ShaderMaterial
		if mat == null:
			mat = ShaderMaterial.new()
			mat.shader = _get_bleed_shader()
			cover_rect.material = mat
		mat.set_shader_parameter("tint", Color(edge_color.r, edge_color.g, edge_color.b, 0.92))

func _get_bleed_shader() -> Shader:
	if _bleed_shader == null:
		_bleed_shader = Shader.new()
		_bleed_shader.code = BLEED_SHADER_CODE
	return _bleed_shader
