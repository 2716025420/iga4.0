class_name DaylightUI
extends RefCounted

## Shared presentation only; gameplay state and dialogue scripts remain separate.
const INK := Color("#232030")
const MUTED := Color("#4B485E")
static var _body_font_cache: Font
static var _bold_font_cache: Font

static func body_font() -> Font:
	if _body_font_cache == null:
		var body := FontVariation.new()
		body.base_font = load("res://assets/fonts/NotoSansSC-Regular.ttf")
		body.variation_embolden = 0.22
		_body_font_cache = body
	return _body_font_cache

static func bold_font() -> Font:
	if _bold_font_cache == null:
		var bold := FontVariation.new()
		bold.base_font = load("res://assets/fonts/NotoSansSC-Regular.ttf")
		bold.variation_embolden = 0.42
		_bold_font_cache = bold
	return _bold_font_cache
const PAPER := Color("#FFF9F0")
const LAVENDER := Color("#DDD7ED")
const ACCENT := Color("#796B9E")
const WARM := Color("#9E7051")
const BORDER := Color("#C9BDD6")
static var _theme: Theme
static var _ground_shadow_texture: GradientTexture2D

static func panel_style(fill: Color = PAPER, border: Color = BORDER, inset: int = 0) -> StyleBox:
	return SceneSkin.panel_style(fill, border, inset)

static func get_theme() -> Theme:
	if _theme:
		return _theme
	_theme = Theme.new()
	var body := body_font() as FontVariation
	_theme.default_font = body
	_theme.default_font_size = 21
	_theme.set_font("bold_font", "RichTextLabel", bold_font())
	var serif: Font = load("res://assets/fonts/NotoSerifSC-SemiBold.ttf")
	for type in ["Panel", "PanelContainer"]:
		_theme.set_stylebox("panel", type, panel_style())
	_theme.set_type_variation("CardPanel", "PanelContainer")
	_theme.set_stylebox("panel", "CardPanel", panel_style(Color("#F1ECF5")))
	for type in ["Label", "RichTextLabel", "Button"]:
		_theme.set_color("font_color" if type != "RichTextLabel" else "default_color", type, INK)
	var normal := panel_style(Color("#F6F1FA"), BORDER, 12)
	var hover := panel_style(Color("#E8DFF4"), ACCENT, 12)
	var pressed := panel_style(Color("#DDD1ED"), ACCENT, 12)
	var disabled := panel_style(Color("#EEEAE8"), Color("#D7D0D7"), 12)
	var focus := SceneSkin.focus_style()
	for type in ["Button", "PrimaryButton", "SecondaryButton"]:
		if type != "Button":
			_theme.set_type_variation(type, "Button")
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var style: StyleBox = {"normal": normal, "hover": hover, "pressed": pressed, "disabled": disabled, "focus": focus}[state]
			_theme.set_stylebox(state, type, style)
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			_theme.set_color(color_name, type, INK)
		_theme.set_color("font_disabled_color", type, MUTED)
	_theme.set_stylebox("normal", "PrimaryButton", panel_style(Color("#C7B7DE"), ACCENT, 12))
	_theme.set_stylebox("background", "ProgressBar", panel_style(Color("#ECE5EC"), BORDER))
	_theme.set_stylebox("fill", "ProgressBar", panel_style(Color("#97B5A5"), Color("#97B5A5")))
	for variant in ["TitleLabel", "SubtitleLabel", "SecondaryLabel", "CaptionLabel", "BodyLabel"]:
		_theme.set_type_variation(variant, "Label")
		_theme.set_color("font_color", variant, MUTED if variant in ["SecondaryLabel", "CaptionLabel"] else INK)
		_theme.set_font_size("font_size", variant, 30 if variant == "TitleLabel" else 20)
		if variant in ["TitleLabel", "SubtitleLabel"]:
			_theme.set_font("font", variant, serif)
	var line := StyleBoxLine.new()
	line.color = BORDER
	line.thickness = 1
	_theme.set_stylebox("separator", "HSeparator", line)
	SceneSkin.apply_theme(_theme)
	return _theme

