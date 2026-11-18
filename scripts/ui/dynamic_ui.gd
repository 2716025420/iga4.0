class_name DynamicUI
extends RefCounted

## Shared lightweight UI styling and animation helpers (all respect reduced_motion & borderless focus).

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
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(corner_radius)
		box.content_margin_left = 14
		box.content_margin_right = 14
		if state == "normal":
			box.bg_color = fill
			box.border_color = Color(accent, 0.88)
			box.set_border_width_all(2)
			box.border_width_left = 6
			box.border_width_bottom = 5
			box.shadow_color = Color(0.11, 0.16, 0.28, 0.18)
			box.shadow_size = 5
			box.shadow_offset = Vector2(0, 3)
		elif state == "hover":
			box.bg_color = fill.lightened(0.05) if fill.get_luminance() > 0.4 else fill.lightened(0.10)
			box.border_color = accent
			box.set_border_width_all(2)
			box.border_width_left = 7
			box.border_width_bottom = 5
			box.shadow_color = Color(accent, 0.34)
			box.shadow_size = 7
			box.shadow_offset = Vector2(0, 4)
		elif state in ["pressed", "hover_pressed"]:
			box.bg_color = fill.darkened(0.08)
			box.border_color = accent
			box.set_border_width_all(2)
			box.border_width_left = 6
			box.border_width_bottom = 3
			box.shadow_color = Color(0.10, 0.15, 0.26, 0.14)
			box.shadow_size = 2
			box.shadow_offset = Vector2(0, 1)
		else:
			box.bg_color = Color(fill, fill.a * 0.62)
			box.border_color = Color(accent, 0.38)
			box.set_border_width_all(1)
			box.border_width_left = 4
			box.border_width_bottom = 3
		button.add_theme_stylebox_override(state, box)
	for col_key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(col_key, ink)
	button.add_theme_color_override("font_disabled_color", Color(ink, 0.50))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	SchoolObjectUI.borderless(button)
	attach_hover_pop(button, 1.04)

static func apply_world_card_style(button: Button, mode: String) -> void:
	var fill := Color("#FFFFFF", 0.97)
	var ink := Color("#15253D")
	var accent := Color("#368BD2")
	if mode == "next":
		fill = Color("#FFF9ED", 0.97)
		ink = Color("#3D2812")
		accent = Color("#E5953B")
	elif mode == "locked":
		fill = Color("#EFF4FB", 0.92)
		ink = Color("#4B5F7A")
		accent = Color("#8BA0BD")
	make_cel_button(button, fill, ink, accent, 22, 16)
