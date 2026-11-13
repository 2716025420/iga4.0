class_name GameSettingsPage
extends Control

signal close_requested

const DESIGN := Vector2(1920.0, 1080.0)
const ART_ROOT := "res://assets/ui/player_experience/"
const ART_SCALE := Vector2(1920.0 / 1672.0, 1080.0 / 941.0)
const INK := Color("#173C51")
const TEAL := Color("#328C92")
const CREAM := Color("#FFF2D6")
const PAPER_FILL := Color("#FFF8EB")

var stage: Control
var room_art: TextureRect
var draft: Dictionary = {}
var original: Dictionary = {}
var sliders: Dictionary = {}
var fullscreen_toggle: CheckButton
var fullscreen_state: Label
var motion_toggle: CheckButton
var motion_state: Label
var speed_label: Label
var speed_option: OptionButton
var status: Label
var preview: RichTextLabel
var _preview_elapsed: float = 0.0
var _discard_prompt: Panel
var _locked_controls: Array[Dictionary] = []

func _ready() -> void:
	name = "SettingsPage"
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	theme = DaylightUI.get_theme().duplicate() as Theme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	original = SaveManager.settings.duplicate(true)
	draft = original.duplicate(true)

	stage = Control.new()
	stage.name = "SettingsStage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.size = DESIGN
	add_child(stage)

	var room_path := ART_ROOT + "settings_broadcast_room_wide.png"
	if not ResourceLoader.exists(room_path): room_path = ART_ROOT + "settings_broadcast_room.png"
	room_art = SchoolObjectUI.art(stage, "BroadcastRoom", room_path)
	var console := SchoolObjectUI.art(stage, "BroadcastConsole", ART_ROOT + "settings_console.png")
	console.stretch_mode = TextureRect.STRETCH_SCALE
	_place(console, Rect2(135, 87, 1438, 885))

	_label(stage, "Title", "游戏设置", Rect2(150, 20, 520, 128), 88, CREAM)
	_label(stage, "Subtitle", "调到自己的频率。", Rect2(235, 151, 480, 49), 29, CREAM)
	var back_btn := _button(stage, "BackButton", "‹  返回", Rect2(1488, 44, 153, 60), 28, true)
	back_btn.pressed.connect(request_close)
	_label(stage, "OnAir", "ON AIR", Rect2(402, 272, 145, 39), 30, Color("#FFFDF7"), true)
	_label(stage, "Frequency", "放学以后 · FM 104", Rect2(928, 233, 240, 26), 17, Color("#FFF8E8"))
	_label(stage, "SoundHeading", "♪  声音", Rect2(256, 369, 590, 54), 32)
	_label(stage, "ComfortHeading", "显示与阅读", Rect2(926, 369, 500, 54), 32)
	_rule(Rect2(332, 421, 514, 1))
	_rule(Rect2(925, 421, 523, 1))

	var audio_keys := ["master_volume", "music_volume", "sfx_volume"]
	var audio_names := ["总音量", "背景音乐", "音效"]
	for index in audio_keys.size():
		var key: String = audio_keys[index]
		var y := 451.0 + index * 100.0
		_label(stage, key + "Label", audio_names[index], Rect2(278, y, 140, 54), 27)
		var value_label := _label(stage, key + "Value", "", Rect2(790, y, 75, 54), 27)
		var slider := HSlider.new()
		slider.name = key + "Slider"
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1
		slider.value = float(draft[key]) * 100
		slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["slider", "grabber_area", "grabber_area_highlight"]:
			var track := StyleBoxFlat.new()
			track.bg_color = Color("#C9C5B2") if state == "slider" else TEAL
			track.border_color = Color("#8C9D9B")
			track.set_border_width_all(1)
			track.set_content_margin_all(7)
			track.set_corner_radius_all(8)
			slider.add_theme_stylebox_override(state, track)
		for state in ["grabber", "grabber_highlight", "grabber_disabled"]:
			slider.add_theme_icon_override(state, load(ART_ROOT + "settings_knob.svg"))
		stage.add_child(slider)
		_place(slider, Rect2(426, y - 2, 344, 58))
		value_label.text = "%d%%" % int(slider.value)
		slider.value_changed.connect(func(value: float):
			draft[key] = value / 100.0
			value_label.text = "%d%%" % int(value)
		)
		sliders[key] = slider
		if index < 2:
			_rule(Rect2(258, y + 81, 590, 1))

	var fs_pair := _toggle("FullscreenToggle", "全屏显示", Rect2(925, 436, 485, 50), bool(draft["fullscreen"]))
	fullscreen_toggle = fs_pair[0] as CheckButton
	fullscreen_state = fs_pair[1] as Label
	fullscreen_toggle.toggled.connect(func(value: bool): draft["fullscreen"] = value)

	var rm_pair := _toggle("ReducedMotionToggle", "减少动态效果", Rect2(925, 496, 485, 50), bool(draft["reduced_motion"]))
	motion_toggle = rm_pair[0] as CheckButton
	motion_state = rm_pair[1] as Label
	motion_toggle.toggled.connect(func(value: bool): draft["reduced_motion"] = value)

	speed_label = _label(stage, "TextSpeedLabel", "文本速度", Rect2(925, 562, 240, 48), 27)
	speed_option = OptionButton.new()
	speed_option.name = "TextSpeedOption"
	for copy in ["舒缓", "标准", "快速", "即时显示"]:
		speed_option.add_item(copy)
	speed_option.selected = int(draft["text_speed"])
	speed_option.add_theme_font_size_override("font_size", 28)
	speed_option.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_field(speed_option)
	stage.add_child(speed_option)
	_place(speed_option, Rect2(1190, 561, 280, 48))
	speed_option.item_selected.connect(func(index: int):
		draft["text_speed"] = index
		_preview_elapsed = 0.0
	)

	_label(stage, "PreviewSymbol", "♪", Rect2(942, 645, 50, 60), 40, Color("#53ACB9"), true)
	preview = RichTextLabel.new()
	preview.name = "ReadingPreview"
	preview.text = "放学的铃声响了。收好书包，慢慢出发吧。"
	preview.scroll_active = false
	preview.add_theme_font_size_override("normal_font_size", 28)
	preview.add_theme_color_override("default_color", CREAM)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(preview)
	_place(preview, Rect2(1004, 637, 443, 83))

	var status_pill := SchoolObjectUI.slab(stage, "SettingsStatusPlate", Rect2(504, 742, 560, 32), Color(0.08, 0.21, 0.27, 0.90))
	var pill_style := status_pill.get_theme_stylebox("panel") as StyleBoxFlat
	if pill_style != null:
		pill_style.set_border_width_all(0)
		pill_style.set_corner_radius_all(16)
	_place(status_pill, Rect2(504, 742, 560, 32))
	status = _label(stage, "SettingsStatus", "设置在所有存档之间共用 · 保存后生效。", Rect2(504, 742, 560, 32), 19, Color("#FFFDF7"), true)

	var reset_btn := _button(stage, "ResetDefaults", "↶  恢复默认", Rect2(342, 796, 276, 72), 28)
	var cancel_btn := _button(stage, "CancelSettings", "×  取消修改", Rect2(660, 796, 320, 72), 28)
	var save_btn := _button(stage, "SaveSettings", "保存设置", Rect2(1022, 796, 312, 72), 30, false, true)
	reset_btn.pressed.connect(_reset_defaults)
	cancel_btn.pressed.connect(request_close)
	save_btn.pressed.connect(_save)

	resized.connect(_layout)
	Platform.input_mode_changed.connect(_on_input_mode_changed)
	_layout()
	_layout_comfort_panel()
	_wire_focus()
	back_btn.grab_focus()