static func readable_bbcode(text: String) -> String:
	var substitutions := {
		"#EDE6D6": "#403C52", "#C4B8D8": "#777387", "#B79AE0": "#796B9E",
		"#E2B35C": "#9E7051", "#E8833A": "#9E7051", "#6FD3C4": "#547C69",
		"#feca57": "#9E7051", "#ff6b6b": "#B65B63", "#2ed573": "#547C69",
		"#ff4757": "#B65B63", "#ff5555": "#B65B63", "#ffa502": "#A86C34", "#1e90ff": "#557C9A",
		"#747d8c": "#777387", "#ffffff": "#403C52", "#ff9ff3": "#796B9E"
	}
	for old in substitutions:
		text = text.replace(old, substitutions[old])
	return text

static func polish(node: Node) -> void:
	if node is Control:
		node.add_theme_constant_override("outline_size", 0)
		node.remove_theme_color_override("font_color")
		if node is Label:
			node.add_theme_font_size_override("font_size", maxi(26 if str(node.name) in ["Title", "TitleLabel", "Header"] else 18, node.get_theme_font_size("font_size")))
			node.add_theme_color_override("font_color", INK)
		elif node is RichTextLabel:
			node.add_theme_color_override("default_color", INK)
			var is_card_summary: bool = str(node.name) == "DescLabel" and node.get_parent() != null and node.get_parent().get_parent() != null and node.get_parent().get_parent().has_method("_refresh_card_illustration")
			var is_result_summary: bool = str(node.name) == "DescLabel" and node.get_parent() != null and node.get_parent().get_parent() != null and str(node.get_parent().get_parent().name) == "ResultModal"
			if not is_card_summary:
				node.add_theme_font_size_override("normal_font_size", 28 if is_result_summary else 21)
			node.add_theme_font_size_override("bold_font_size", 28 if is_result_summary else (24 if is_card_summary else 22))
			if is_result_summary:
				node.scroll_active = false
				node.fit_content = false
				node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			node.add_theme_constant_override("line_separation", 0 if is_card_summary else 8)
			if is_card_summary:
				node.custom_minimum_size.y = 0.0
				node.scroll_active = false
			node.text = readable_bbcode(node.text)
		elif node is Button:
			bind_button_feedback(node)
			node.add_theme_font_size_override("font_size", maxi(18, node.get_theme_font_size("font_size")))
			node.add_theme_color_override("font_color", INK)
	for child in node.get_children():
		polish(child)

static func bind_button_feedback(button: Button) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new() if button.text.strip_edges() in ["×","✕","✖","X"] else SceneSkin.focus_style())
	if not button.has_meta("DaylightFeedbackBound"):
		button.set_meta("DaylightFeedbackBound", true)
		for signal_name in ["focus_entered", "focus_exited", "mouse_entered", "mouse_exited"]:
			button.connect(signal_name, _update_button_feedback.bind(button))
	bind_button_audio(button)
	_update_button_feedback(button)

static func bind_button_audio(button: Button) -> void:
	if not is_instance_valid(button) or button.has_meta("DaylightAudioBound"):
		return
	button.set_meta("DaylightAudioBound", true)
	button.mouse_entered.connect(func() -> void:
		if button.disabled or not button.is_inside_tree():
			return
		var audio := button.get_tree().root.get_node_or_null("AudioManager")
		if audio != null and audio.has_method("play_sfx_hover"):
			audio.call("play_sfx_hover")
	)
	button.pressed.connect(func() -> void:
		if not button.is_inside_tree():
			return
		var audio := button.get_tree().root.get_node_or_null("AudioManager")
		if audio != null and audio.has_method("play_sfx_click"):
			audio.call("play_sfx_click")
	)

static func _update_button_feedback(button: Button) -> void:
	if not is_instance_valid(button):
		return
	button.self_modulate = Color(0.96, 0.94, 1.0) if button.has_focus() and not button.disabled else (Color(1.02, 1.01, 1.03) if button.is_hovered() and not button.disabled and not button.get_meta("choice_selected",false) else Color.WHITE)

