class_name DynamicUI
extends RefCounted

## Shared lightweight UI styling and animation helpers (all respect reduced_motion & borderless focus).

const V14_DIR := "res://assets/ui_core/v14_ui/"
const THEME_PAPER_MODAL := "res://assets/ui_core/theme/paper_modal_9slice.png"
const THEME_PAPER_CHOICE := "res://assets/ui_core/theme/dialogue_choice_9slice.png"
const THEME_PAPER_CARD := "res://assets/ui_core/theme/ui_tutorial_callout_9slice.png"
const THEME_FABRIC_RIBBON := "res://assets/ui_core/theme/ribbon_header_9slice.png"

const V14_EXPAND_HALOS := {
	"dialogue_choice_9slice": Vector4(14, 17, 14, 14),
	"paper_modal_9slice": Vector4(17, 18, 17, 17),
	"ribbon_header_9slice": Vector4(15, 18, 16, 19),
	"ui_tutorial_callout_9slice": Vector4(8, 14, 10, 17),
	"ui_clerk_speech_bubble_9slice": Vector4(12, 14, 12, 17),
}

const V14_CAPSULE_KEYS: Array[String] = []

const V14_DEFAULT_HEIGHTS := {
	"dialogue_choice_9slice": 60.0,
	"ribbon_header_9slice": 46.0,
	"ui_tutorial_callout_9slice": 64.0,
	"ui_clerk_speech_bubble_9slice": 114.0,
}

static var _scaled_tex_cache: Dictionary = {}