func _layout() -> void:
	if not is_instance_valid(stage):
		return
	Platform.fit_stage(self, stage, Color("#243A47"), room_art.texture if room_art != null else null)
	if is_instance_valid(room_art) and room_art.texture != null and room_art.texture.get_width() > int(DESIGN.x):
		var factor := minf(size.x / DESIGN.x, size.y / DESIGN.y)
		var wide_scale := maxf(1.0, (size.x / maxf(factor, 0.001)) / 2340.0)
		var w := 2340.0 * wide_scale
		var h := 1080.0 * wide_scale
		room_art.stretch_mode = TextureRect.STRETCH_SCALE
		_place(room_art, Rect2((DESIGN.x - w) * 0.5, (DESIGN.y - h) * 0.5, w, h))

func _on_input_mode_changed(_touch: bool) -> void:
	if is_inside_tree():
		_layout_comfort_panel()
		_wire_focus()

func _hide_fullscreen_option() -> bool:
	return OS.get_name() in ["Android", "iOS"] or Platform.is_touch()

func _layout_comfort_panel() -> void:
	var hide_fs := _hide_fullscreen_option()
	fullscreen_toggle.visible = not hide_fs
	fullscreen_state.visible = not hide_fs
	if hide_fs:
		_place(motion_toggle, Rect2(925, 444, 485, 58))
		_place(motion_state, Rect2(1420, 444, 50, 58))
		_place(speed_label, Rect2(925, 526, 240, 54))
		_place(speed_option, Rect2(1190, 526, 280, 54))
	else:
		_place(fullscreen_toggle, Rect2(925, 436, 485, 50))
		_place(fullscreen_state, Rect2(1420, 436, 50, 50))
		_place(motion_toggle, Rect2(925, 496, 485, 50))
		_place(motion_state, Rect2(1420, 496, 50, 50))
		_place(speed_label, Rect2(925, 562, 240, 48))
		_place(speed_option, Rect2(1190, 561, 280, 48))