static func apply(root: Control) -> void:
	root.theme = get_theme()
	polish(root)
	layout.call_deferred(root)
	if not root.resized.is_connected(layout.bind(root)):
		root.resized.connect(layout.bind(root))

static func place(node: Control, x: float, y: float, width: float, height: float) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.position = Vector2(x, y)
	node.size = Vector2(width, height)

static func centered(node: Control, root_size: Vector2, extent: Vector2) -> void:
	place(node, (root_size.x - extent.x) / 2.0, (root_size.y - extent.y) / 2.0, extent.x, extent.y)

static func soft_ground_shadow(parent: Control, node_name: String, position: Vector2, extent: Vector2) -> TextureRect:
	if _ground_shadow_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 1.0])
		gradient.colors = PackedColorArray([Color(0.35, 0.31, 0.42, 0.14), Color(0.35, 0.31, 0.42, 0.0)])
		_ground_shadow_texture = GradientTexture2D.new()
		_ground_shadow_texture.width = 256
		_ground_shadow_texture.height = 64
		_ground_shadow_texture.gradient = gradient
		_ground_shadow_texture.fill = GradientTexture2D.FILL_RADIAL
		_ground_shadow_texture.fill_from = Vector2(0.5, 0.5)
		_ground_shadow_texture.fill_to = Vector2(1.0, 0.5)
	var shadow := parent.get_node_or_null(node_name) as TextureRect
	if shadow == null:
		shadow = TextureRect.new()
		shadow.name = node_name
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(shadow)
		parent.move_child(shadow, 0)
	shadow.texture = _ground_shadow_texture
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	place(shadow, position.x, position.y, extent.x, extent.y)
	return shadow

static func surface(parent: Control, node_name: String, color: Color) -> Panel:
	var panel := parent.get_node_or_null(node_name) as Panel
	if not panel:
		panel = Panel.new()
		panel.name = node_name
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(panel)
		parent.move_child(panel, 0)
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var key := "panel_frame"
	if node_name == "RouteSurface":
		key = "route_board"
	elif node_name in ["HeaderSurface", "HandSurface"]:
		key = "status_frame"
	elif node_name == "ReadableSurface":
		key = "button_primary" if str(parent.name) == "HotspotExplore" else "button_secondary"
	panel.add_theme_stylebox_override("panel", SceneSkin.style(key, Vector4.ZERO, Color(1, 1, 1, color.a)))
	return panel

static func character_path(key: String, portrait: bool = false) -> String:
	var aliases := {"protagonist": "ye_zhou", "uncle_wan": "liu_yu_long", "victoria": "jiang_zi"}
	return "res://assets/sprites/characters/phase_two/%s/%s.png" % ["portraits" if portrait else "fullbody", aliases.get(key, key)]

static func layout(root: Control) -> void:
	if not is_instance_valid(root) or not root.is_inside_tree():
		return
	if root.has_method("_layout_story_scene"):
		root.call("_layout_story_scene")
		return
	var extent := root.size
	var backgrounds := {"NodeMap": "school_gate", "CombatScreen": "battle_campus", "DialogueScreen": "morning_road"}
	if backgrounds.has(str(root.name)):
		var key: String = backgrounds[str(root.name)]
		var combat_overclock := false
		if str(root.name) == "DialogueScreen":
			key = PhaseTwoContent.background_key(str(root.get("current_dialogue_id")))
		elif str(root.name) == "CombatScreen":
			combat_overclock = CombatPresentation.is_overclock_combat(root)
			if combat_overclock:
				key = "battle_red_moon_lockdown"
			elif GameState.current_node_id == "n_gate":
				key = "battle_sports_field"
		var background := root.get_node("Background") as TextureRect
		var path := PhaseTwoContent.resolve_background_path(key, true) if str(root.name) in ["CombatScreen", "DialogueScreen"] else ("res://assets/backgrounds/phase_two/%s_wide.png" % key)
		if path == "" or not ResourceLoader.exists(path):
			path = "res://assets/backgrounds/phase_two/%s.png" % key
		var exploration_background := ""
		if str(root.name) == "NodeMap":
			exploration_background = "res://assets/backgrounds/phase_three/exploration_campus_wide.png"
			if not ResourceLoader.exists(exploration_background):
				exploration_background = "res://assets/backgrounds/phase_three/exploration_campus.png"
		elif str(root.name) == "CombatScreen" and bool(root.get("_exploration_mode")) and not combat_overclock:
			exploration_background = "res://assets/backgrounds/phase_three/exploration_battle_wide.png"
			if not ResourceLoader.exists(exploration_background):
				exploration_background = "res://assets/backgrounds/phase_three/exploration_battle.png"
		if exploration_background != "" and ResourceLoader.exists(exploration_background):
			path = exploration_background
		if ResourceLoader.exists(path):
			background.texture = load(path)
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		background.modulate = Color.WHITE
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match str(root.name):
		"HomeScreen":
			layout_home(root, extent)
		"NodeMap":
			layout_route(root, extent)
		"CombatScreen":
			layout_combat(root, extent)
		"DialogueScreen":
			layout_dialogue(root, extent)

