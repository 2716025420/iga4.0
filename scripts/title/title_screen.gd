class_name TitleScreen
extends Control

const DESIGN := Vector2(1920, 1080)
var presentation: Control
var continue_button: Button
var new_button: Button
var settings_button: Button
var quit_button: Button
var modal: Panel
var backdrop: ColorRect
var status_label: Label
var _modal_kind: String = ""
var settings_page: GameSettingsPage

func _ready() -> void:
	theme = DaylightUI.get_theme()
	SceneManager.current_scene_type = SceneManager.TargetScene.TITLE
	clip_contents = true
	presentation = Control.new()
	presentation.name = "TitlePresentation"
	presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(presentation)
	presentation.size = DESIGN
	_art("RoomArt", "res://assets/backgrounds/phase_three/title/background.png")
	_art("ForegroundArt", "res://assets/backgrounds/phase_three/title/foreground.png")
	_label("GameTitle", "IGA", 110, Vector2(252, 142), Vector2(900, 150), true)
	_rule(presentation, Vector2(256, 296), 488)
	_label("Tagline", "Inorganic General Alien", 36, Vector2(256, 315), Vector2(680, 64), true)
	_label("BuildNotice", "开发测试版 · 剧情与设定待完善", 24, Vector2(258, 392), Vector2(720, 42))
	continue_button = _menu_row("ContinueButton", "继续游戏", 338)
	new_button = _menu_row("NewGameButton", "开始新游戏", 458)
	settings_button = _menu_row("SettingsButton", "设置", 578)
	quit_button = _menu_row("QuitButton", "退出游戏", 698)
	continue_button.pressed.connect(_continue)
	new_button.pressed.connect(_new_game)
	settings_button.pressed.connect(_settings)
	quit_button.pressed.connect(_quit)
	status_label = _label("SaveStatus", "", 24, Vector2(1330, 820), Vector2(420, 96))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	backdrop = ColorRect.new()
	backdrop.name = "ModalBackdrop"
	backdrop.color = Color(0.22, 0.20, 0.28, 0.44)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.visible = false
	presentation.add_child(backdrop)
	DaylightUI.place(backdrop, -600, -300, 3120, 1680)
	_wire_menu_focus()
	_refresh_save()
	SaveManager.save_state_changed.connect(_refresh_save)
	resized.connect(_layout)
	_layout()
	_focus_default_row()

func _layout() -> void:
	var room := presentation.get_node_or_null("RoomArt") as TextureRect
	Platform.fit_stage(self, presentation, Color("#EBE3D3"), room.texture if room != null else null)

func _art(node_name: String, path: String) -> void:
	var art := TextureRect.new()
	art.name = node_name
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(path): art.texture = load(path)
	presentation.add_child(art)
	DaylightUI.place(art, 0, 0, DESIGN.x, DESIGN.y)

func _label(node_name: String, text: String, font_size: int, position: Vector2, extent: Vector2, serif: bool = false) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#303A67"))
	label.add_theme_color_override("font_shadow_color", Color(1.0, 0.98, 0.93, 0.62))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 2)
	if serif: label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	presentation.add_child(label)
	DaylightUI.place(label, position.x, position.y, extent.x, extent.y)
	return label

func _rule(parent: Control, position: Vector2, width: float) -> void:
	var rule := ColorRect.new()
	rule.color = Color(0.31, 0.32, 0.43, 0.32)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rule)
	DaylightUI.place(rule, position.x, position.y, width, 1)

func _row_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(3)
	style.content_margin_left = 44
	style.content_margin_right = 44
	return style

func _menu_row(node_name: String, text: String, top: float) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", Color("#303A67"))
	button.add_theme_color_override("font_hover_color", Color("#222B54"))
	button.add_theme_color_override("font_pressed_color", Color("#222B54"))
	button.add_theme_color_override("font_focus_color", Color("#222B54"))
	button.add_theme_color_override("font_disabled_color", Color("#67657C"))
	button.add_theme_stylebox_override("normal", _row_style(Color.TRANSPARENT))
	button.add_theme_stylebox_override("hover", _row_style(Color(0.79,0.73,0.87,0.48)))
	button.add_theme_stylebox_override("pressed", _row_style(Color(0.72,0.65,0.82,0.55)))
	button.add_theme_stylebox_override("disabled", _row_style(Color.TRANSPARENT))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	presentation.add_child(button)
	DaylightUI.place(button, 1320, top, 444, 100)
	if node_name != "QuitButton": _rule(presentation, Vector2(1330, top + 112), 424)
	return button

func _button(parent: Control, node_name: String, text: String, position: Vector2, extent: Vector2, primary: bool = false) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 32)
	var base := Color("#D66B5A") if primary else Color("#EFE6D5")
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = base
		if state == "hover":
			box.bg_color = base.lightened(0.06) if primary else base.darkened(0.05)
		elif state in ["pressed", "hover_pressed"]:
			box.bg_color = base.darkened(0.10)
		box.border_color = Color("#B95343") if primary else Color("#D4C6B4")
		box.set_border_width_all(1)
		box.set_corner_radius_all(12)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, Color("#FFFDF8") if primary else Color("#303A67"))
	parent.add_child(button)
	DaylightUI.place(button, position.x, position.y, extent.x, extent.y)
	SchoolObjectUI.borderless(button)
	return button

