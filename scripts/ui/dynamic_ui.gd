class_name DynamicUI
extends RefCounted

## Shared lightweight UI styling and animation helpers (all respect reduced_motion & borderless focus).

const V14_DIR := "res://assets/ui_core/v14_ui/"
const V17_UI_A_DIR := "res://assets/ui_core/v17_ui_a/"
const V17_DIAL_MORNING := V17_UI_A_DIR + "dials/ui_dial_morning.png"
const V17_DIAL_REDMOON := V17_UI_A_DIR + "dials/ui_dial_redmoon.png"
const V17_DOCK_STRIP := V17_UI_A_DIR + "panels/ui_hud_dock_strip_9slice.png"
const V17_RESOURCE_CAPSULE := V17_UI_A_DIR + "panels/ui_hud_resource_capsule_9slice.png"
const V17_ACTION_BTN := V17_UI_A_DIR + "buttons/ui_btn_cel_normal_9slice.png"
const V17_NPC_BUBBLE := V17_UI_A_DIR + "panels/ui_npc_bubble_9slice.png"
const V17_STORY_DIALOGUE := V17_UI_A_DIR + "panels/ui_story_dialogue_9slice.png"
const V18_SHOP_DIR := "res://assets/ui_core/v18_windows/shop/"
const V18_GYM_DIR := "res://assets/ui_core/v18_windows/gym/"
const V17_INK := Color("#213D3A")
const V17_MUTED := Color("#45645F")
const V17_CORAL := Color("#C95543")
const THEME_PAPER_MODAL := "res://assets/ui_core/theme/paper_modal_9slice.png"
const THEME_PAPER_CHOICE := "res://assets/ui_core/theme/dialogue_choice_9slice.png"
const THEME_PAPER_CARD := "res://assets/ui_core/theme/ui_tutorial_callout_9slice.png"
const THEME_FABRIC_RIBBON := "res://assets/ui_core/theme/ribbon_header_9slice.png"

const V14_EXPAND_HALOS := {
	"dialogue_choice_9slice": Vector4(14, 17, 14, 14),
	"paper_modal_9slice": Vector4(17, 18, 17, 17),
	"ribbon_header_9slice": Vector4(15, 18, 16, 19),
	"ui_tutorial_callout_9slice": Vector4(8, 14, 10, 17),
}