func _wire_focus() -> void:
	var master := sliders["master_volume"] as Slider
	var music := sliders["music_volume"] as Slider
	var sfx := sliders["sfx_volume"] as Slider
	var back := stage.get_node("BackButton") as Button
	var reset_btn := stage.get_node("ResetDefaults") as Button
	var cancel_btn := stage.get_node("CancelSettings") as Button
	var save_btn := stage.get_node("SaveSettings") as Button
	var right_top: Control = motion_toggle if _hide_fullscreen_option() else fullscreen_toggle

	master.focus_neighbor_bottom = master.get_path_to(music)
	master.focus_neighbor_top = master.get_path_to(back)
	master.focus_neighbor_right = master.get_path_to(right_top)
	music.focus_neighbor_top = music.get_path_to(master)
	music.focus_neighbor_bottom = music.get_path_to(sfx)
	music.focus_neighbor_right = music.get_path_to(motion_toggle)
	sfx.focus_neighbor_top = sfx.get_path_to(music)
	sfx.focus_neighbor_bottom = sfx.get_path_to(reset_btn)
	sfx.focus_neighbor_right = sfx.get_path_to(speed_option)

	if not _hide_fullscreen_option():
		fullscreen_toggle.focus_neighbor_left = fullscreen_toggle.get_path_to(master)
		fullscreen_toggle.focus_neighbor_bottom = fullscreen_toggle.get_path_to(motion_toggle)
		fullscreen_toggle.focus_neighbor_top = fullscreen_toggle.get_path_to(back)
		motion_toggle.focus_neighbor_top = motion_toggle.get_path_to(fullscreen_toggle)
	else:
		motion_toggle.focus_neighbor_top = motion_toggle.get_path_to(back)
	motion_toggle.focus_neighbor_left = motion_toggle.get_path_to(music)
	motion_toggle.focus_neighbor_bottom = motion_toggle.get_path_to(speed_option)
	speed_option.focus_neighbor_left = speed_option.get_path_to(sfx)
	speed_option.focus_neighbor_top = speed_option.get_path_to(motion_toggle)
	speed_option.focus_neighbor_bottom = speed_option.get_path_to(save_btn)

	reset_btn.focus_neighbor_top = reset_btn.get_path_to(sfx)
	reset_btn.focus_neighbor_right = reset_btn.get_path_to(cancel_btn)
	cancel_btn.focus_neighbor_left = cancel_btn.get_path_to(reset_btn)
	cancel_btn.focus_neighbor_top = cancel_btn.get_path_to(sfx)
	cancel_btn.focus_neighbor_right = cancel_btn.get_path_to(save_btn)
	save_btn.focus_neighbor_left = save_btn.get_path_to(cancel_btn)
	save_btn.focus_neighbor_top = save_btn.get_path_to(speed_option)
	back.focus_neighbor_bottom = back.get_path_to(right_top)

func _place(node: Control, rect: Rect2) -> void:
	node.position = rect.position * ART_SCALE
	node.size = rect.size * ART_SCALE