static func layout_home(root: Control, _extent: Vector2) -> void:
	if root.has_method("_layout_home_scene"):
		root.call("_layout_home_scene")

static func layout_route(root: Control, extent: Vector2) -> void:
	if root.has_method("layout_exploration_map") and bool(root.get("material_exploration_mode")):
		root.call("layout_exploration_map")
		return
	place(root.get_node("TopBar"), 0, 0, extent.x, 96)
	place(root.get_node("TopBar/ChapterTitle"), 32, 24, extent.x * 0.46, 44)
	place(root.get_node("TopBar/PlayerInfo"), extent.x * 0.48, 27, 340, 42)
	place(root.get_node("TopBar/RetreatButton"), extent.x - 224, 24, 192, 48)
	if is_instance_valid(root.get("reset_route_btn")):
		place(root.get("reset_route_btn"), extent.x - 432, 24, 184, 48)
	var scroll := root.get_node("ScrollContainer") as ScrollContainer
	place(scroll, 64, 144, extent.x - 128, extent.y - 220)
	var canvas := root.get_node("ScrollContainer/MapCanvas") as Control
	canvas.custom_minimum_size = Vector2(maxf(1300, extent.x - 128), maxf(580, extent.y - 220))
	canvas.size = canvas.custom_minimum_size
	surface(canvas, "RouteSurface", Color(1.0, 0.975, 0.94, 0.85))
	root.call("_render_nodes_and_lines")
	var modal := root.get_node("EventModal") as Control
	centered(modal, extent, Vector2(760, 380))
	place(modal.get_node("VBox"), 36, 30, 688, 320)
	modal.get_node("VBox/ConfirmBtn").custom_minimum_size.y = 56
	var backdrop := root.get_node_or_null("EventBackdrop") as ColorRect
	if not backdrop:
		backdrop = ColorRect.new()
		backdrop.name = "EventBackdrop"
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.color = Color(0.25, 0.22, 0.33, 0.35)
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(backdrop)
		root.move_child(backdrop, modal.get_index())
		modal.visibility_changed.connect(func(): backdrop.visible = modal.visible)
		root.move_child(modal, -1)
	backdrop.visible = modal.visible