static func make_paper_tag(fill: Color, border: Color, corner_radius: int = 6, pad_h: float = 8.0, pad_v: float = 2.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(corner_radius)
	box.shadow_color = Color(0.20, 0.22, 0.28, 0.14)
	box.shadow_size = 2
	box.shadow_offset = Vector2(0, 1)
	box.content_margin_left = pad_h
	box.content_margin_right = pad_h
	box.content_margin_top = pad_v
	box.content_margin_bottom = pad_v
	return box

static func v14_texture(rel_path: String) -> Texture2D:
	var full_path := rel_path if rel_path.begins_with("res://") else (V14_DIR + rel_path)
	if not ResourceLoader.exists(full_path):
		return null
	return load(full_path) as Texture2D

static func nine_slice_box(rel_path: String, margins: Vector4, content_pad: Vector4 = Vector4(-1, -1, -1, -1), modulate_col: Color = Color.WHITE, expand_margins: Vector4 = Vector4(-1, -1, -1, -1), target_height: float = -1.0) -> StyleBoxTexture:
	var tex := v14_texture(rel_path)
	if tex == null:
		return null
	var base_key := rel_path.get_file().get_basename()
	var resolved_expand := expand_margins
	if resolved_expand.x < 0.0 and V14_EXPAND_HALOS.has(base_key):
		resolved_expand = V14_EXPAND_HALOS[base_key]
	var eff_target_h := target_height
	if eff_target_h <= 8.0 and V14_DEFAULT_HEIGHTS.has(base_key):
		eff_target_h = float(V14_DEFAULT_HEIGHTS[base_key])
	var src_w := float(tex.get_width())
	var src_h := float(tex.get_height())
	var halo := resolved_expand if resolved_expand.x >= 0.0 else Vector4.ZERO
	var opaque_src_h := maxf(16.0, src_h - halo.y - halo.w)
	var eff_scale := 1.0
	if eff_target_h > 8.0 and eff_target_h < opaque_src_h - 2.0 and V14_DEFAULT_HEIGHTS.has(base_key):
		var q_h := maxi(16, int(round(eff_target_h / 2.0)) * 2)
		var scale := float(q_h) / opaque_src_h
		var cache_key := "%s@%d" % [base_key, q_h]
		if not _scaled_tex_cache.has(cache_key):
			var img := tex.get_image()
			if img != null and not img.is_empty():
				var copy_img := img.duplicate() as Image
				if copy_img.is_compressed():
					copy_img.decompress()
				var new_w := maxi(16, int(round(src_w * scale)))
				var new_h := maxi(16, int(round(src_h * scale)))
				copy_img.resize(new_w, new_h, Image.INTERPOLATE_CUBIC)
				_scaled_tex_cache[cache_key] = ImageTexture.create_from_image(copy_img)
		if _scaled_tex_cache.has(cache_key):
			tex = _scaled_tex_cache[cache_key]
			eff_scale = scale
	var box := StyleBoxTexture.new()
	box.texture = tex
	if base_key in V14_CAPSULE_KEYS:
		var cap_src := 32.0 if src_h <= 72.0 else 64.0
		var cap_scaled := roundf(cap_src * eff_scale)
		box.texture_margin_left = cap_scaled
		box.texture_margin_right = cap_scaled
		box.texture_margin_top = 0.0
		box.texture_margin_bottom = 0.0
	else:
		box.texture_margin_left = roundf(margins.x * eff_scale)
		box.texture_margin_top = roundf(margins.y * eff_scale)
		box.texture_margin_right = roundf(margins.z * eff_scale)
		box.texture_margin_bottom = roundf(margins.w * eff_scale)
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.modulate_color = modulate_col
	if resolved_expand.x >= 0.0:
		box.expand_margin_left = roundf(resolved_expand.x * eff_scale)
		box.expand_margin_top = roundf(resolved_expand.y * eff_scale)
		box.expand_margin_right = roundf(resolved_expand.z * eff_scale)
		box.expand_margin_bottom = roundf(resolved_expand.w * eff_scale)
	if content_pad.x >= 0.0:
		box.content_margin_left = content_pad.x
		box.content_margin_top = content_pad.y
		box.content_margin_right = content_pad.z
		box.content_margin_bottom = content_pad.w
	return box

static func apply_nine_slice_panel(panel: Control, rel_path: String, margins: Vector4, modulate_col: Color = Color.WHITE, content_pad: Vector4 = Vector4(-1, -1, -1, -1)) -> bool:
	if not is_instance_valid(panel):
		return false
	var target_h := maxf(panel.size.y, panel.custom_minimum_size.y)
	var box := nine_slice_box(rel_path, margins, content_pad, modulate_col, Vector4(-1, -1, -1, -1), target_h)
	if box == null:
		return false
	panel.add_theme_stylebox_override("panel", box)
	return true

static func attach_leading_icon(host: Control, node_name: String, rel_path: String, rect: Rect2, modulate_col: Color = Color.WHITE) -> TextureRect:
	if not is_instance_valid(host):
		return null
	var tex := v14_texture(rel_path)
	if tex == null:
		return null
	var icon := host.get_node_or_null(node_name) as TextureRect
	if icon == null:
		icon = TextureRect.new()
		icon.name = node_name
		host.add_child(icon)
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = modulate_col
	DaylightUI.place(icon, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	return icon

class _BobDriver:
	extends Node
	var target: Control
	var base_y: float = 0.0
	var amp: float = 4.0
	var speed: float = 2.6
	var _phase: float = 0.0
	func _ready() -> void:
		if is_instance_valid(target):
			base_y = target.position.y
	func _process(delta: float) -> void:
		if not is_instance_valid(target): return
		if bool(SaveManager.settings.get("reduced_motion", false)):
			target.position.y = base_y
			return
		_phase += delta * speed
		target.position.y = base_y + sin(_phase) * amp

class _PulseRingControl:
	extends Control
	var ring_color := Color("#3B9ED8")
	var max_r := 30.0
	var _t := 0.0
	func _process(delta: float) -> void:
		if bool(SaveManager.settings.get("reduced_motion", false)):
			if _t != 0.5:
				_t = 0.5
				queue_redraw()
			return
		_t = fmod(_t + delta * 0.72, 1.0)
		queue_redraw()
	func _draw() -> void:
		var c := size * 0.5
		if bool(SaveManager.settings.get("reduced_motion", false)):
			draw_arc(c, max_r * 0.68, 0.0, TAU, 40, Color(ring_color, 0.55), 2.5, true)
			return
		for i in 2:
			var p := fmod(_t + i * 0.5, 1.0)
			var r := lerpf(max_r * 0.28, max_r, p)
			var a := (1.0 - p) * (1.0 - p) * 0.78
			draw_arc(c, r, 0.0, TAU, 44, Color(ring_color, a), 3.0 - p * 1.4, true)

const _SHEEN_SHADER := """shader_type canvas_item;
uniform float reduced = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.34);
void fragment() {
 if (reduced > 0.5) {
  COLOR = vec4(0.0);
 } else {
  float cycle = fract(TIME * 0.28);
  float sweep = mix(-0.55, 1.65, clamp(cycle * 2.2, 0.0, 1.0));
  float diag = UV.x * 0.85 + UV.y * 0.28;
  float band = smoothstep(sweep - 0.16, sweep, diag) * (1.0 - smoothstep(sweep, sweep + 0.16, diag));
  float active = step(cycle, 0.45);
  COLOR = vec4(tint.rgb, tint.a * band * active);
 }
}
"""

static func attach_hover_pop(control: Control, scale_factor: float = 1.045) -> void:
	if not is_instance_valid(control): return
	control.pivot_offset = control.size * 0.5
	control.resized.connect(func():
		if is_instance_valid(control): control.pivot_offset = control.size * 0.5
	)
	var animate := func(target_scale: float, dur: float):
		if not is_instance_valid(control): return
		control.pivot_offset = control.size * 0.5
		if bool(SaveManager.settings.get("reduced_motion", false)):
			control.scale = Vector2.ONE
			return
		if control.has_meta("_dyn_pop_tw"):
			var old_tw: Tween = control.get_meta("_dyn_pop_tw")
			if is_instance_valid(old_tw): old_tw.kill()
		var tw := control.create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(control, "scale", Vector2.ONE * target_scale, dur)
		control.set_meta("_dyn_pop_tw", tw)
	var hovered := false
	control.mouse_entered.connect(func():
		hovered = true
		animate.call(scale_factor, 0.14)
	)
	control.mouse_exited.connect(func():
		hovered = false
		animate.call(1.0, 0.14)
	)
	control.focus_entered.connect(func(): animate.call(scale_factor, 0.14))
	control.focus_exited.connect(func():
		if not hovered: animate.call(1.0, 0.14)
	)
	if control is BaseButton:
		var btn := control as BaseButton
		btn.button_down.connect(func():
			if not btn.disabled: animate.call(0.965, 0.08)
		)
		btn.button_up.connect(func():
			animate.call(scale_factor if hovered else 1.0, 0.12)
		)

static func attach_float_bob(control: Control, amp: float = 4.5, speed: float = 2.6) -> void:
	if not is_instance_valid(control): return
	var driver := _BobDriver.new()
	driver.name = "BobDriver"
	driver.target = control
	driver.amp = amp
	driver.speed = speed
	control.add_child(driver)

static func create_pulse_ring(parent: Control, node_name: String, center: Vector2, max_radius: float, color: Color) -> Control:
	var ring := _PulseRingControl.new()
	ring.name = node_name
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.ring_color = color
	ring.max_r = max_radius
	var side := (max_radius + 8.0) * 2.0
	parent.add_child(ring)
	DaylightUI.place(ring, center.x - side * 0.5, center.y - side * 0.5, side, side)
	return ring

static func attach_sheen(control: Control, tint: Color = Color(1, 1, 1, 0.34), corner_radius: int = 12) -> void:
	if not is_instance_valid(control): return
	control.clip_contents = true
	var sheen := Panel.new()
	sheen.name = "SheenOverlay"
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := StyleBoxFlat.new()
	box.bg_color = Color.WHITE
	box.set_corner_radius_all(corner_radius)
	sheen.add_theme_stylebox_override("panel", box)
	var sh := Shader.new()
	sh.code = _SHEEN_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("reduced", 1.0 if bool(SaveManager.settings.get("reduced_motion", false)) else 0.0)
	mat.set_shader_parameter("tint", tint)
	sheen.material = mat
	control.add_child(sheen)

static func slide_in(control: Control, offset: Vector2, duration: float = 0.24, delay: float = 0.0) -> void:
	if not is_instance_valid(control) or bool(SaveManager.settings.get("reduced_motion", false)): return
	var dest := control.position
	control.position = dest + offset
	control.modulate.a = 0.0
	var tw := control.create_tween()
	if delay > 0.0: tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(control, "position", dest, duration)
	tw.tween_property(control, "modulate:a", 1.0, duration)

static func make_cel_button(button: Button, fill: Color, ink: Color, accent: Color, font_size: int = 23, corner_radius: int = 14) -> void:
	if not is_instance_valid(button): return
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_font_override("font", DaylightUI.bold_font())
	var used_paper := false
	var is_primary := fill.r > 0.72 and fill.g < 0.48 and fill.b < 0.48
	var is_teal := fill.g > 0.50 and fill.r < 0.35
	var is_back := button.name in ["BackLocation", "OpenMap", "OpenMenu", "CloseButton", "ReturnToPlace", "BackToLocal", "MainMenuButton", "BackToOverview"] or fill.b > fill.r + 0.015
	var is_dark := fill.get_luminance() < 0.35
	var tex_rel := THEME_PAPER_CHOICE
	var margins := Vector4(84, 34, 28, 28)
	var normal_mod := Color(1.0, 0.99, 0.97, 1.0)
	var hover_mod := Color(0.95, 0.91, 0.84, 1.0)
	var pressed_mod := Color(0.89, 0.84, 0.76, 1.0)
	var disabled_mod := Color(0.88, 0.86, 0.82, 0.62)
	var resolved_ink := ink
	if is_primary:
		tex_rel = THEME_PAPER_CARD
		margins = Vector4(44, 36, 32, 32)
		normal_mod = Color(0.84, 0.40, 0.33, 1.0)
		hover_mod = Color(0.90, 0.45, 0.37, 1.0)
		pressed_mod = Color(0.74, 0.33, 0.27, 1.0)
		disabled_mod = Color(0.84, 0.80, 0.75, 0.65)
		resolved_ink = Color("#FFFBF2")
	elif is_teal:
		tex_rel = THEME_PAPER_CARD
		margins = Vector4(44, 36, 32, 32)
		normal_mod = Color(0.25, 0.56, 0.49, 1.0)
		hover_mod = Color(0.30, 0.62, 0.54, 1.0)
		pressed_mod = Color(0.20, 0.48, 0.42, 1.0)
		disabled_mod = Color(0.76, 0.82, 0.80, 0.68)
		resolved_ink = Color("#FFFBF2")
	elif is_back:
		tex_rel = THEME_PAPER_CARD
		margins = Vector4(44, 36, 32, 32)
		if is_dark:
			normal_mod = Color(0.26, 0.32, 0.45, 0.96)
			hover_mod = Color(0.32, 0.39, 0.54, 0.98)
			pressed_mod = Color(0.20, 0.25, 0.37, 0.98)
			disabled_mod = Color(0.24, 0.28, 0.38, 0.58)
		else:
			normal_mod = Color(0.96, 0.98, 1.0, 1.0)
			hover_mod = Color(0.90, 0.94, 0.98, 1.0)
			pressed_mod = Color(0.84, 0.89, 0.95, 1.0)
			disabled_mod = Color(0.86, 0.88, 0.91, 0.60)
	elif is_dark:
		normal_mod = Color(0.25, 0.30, 0.42, 0.96)
		hover_mod = Color(0.31, 0.38, 0.52, 0.98)
		pressed_mod = Color(0.20, 0.24, 0.35, 0.98)
		disabled_mod = Color(0.22, 0.26, 0.36, 0.58)
	var pad := Vector4(24, 6, 18, 8) if tex_rel == THEME_PAPER_CHOICE else Vector4(18, 6, 18, 8)
	var btn_h := maxf(button.size.y, button.custom_minimum_size.y)
	var nbox := nine_slice_box(tex_rel, margins, pad, normal_mod, Vector4(-1, -1, -1, -1), btn_h)
	if nbox != null:
		used_paper = true
		var hbox := nine_slice_box(tex_rel, margins, pad, hover_mod, Vector4(-1, -1, -1, -1), btn_h)
		var pbox := nine_slice_box(tex_rel, margins, pad, pressed_mod, Vector4(-1, -1, -1, -1), btn_h)
		var dbox := nine_slice_box(tex_rel, margins, pad, disabled_mod, Vector4(-1, -1, -1, -1), btn_h)
		button.add_theme_stylebox_override("normal", nbox)
		button.add_theme_stylebox_override("focus", nbox)
		button.add_theme_stylebox_override("hover", hbox if hbox != null else nbox)
		button.add_theme_stylebox_override("pressed", pbox if pbox != null else nbox)
		button.add_theme_stylebox_override("hover_pressed", pbox if pbox != null else nbox)
		button.add_theme_stylebox_override("disabled", dbox if dbox != null else nbox)
	if not used_paper:
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var box := StyleBoxFlat.new()
			box.set_corner_radius_all(mini(corner_radius, 8))
			box.content_margin_left = 14
			box.content_margin_right = 14
			if state == "normal":
				box.bg_color = fill
				box.border_color = Color(accent, 0.72)
				box.set_border_width_all(1)
				box.border_width_bottom = 3
				box.shadow_color = Color(0.18, 0.20, 0.26, 0.14)
				box.shadow_size = 3
				box.shadow_offset = Vector2(0, 2)
			elif state == "hover":
				box.bg_color = fill.darkened(0.05) if fill.get_luminance() > 0.5 else fill.lightened(0.08)
				box.border_color = accent
				box.set_border_width_all(2)
				box.border_width_bottom = 3
			elif state in ["pressed", "hover_pressed"]:
				box.bg_color = fill.darkened(0.10)
				box.border_color = accent
				box.set_border_width_all(1)
			else:
				box.bg_color = Color(fill, fill.a * 0.60)
				box.border_color = Color(accent, 0.35)
				box.set_border_width_all(1)
			button.add_theme_stylebox_override(state, box)
	for col_key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(col_key, resolved_ink)
	button.add_theme_color_override("font_disabled_color", Color(resolved_ink, 0.55))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	SchoolObjectUI.borderless(button)
	attach_hover_pop(button, 1.025)

static func apply_world_card_style(button: Button, mode: String) -> void:
	var fill := Color("#FFFFFF", 0.97)
	var ink := Color("#15253D")
	var accent := Color("#368BD2")
	var card_mod := Color(1.0, 0.99, 0.96, 1.0)
	var hover_mod := Color(0.95, 0.97, 1.0, 1.0)
	if mode == "next":
		fill = Color("#FFF9ED", 0.97)
		ink = Color("#3D2812")
		accent = Color("#E5953B")
		card_mod = Color(1.0, 0.94, 0.83, 1.0)
		hover_mod = Color(1.0, 0.90, 0.76, 1.0)
	elif mode == "locked":
		fill = Color("#EFF4FB", 0.92)
		ink = Color("#4B5F7A")
		accent = Color("#8BA0BD")
		card_mod = Color(0.88, 0.91, 0.95, 0.88)
		hover_mod = Color(0.88, 0.91, 0.95, 0.88)
	make_cel_button(button, fill, ink, accent, 22, 8)
	var pad := Vector4(18, 6, 18, 8)
	var margins := Vector4(44, 36, 32, 32)
	var card_h := maxf(button.size.y, button.custom_minimum_size.y)
	var nbox := nine_slice_box(THEME_PAPER_CARD, margins, pad, card_mod, Vector4(-1, -1, -1, -1), card_h)
	if nbox != null:
		var hbox := nine_slice_box(THEME_PAPER_CARD, margins, pad, hover_mod, Vector4(-1, -1, -1, -1), card_h)
		var pbox := nine_slice_box(THEME_PAPER_CARD, margins, pad, card_mod.darkened(0.08), Vector4(-1, -1, -1, -1), card_h)
		var dbox := nine_slice_box(THEME_PAPER_CARD, margins, pad, Color(card_mod.r, card_mod.g, card_mod.b, 0.72), Vector4(-1, -1, -1, -1), card_h)
		button.add_theme_stylebox_override("normal", nbox)
		button.add_theme_stylebox_override("focus", nbox)
		button.add_theme_stylebox_override("hover", hbox if hbox != null else nbox)
		button.add_theme_stylebox_override("pressed", pbox if pbox != null else nbox)
		button.add_theme_stylebox_override("hover_pressed", pbox if pbox != null else nbox)
		button.add_theme_stylebox_override("disabled", dbox if dbox != null else nbox)