func _label(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int = 27, color: Color = INK, centered: bool = false, raw_coords: bool = false) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = copy
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	var scale_x := 1.0 if raw_coords else ART_SCALE.x
	label.add_theme_font_size_override("font_size", roundi(font_size * scale_x))
	label.add_theme_color_override("font_color", color)
	if node_name == "Title":
		label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	parent.add_child(label)
	if raw_coords:
		DaylightUI.place(label, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	else:
		_place(label, rect)
	return label

func _rule(rect: Rect2) -> void:
	var line := ColorRect.new()
	line.color = Color(0.16, 0.36, 0.40, 0.25)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(line)
	_place(line, rect)

func _button(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int = 29, solid: bool = false, light: bool = false, raw_coords: bool = false) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = copy
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var scale_x := 1.0 if raw_coords else ART_SCALE.x
	button.add_theme_font_size_override("font_size", roundi(font_size * scale_x))
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = CREAM if solid else Color.TRANSPARENT
		if state == "hover":
			style.bg_color = Color("#F4DFC0") if solid else Color(1.0, 1.0, 1.0, 0.14 if light else 0.12)
		elif state in ["pressed", "hover_pressed"]:
			style.bg_color = Color("#D8C5A7") if solid else Color(0.06, 0.18, 0.24, 0.18)
		style.set_corner_radius_all(16)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, Color("#FFFDF7") if light else INK)
	parent.add_child(button)
	if raw_coords:
		DaylightUI.place(button, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	else:
		_place(button, rect)
	SchoolObjectUI.borderless(button)
	return button

func _toggle(node_name: String, copy: String, rect: Rect2, value: bool) -> Array:
	var toggle := CheckButton.new()
	toggle.name = node_name
	toggle.text = copy
	toggle.button_pressed = value
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggle.add_theme_font_size_override("font_size", roundi(27 * ART_SCALE.x))
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		toggle.add_theme_color_override(key, INK)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.16, 0.45, 0.47, 0.08) if state in ["hover", "hover_pressed"] else Color.TRANSPARENT
		style.set_corner_radius_all(8)
		toggle.add_theme_stylebox_override(state, style)
	toggle.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["checked", "checked_disabled"]:
		toggle.add_theme_icon_override(key, load(ART_ROOT + "settings_switch_on.svg"))
	for key in ["unchecked", "unchecked_disabled"]:
		toggle.add_theme_icon_override(key, load(ART_ROOT + "settings_switch_off.svg"))
	stage.add_child(toggle)
	_place(toggle, rect)
	SchoolObjectUI.borderless(toggle)
	var state_label := _label(stage, node_name + "State", "开" if value else "关", Rect2(1420, rect.position.y, 50, rect.size.y), 24)
	SchoolObjectUI.set_selected(toggle, value)
	toggle.toggled.connect(func(enabled: bool):
		state_label.text = "开" if enabled else "关"
		SchoolObjectUI.set_selected(toggle, enabled)
	)
	return [toggle, state_label]

func _field(option: OptionButton) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = PAPER_FILL if state == "normal" else Color("#F3E2C5")
		style.border_color = TEAL if state in ["hover", "pressed"] else Color("#8EA7A9")
		style.set_border_width_all(1)
		style.set_corner_radius_all(12)
		style.content_margin_left = 16
		style.content_margin_right = 14
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		option.add_theme_stylebox_override(state, style)
	option.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		option.add_theme_color_override(key, INK)
	var popup := option.get_popup()
	var plate := StyleBoxFlat.new()
	plate.bg_color = PAPER_FILL
	plate.border_color = Color("#8EA7A9")
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(10)
	plate.set_content_margin_all(8)
	popup.add_theme_stylebox_override("panel", plate)
	var selected := StyleBoxFlat.new()
	selected.bg_color = Color("#DCEAD9")
	selected.set_corner_radius_all(7)
	popup.add_theme_stylebox_override("hover", selected)
	popup.add_theme_color_override("font_color", INK)
	popup.add_theme_color_override("font_hover_color", INK)
	popup.add_theme_font_size_override("font_size", 26)