const V14_DEFAULT_HEIGHTS := {
	"dialogue_choice_9slice": 60.0,
	"ribbon_header_9slice": 46.0,
	"ui_tutorial_callout_9slice": 64.0,
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

static func v17_texture(rel_or_full: String) -> Texture2D:
	var full_path := rel_or_full if rel_or_full.begins_with("res://") else (V17_UI_A_DIR + rel_or_full)
	if not ResourceLoader.exists(full_path):
		return null
	return load(full_path) as Texture2D

static func v17_icon(icon_key: String) -> Texture2D:
	if icon_key == "":
		return null
	return v17_texture("icons/%s.png" % icon_key)

static func _scaled_v17_texture(full_path: String, tex: Texture2D, scale: float) -> Texture2D:
	if tex == null or scale >= 0.995:
		return tex
	var q_scale := maxf(0.18, roundf(scale * 100.0) / 100.0)
	var cache_key := "v17:%s@%.2f" % [full_path.get_file().get_basename(), q_scale]
	if not _scaled_tex_cache.has(cache_key):
		var img := tex.get_image()
		if img != null and not img.is_empty():
			var copy_img := img.duplicate() as Image
			if copy_img.is_compressed():
				copy_img.decompress()
			var new_w := maxi(16, int(round(float(tex.get_width()) * q_scale)))
			var new_h := maxi(16, int(round(float(tex.get_height()) * q_scale)))
			copy_img.resize(new_w, new_h, Image.INTERPOLATE_CUBIC)
			_scaled_tex_cache[cache_key] = ImageTexture.create_from_image(copy_img)
	return _scaled_tex_cache.get(cache_key, tex) as Texture2D

static func v17_capsule_box(rel_or_full: String, target_h: float, modulate_col: Color = Color.WHITE, content_pad: Vector4 = Vector4(18, 4, 18, 4)) -> StyleBoxTexture:
	var full_path := rel_or_full if rel_or_full.begins_with("res://") else (V17_UI_A_DIR + rel_or_full)
	var tex := v17_texture(full_path)
	if tex == null:
		return null
	var base := full_path.get_file().get_basename()
	var solid_pad := Vector4(25, 14, 24, 14)
	var cap_px := 64.0
	if base == "ui_hud_resource_capsule_9slice":
		solid_pad = Vector4(38, 17, 37, 17)
		cap_px = 86.0
	var opaque_h := maxf(16.0, float(tex.get_height()) - solid_pad.y - solid_pad.w)
	var eff_scale := clampf(target_h / opaque_h, 0.25, 1.0) if target_h > 8.0 else 1.0
	var scaled_tex := _scaled_v17_texture(full_path, tex, eff_scale)
	var actual_scale := float(scaled_tex.get_height()) / maxf(1.0, float(tex.get_height()))
	var box := StyleBoxTexture.new()
	box.texture = scaled_tex
	box.texture_margin_left = roundf(cap_px * actual_scale)
	box.texture_margin_right = roundf(cap_px * actual_scale)
	box.texture_margin_top = 0.0
	box.texture_margin_bottom = 0.0
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.expand_margin_left = roundf(solid_pad.x * actual_scale)
	box.expand_margin_top = roundf(solid_pad.y * actual_scale)
	box.expand_margin_right = roundf(solid_pad.z * actual_scale)
	box.expand_margin_bottom = roundf(solid_pad.w * actual_scale)
	box.modulate_color = modulate_col
	if content_pad.x >= 0.0:
		box.content_margin_left = content_pad.x
		box.content_margin_top = content_pad.y
		box.content_margin_right = content_pad.z
		box.content_margin_bottom = content_pad.w
	return box

static func v17_panel_box(rel_or_full: String, caps: Vector4, solid_pad: Vector4, target_scale: float = 0.62, modulate_col: Color = Color.WHITE, content_pad: Vector4 = Vector4(-1, -1, -1, -1)) -> StyleBoxTexture:
	var full_path := rel_or_full if rel_or_full.begins_with("res://") else (V17_UI_A_DIR + rel_or_full)
	var tex := v17_texture(full_path)
	if tex == null:
		return null
	var eff_scale := clampf(target_scale, 0.25, 1.0)
	var scaled_tex := _scaled_v17_texture(full_path, tex, eff_scale)
	var actual_scale := float(scaled_tex.get_height()) / maxf(1.0, float(tex.get_height()))
	var box := StyleBoxTexture.new()
	box.texture = scaled_tex
	box.texture_margin_left = roundf(caps.x * actual_scale)
	box.texture_margin_top = roundf(caps.y * actual_scale)
	box.texture_margin_right = roundf(caps.z * actual_scale)
	box.texture_margin_bottom = roundf(caps.w * actual_scale)
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.expand_margin_left = roundf(solid_pad.x * actual_scale)
	box.expand_margin_top = roundf(solid_pad.y * actual_scale)
	box.expand_margin_right = roundf(solid_pad.z * actual_scale)
	box.expand_margin_bottom = roundf(solid_pad.w * actual_scale)
	box.modulate_color = modulate_col
	if content_pad.x >= 0.0:
		box.content_margin_left = content_pad.x
		box.content_margin_top = content_pad.y
		box.content_margin_right = content_pad.z
		box.content_margin_bottom = content_pad.w
	return box

static func make_v17_button(button: Button, tint: Color = Color.WHITE, ink: Color = V17_INK, font_size: int = 21, target_h: float = -1.0, content_pad: Vector4 = Vector4(18, 4, 18, 4)) -> void:
	if not is_instance_valid(button):
		return
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_font_override("font", DaylightUI.bold_font())
	var btn_h := target_h if target_h > 8.0 else maxf(button.size.y, button.custom_minimum_size.y)
	if btn_h <= 8.0:
		btn_h = 54.0
	var hov_tint := Color(clampf(tint.r * 0.96, 0.0, 1.0), clampf(tint.g * 0.99, 0.0, 1.0), clampf(tint.b * 0.97, 0.0, 1.0), tint.a)
	var prs_tint := Color(clampf(tint.r * 0.90, 0.0, 1.0), clampf(tint.g * 0.94, 0.0, 1.0), clampf(tint.b * 0.92, 0.0, 1.0), tint.a)
	var dis_tint := Color(tint.r * 0.92, tint.g * 0.92, tint.b * 0.92, tint.a * 0.62)
	var nbox := v17_capsule_box(V17_ACTION_BTN, btn_h, tint, content_pad)
	if nbox != null:
		var hbox := v17_capsule_box(V17_ACTION_BTN, btn_h, hov_tint, content_pad)
		var pbox := v17_capsule_box(V17_ACTION_BTN, btn_h, prs_tint, content_pad)
		var dbox := v17_capsule_box(V17_ACTION_BTN, btn_h, dis_tint, content_pad)
		button.add_theme_stylebox_override("normal", nbox)
		button.add_theme_stylebox_override("focus", nbox)
		button.add_theme_stylebox_override("hover", hbox if hbox != null else nbox)
		button.add_theme_stylebox_override("pressed", pbox if pbox != null else nbox)
		button.add_theme_stylebox_override("hover_pressed", pbox if pbox != null else nbox)
		button.add_theme_stylebox_override("disabled", dbox if dbox != null else nbox)
	for col_key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(col_key, ink)
	button.add_theme_color_override("font_disabled_color", Color(ink, 0.55))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	SchoolObjectUI.borderless(button)
	attach_hover_pop(button, 1.022)

static func v18_box(full_path: String, margins: Vector4, content_pad: Vector4 = Vector4(-1, -1, -1, -1), modulate_col: Color = Color.WHITE) -> StyleBoxTexture:
	if not ResourceLoader.exists(full_path):
		return null
	var tex := load(full_path) as Texture2D
	if tex == null:
		return null
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.texture_margin_left = margins.x
	box.texture_margin_top = margins.y
	box.texture_margin_right = margins.z
	box.texture_margin_bottom = margins.w
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	box.modulate_color = modulate_col
	if content_pad.x >= 0.0:
		box.content_margin_left = content_pad.x
		box.content_margin_top = content_pad.y
		box.content_margin_right = content_pad.z
		box.content_margin_bottom = content_pad.w
	return box

static func apply_v18_panel(panel: Control, full_path: String, margins: Vector4, modulate_col: Color = Color.WHITE, content_pad: Vector4 = Vector4(-1, -1, -1, -1)) -> bool:
	if not is_instance_valid(panel):
		return false
	var box := v18_box(full_path, margins, content_pad, modulate_col)
	if box == null:
		return false
	panel.add_theme_stylebox_override("panel", box)
	return true

static func apply_v18_button(button: Button, full_path: String, margins: Vector4, ink: Color, font_size: int = 20, content_pad: Vector4 = Vector4(12, 4, 12, 4), disabled_path: String = "", disabled_ink: Color = Color(-1, -1, -1, -1), normal_mod: Color = Color.WHITE) -> bool:
	if not is_instance_valid(button):
		return false
	var nbox := v18_box(full_path, margins, content_pad, normal_mod)
	if nbox == null:
		return false
	var hov_col := Color(minf(1.08, normal_mod.r * 1.05), minf(1.08, normal_mod.g * 1.04), minf(1.08, normal_mod.b * 1.02), normal_mod.a)
	var prs_col := Color(normal_mod.r * 0.90, normal_mod.g * 0.89, normal_mod.b * 0.88, normal_mod.a)
	var hbox := v18_box(full_path, margins, content_pad, hov_col)
	var pbox := v18_box(full_path, margins, content_pad, prs_col)
	var dbox := v18_box(disabled_path, margins, content_pad, Color(0.94, 0.92, 0.89, 0.92)) if disabled_path != "" else v18_box(full_path, margins, content_pad, Color(normal_mod.r * 0.86, normal_mod.g * 0.86, normal_mod.b * 0.86, normal_mod.a * 0.72))
	button.add_theme_stylebox_override("normal", nbox)
	button.add_theme_stylebox_override("focus", nbox)
	button.add_theme_stylebox_override("hover", hbox if hbox != null else nbox)
	button.add_theme_stylebox_override("pressed", pbox if pbox != null else nbox)
	button.add_theme_stylebox_override("hover_pressed", pbox if pbox != null else nbox)
	button.add_theme_stylebox_override("disabled", dbox if dbox != null else nbox)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_font_override("font", DaylightUI.bold_font())
	for col_key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(col_key, ink)
	button.add_theme_color_override("font_disabled_color", disabled_ink if disabled_ink.r >= 0.0 else Color(ink, 0.52))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	SchoolObjectUI.borderless(button)
	attach_hover_pop(button, 1.022)
	return true

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