static func layout_combat(root: Control, extent: Vector2) -> void:
	CombatPresentation.layout(root, extent)
	if is_instance_valid(root.get("log_panel")):
		place(root.get("log_panel"), (extent.x - 1100) / 2.0, (extent.y - 650) / 2.0, 1100, 650)
		root.get("log_panel").add_theme_stylebox_override("panel", CombatSkin.paper(Vector4(44, 38, 44, 38)))
		root.get("log_text").add_theme_font_size_override("normal_font_size", 26)
		root.get("log_text").add_theme_font_size_override("bold_font_size", 26)
		root.get("log_text").add_theme_constant_override("line_separation", 6)
	var hint := root.get_node_or_null("FirstBattleHint") as HBoxContainer
	if hint:
		var factor := minf(extent.x / 1920.0, extent.y / 1080.0)
		var origin := (extent - Vector2(1920.0, 1080.0) * factor) / 2.0
		var hint_design := Vector2(380.0, 58.0)
		var hint_origin := Vector2(770.0, 224.0)
		for child in hint.get_children():
			if child is Label:
				if child.text.strip_edges().is_empty():
					child.text = "先看对方行动，再出牌。护盾只保留到本轮结束。"
				child.custom_minimum_size = Vector2(hint_design.x, hint_design.y - 4.0)
				child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				child.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				child.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				child.add_theme_font_size_override("font_size", 16)
				child.add_theme_color_override("font_color", INK)
				child.add_theme_constant_override("outline_size", 0)
			elif child is Button:
				child.custom_minimum_size = Vector2(76, 40)
				child.add_theme_font_size_override("font_size", 20)
				for state in ["normal", "hover", "pressed", "disabled"]:
					child.add_theme_stylebox_override(state, SceneSkin.style("button_secondary", Vector4(12, 3, 12, 3)))
		hint.custom_minimum_size = hint_design
		place(hint, hint_origin.x, hint_origin.y, hint_design.x, hint_design.y)
		hint.scale = Vector2.ONE * factor
		hint.position = origin + hint_origin * factor
		hint.alignment = BoxContainer.ALIGNMENT_CENTER
		hint.add_theme_constant_override("separation", 12)
		var wash := root.get_node_or_null("FirstBattleHintWash") as Panel
		if wash == null:
			wash = Panel.new()
			wash.name = "FirstBattleHintWash"
			wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var callout_path := "res://assets/ui_core/theme/ui_tutorial_callout_9slice.png"
			if ResourceLoader.exists(callout_path):
				var callout_box := StyleBoxTexture.new()
				callout_box.texture = load(callout_path) as Texture2D
				for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
					callout_box.set_texture_margin(side, 48.0)
				wash.add_theme_stylebox_override("panel", callout_box)
			else:
				var wash_box := CombatSkin.flat(Color(0.99, 0.96, 0.91, 0.92), Vector4.ZERO)
				wash_box.set_corner_radius_all(14)
				wash.add_theme_stylebox_override("panel", wash_box)
			root.add_child(wash)
			root.move_child(wash, hint.get_index())
			hint.visibility_changed.connect(func(): wash.visible = hint.visible)
		wash.visible = hint.visible
		var wash_origin := Vector2(hint_origin.x - 46.0, hint_origin.y - 10.0)
		var wash_design := Vector2(hint_design.x + 92.0, hint_design.y + 20.0)
		place(wash, wash_origin.x, wash_origin.y, wash_design.x, wash_design.y)
		wash.scale = Vector2.ONE * factor
		wash.position = origin + wash_origin * factor
	root.get_node("ResultModal").add_theme_stylebox_override("panel", CombatSkin.paper(Vector4.ZERO))
	centered(root.get_node("ResultModal"), extent, Vector2(820, 460))
	var result_box := root.get_node("ResultModal/VBox") as VBoxContainer
	place(result_box, 36, 28, 748, 404)
	result_box.add_theme_constant_override("separation", 16)
	var result_title := result_box.get_node("TitleLabel") as Label
	result_title.add_theme_font_override("font", get_theme().get_font("font", "TitleLabel"))
	result_title.add_theme_font_size_override("font_size", 40)
	result_title.custom_minimum_size.y = 68
	result_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var result_description := result_box.get_node("DescLabel") as RichTextLabel
	result_description.add_theme_font_size_override("normal_font_size", 28)
	result_description.add_theme_font_size_override("bold_font_size", 28)
	result_description.add_theme_constant_override("line_separation", 8)
	result_description.custom_minimum_size.y = 200
	result_description.scroll_active = false
	result_description.fit_content = false
	result_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var result_action := result_box.get_node("ConfirmButton") as Button
	result_action.theme_type_variation = &"PrimaryButton"
	result_action.custom_minimum_size = Vector2(330, 80)
	result_action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result_action.add_theme_font_size_override("font_size", 32)
	CombatSkin.button(result_action, true)