func _process(delta: float) -> void:
	if not is_instance_valid(preview):
		return
	_preview_elapsed += delta
	var interval: float = [0.045, 0.025, 0.012, 0.0][int(draft["text_speed"])]
	preview.visible_characters = -1 if interval <= 0.0 else int(_preview_elapsed / interval)
	if _preview_elapsed > 4.0:
		_preview_elapsed = 0.0

func _reset_defaults() -> void:
	for key in sliders:
		sliders[key].value = float(SaveManager.DEFAULT_SETTINGS[key]) * 100
	fullscreen_toggle.button_pressed = bool(SaveManager.DEFAULT_SETTINGS["fullscreen"])
	motion_toggle.button_pressed = bool(SaveManager.DEFAULT_SETTINGS["reduced_motion"])
	speed_option.select(int(SaveManager.DEFAULT_SETTINGS["text_speed"]))
	draft["text_speed"] = int(SaveManager.DEFAULT_SETTINGS["text_speed"])
	_preview_elapsed = 0.0
	status.text = "已恢复默认值，保存后生效。"

func _save() -> void:
	if SaveManager.update_settings(draft):
		original = draft.duplicate(true)
		close_requested.emit()
	else:
		status.text = SaveManager.last_error

func request_close() -> void:
	if is_instance_valid(_discard_prompt):
		for entry in _locked_controls:
			if is_instance_valid(entry["control"]):
				entry["control"].focus_mode = entry["mode"]
		_locked_controls.clear()
		_discard_prompt.queue_free()
		_discard_prompt = null
		stage.get_node("BackButton").grab_focus()
		return
	if draft == original:
		close_requested.emit()
		return
	for node in stage.find_children("*", "Control", true, false):
		if node.focus_mode != Control.FOCUS_NONE:
			_locked_controls.append({"control": node, "mode": node.focus_mode})
			node.focus_mode = Control.FOCUS_NONE

	_discard_prompt = Panel.new()
	_discard_prompt.name = "DiscardChanges"
	var scrim := StyleBoxFlat.new()
	scrim.bg_color = Color(0.06, 0.14, 0.20, 0.72)
	_discard_prompt.add_theme_stylebox_override("panel", scrim)
	stage.add_child(_discard_prompt)
	DaylightUI.place(_discard_prompt, -600, -300, 3120, 1680)

	var dialog := SchoolObjectUI.slab(_discard_prompt, "Dialog", Rect2(1160, 680, 800, 320), PAPER_FILL)
	var plate := dialog.get_theme_stylebox("panel") as StyleBoxFlat
	plate.border_color = Color("#8EA7A9")
	plate.set_border_width_all(2)
	plate.set_corner_radius_all(16)
	_label(dialog, "Question", "放弃未保存的设置？", Rect2(56, 44, 688, 56), 36, INK, false, true)
	_label(dialog, "Copy", "已保存的设置会继续使用。", Rect2(56, 108, 688, 48), 24, Color("#566672"), false, true)

	var cancel := _style_modal_btn(dialog, "KeepEditing", "继续调整", Rect2(56, 206, 320, 68), false)
	cancel.pressed.connect(request_close)
	var discard := _style_modal_btn(dialog, "Discard", "放弃修改", Rect2(424, 206, 320, 68), true)
	discard.pressed.connect(func(): close_requested.emit())
	cancel.focus_neighbor_right = cancel.get_path_to(discard)
	discard.focus_neighbor_left = discard.get_path_to(cancel)
	cancel.grab_focus()

func _style_modal_btn(parent: Control, node_name: String, copy: String, rect: Rect2, warning: bool) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = copy
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 26)
	var base := Color("#D66B5A") if warning else Color("#EFE6D5")
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = base
		if state == "hover":
			box.bg_color = base.lightened(0.06) if warning else base.darkened(0.05)
		elif state in ["pressed", "hover_pressed"]:
			box.bg_color = base.darkened(0.10)
		box.border_color = Color("#B95343") if warning else Color("#D4C6B4")
		box.set_border_width_all(1)
		box.set_corner_radius_all(10)
		btn.add_theme_stylebox_override(state, box)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(key, Color("#FFFDF8") if warning else INK)
	parent.add_child(btn)
	DaylightUI.place(btn, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	SchoolObjectUI.borderless(btn)
	return btn