func _refresh_save() -> void:
	var metadata: Dictionary = SaveManager.get_save_metadata()
	continue_button.disabled = backdrop.visible or not metadata["available"]
	status_label.text = "可以继续上次的进度。" if metadata["available"] else "从新游戏开始，进度会自动保存。"
	if metadata["backup"]: status_label.text = "可以从备份继续上次的进度。"

func _continue() -> void:
	if backdrop.visible or SceneManager.is_transitioning: return
	if SaveManager.continue_game(): CampusLife.restore_saved_location()
	else: status_label.text = SaveManager.last_error

func _new_game() -> void:
	if backdrop.visible or SceneManager.is_transitioning: return
	if SaveManager.get_save_metadata()["available"]:
		_open_modal("new", "开始新游戏", "这会替换当前进度。之前的存档会保留一份备份。")
		var confirm := _button(modal, "ConfirmNewGame", "开始新游戏", Vector2(70, 330), Vector2(350, 82), true)
		var cancel := _button(modal, "CancelButton", "取消", Vector2(520, 330), Vector2(350, 82))
		confirm.pressed.connect(_begin_new_game)
		cancel.pressed.connect(_close_modal)
		cancel.grab_focus()
	else: _begin_new_game()

func _begin_new_game() -> void:
	if SceneManager.is_transitioning: return
	if SaveManager.start_new_game():
		_close_modal()
		SceneManager.change_scene(SceneManager.TargetScene.HOME)
	else: status_label.text = SaveManager.last_error

func _open_modal(kind: String, heading: String, copy: String = "") -> void:
	_close_modal()
	_modal_kind = kind
	backdrop.visible = true
	modal = Panel.new()
	modal.name = "TitleModal"
	modal.add_theme_stylebox_override("panel", CombatSkin.paper())
	presentation.add_child(modal)
	DaylightUI.place(modal, 490, 260, 940, 530)
	var title := Label.new()
	title.text = heading
	title.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("#303A67"))
	modal.add_child(title)
	DaylightUI.place(title, 60, 40, 700, 66)
	if copy != "":
		var description := Label.new()
		description.text = copy
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 30)
		description.add_theme_color_override("font_color", Color("#4E5372"))
		modal.add_child(description)
		DaylightUI.place(description, 60, 145, 820, 130)
	for button in [continue_button, new_button, settings_button, quit_button]: button.disabled = true

func _wire_menu_focus() -> void:
	var rows := [continue_button, new_button, settings_button, quit_button]
	for idx in rows.size():
		var btn: Button = rows[idx]
		var prev: Button = rows[posmod(idx - 1, rows.size())]
		var nxt: Button = rows[(idx + 1) % rows.size()]
		btn.focus_neighbor_top = btn.get_path_to(prev)
		btn.focus_neighbor_bottom = btn.get_path_to(nxt)
		btn.focus_previous = btn.get_path_to(prev)
		btn.focus_next = btn.get_path_to(nxt)

func _focus_default_row() -> void:
	if is_instance_valid(continue_button):
		(new_button if continue_button.disabled else continue_button).grab_focus()

func _close_modal() -> void:
	if is_instance_valid(modal):
		presentation.remove_child(modal)
		modal.queue_free()
	modal = null
	_modal_kind = ""
	if is_instance_valid(backdrop): backdrop.visible = false
	if is_instance_valid(continue_button):
		for button in [new_button, settings_button, quit_button]: button.disabled = false
		_refresh_save()
		(new_button if continue_button.disabled else continue_button).grab_focus()

func _settings() -> void:
	if backdrop.visible or is_instance_valid(settings_page): return
	for button in [continue_button, new_button, settings_button, quit_button]: button.disabled = true
	settings_page = GameSettingsPage.new()
	add_child(settings_page)
	settings_page.close_requested.connect(func():
		remove_child(settings_page)
		settings_page.queue_free()
		settings_page = null
		for button in [new_button, settings_button, quit_button]: button.disabled = false
		_refresh_save()
		settings_button.grab_focus()
	)

func _quit() -> void:
	if backdrop.visible: return
	_open_modal("quit", "退出游戏", "当前已保存的进度会保留。")
	var confirm := _button(modal, "ConfirmQuit", "退出游戏", Vector2(70, 330), Vector2(350, 82), true)
	var cancel := _button(modal, "CancelButton", "取消", Vector2(520, 330), Vector2(350, 82))
	confirm.pressed.connect(func(): get_tree().quit())
	cancel.pressed.connect(_close_modal)
	cancel.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and is_instance_valid(settings_page):
		settings_page.request_close()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and backdrop.visible:
		_close_modal()
		get_viewport().set_input_as_handled()