static func layout_dialogue(root: Control, extent: Vector2) -> void:
	var area := root.get_node("CharArea") as Control
	place(area, 0, 0, extent.x, extent.y - 332)
	area.clip_contents = true
	# Half-body actors continue behind the paper, with no feet leaking below it.
	var left_actor := area.get_node("LeftChar") as TextureRect
	var right_actor := area.get_node("RightChar") as TextureRect
	place(left_actor, 145, 80, 610, 760)
	place(right_actor, 1165, 80, 610, 760)
	for actor in [left_actor, right_actor]:
		actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var paper := root.get_node("DialogueBox") as PanelContainer
	place(paper, 64, extent.y - 344, extent.x - 128, 320)
	paper.add_theme_stylebox_override("panel", SceneSkin.style("dialogue_sheet", Vector4.ZERO, Color(1, 1, 1, 0.98)))
	paper.mouse_filter = Control.MOUSE_FILTER_PASS
	var margin := root.get_node("DialogueBox/Margin") as MarginContainer
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	var vbox := root.get_node("DialogueBox/Margin/VBox") as VBoxContainer
	vbox.add_theme_constant_override("separation", 0)
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	var name := root.get_node("DialogueBox/Margin/VBox/Nameplate") as Label
	name.add_theme_font_size_override("font_size", 38)
	name.custom_minimum_size.y = 96
	name.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body := root.get_node("DialogueBox/Margin/VBox/TextLabel") as RichTextLabel
	body.add_theme_font_size_override("normal_font_size", 32)
	body.add_theme_font_size_override("bold_font_size", 32)
	body.add_theme_constant_override("line_separation", 12)
	body.custom_minimum_size.y = 150
	body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body.fit_content = false
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var continue_hint := vbox.get_node_or_null("ContinueHint") as Label
	if not continue_hint:
		continue_hint = Label.new()
		continue_hint.name = "ContinueHint"
		continue_hint.text = "点击继续"
		continue_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(continue_hint)
	continue_hint.custom_minimum_size.y = 50
	continue_hint.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	continue_hint.add_theme_font_size_override("font_size", 24)
	continue_hint.add_theme_color_override("font_color", MUTED)
	var choices := root.get_node("ChoicesArea") as PanelContainer
	place(choices, (extent.x - 860) / 2.0, maxf(300, paper.position.y - 232), 860, 220)
	choices.add_theme_stylebox_override("panel", panel_style(PAPER, BORDER, 24))
	var options := root.get_node("ChoicesArea/ChoicesContainer") as VBoxContainer
	options.add_theme_constant_override("separation", 12)
	for option in options.get_children():
		if option is Button:
			bind_button_feedback(option)
			option.custom_minimum_size.y = 72
			option.add_theme_font_size_override("font_size", 32)
	if not options.has_meta("DaylightChoiceFontsBound"):
		options.set_meta("DaylightChoiceFontsBound", true)
		options.child_entered_tree.connect(func(child: Node) -> void:
			if child is Button:
				bind_button_feedback(child)
				child.custom_minimum_size.y = 72
				child.add_theme_font_size_override("font_size", 32)
		)
	if not choices.has_meta("DaylightContinueHintBound"):
		choices.set_meta("DaylightContinueHintBound", true)
		choices.visibility_changed.connect(func() -> void:
			if is_instance_valid(continue_hint):
				continue_hint.visible = not choices.visible
		)
	continue_hint.visible = not choices.visible
	var controls := root.get_node("ControlBar") as HBoxContainer
	place(controls, extent.x - 392, 24, 360, 64)
	controls.add_theme_constant_override("separation", 12)
	for button in controls.get_children():
		if button is Button:
			button.custom_minimum_size = Vector2(174, 64)
			button.add_theme_font_size_override("font_size", 26)
	var pause := root.get_node_or_null("PauseButton") as Button
	if pause:
		pause.custom_minimum_size = Vector2(180, 60)
		pause.add_theme_font_size_override("font_size", 26)
		place(pause, 32, 24, 180, 60)
