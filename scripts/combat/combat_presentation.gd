class_name CombatPresentation
extends RefCounted

## Responsive 1920x1080 central combat layout over a full-bleed backdrop
## with edge-to-edge top indigo ribbon and modular watercolor notebook tray.
const DESIGN := Vector2(1920, 1080)
const CARD_SIZE := Vector2(242, 340)
const CARD_GAP := 10.0
const TRAY_PATH := "res://assets/combat/notebook_tray_9slice.png"
const STICKY_PATH := "res://assets/combat/notebook_sticky_target.png"
const PLAQUE_PATH := "res://assets/combat/status_plaque.png"

static func _root_place(node: Control, point: Vector2, extent: Vector2, scale_factor: float, origin: Vector2) -> void:
	DaylightUI.place(node, point.x, point.y, extent.x, extent.y)
	node.scale = Vector2.ONE * scale_factor
	node.position = origin + point * scale_factor

static func _text(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int, color: Color = NotebookUI.INK) -> Label:
	var node := parent.get_node_or_null(node_name) as Label
	if node == null: node = NotebookUI.label(parent, node_name, copy, rect.position, rect.size, font_size, color)
	elif not copy.is_empty(): node.text = copy
	DaylightUI.place(node, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node

static func _header_button(button: Button, copy: String) -> void:
	button.text = copy
	button.custom_minimum_size = Vector2.ZERO
	button.add_theme_font_size_override("font_size", 26)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.24, 0.30, 0.45, 0.85)
	normal.border_color = Color(1.0, 0.96, 0.88, 0.42)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.32, 0.38, 0.54, 0.92)
	hover.border_color = Color(1.0, 0.96, 0.88, 0.65)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.19, 0.24, 0.37, 0.95)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]: button.add_theme_color_override(state, Color("#FFF8EC"))
	button.add_theme_color_override("font_disabled_color", Color("#AEB4C2"))
	SchoolObjectUI.borderless(button)

static func _plaque(parent: Control, node_name: String, point: Vector2, extent: Vector2) -> TextureRect:
	var paper := parent.get_node_or_null(node_name) as TextureRect
	if paper == null:
		paper = TextureRect.new()
		paper.name = node_name
		paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		paper.stretch_mode = TextureRect.STRETCH_SCALE
		var path := PLAQUE_PATH if ResourceLoader.exists(PLAQUE_PATH) else "res://assets/ui/combat_notebook/status_note.png"
		paper.texture = load(path) as Texture2D
		parent.add_child(paper)
		parent.move_child(paper, 0)
	DaylightUI.place(paper, point.x, point.y, extent.x, extent.y)
	return paper

static func _ensure_panel(parent: Control, node_name: String, fill: Color, border: Color, radius: int, border_bottom: int = 1) -> Panel:
	var panel := parent.get_node_or_null(node_name) as Panel
	if panel == null:
		panel = Panel.new()
		panel.name = node_name
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(panel)
		parent.move_child(panel, 0)
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	if border_bottom > 1:
		box.set_border_width_all(0)
		box.border_width_bottom = border_bottom
	else:
		box.set_border_width_all(1 if border.a > 0.01 else 0)
	box.set_corner_radius_all(radius)
	panel.add_theme_stylebox_override("panel", box)
	return panel

static func layout(root: Control, extent: Vector2) -> void:
	var safe_extent := extent if extent.x > 0.0 and extent.y > 0.0 else DESIGN
	var factor := minf(safe_extent.x / DESIGN.x, safe_extent.y / DESIGN.y)
	var origin := (safe_extent - DESIGN * factor) / 2.0
	var old_comp := root.get_node_or_null("PaintedCombatComposition") as CanvasItem
	if is_instance_valid(old_comp): old_comp.visible = false
	var old_bleed := root.get_node_or_null("_PlatformEdgeBleed") as CanvasItem
	if is_instance_valid(old_bleed): old_bleed.visible = false
	var bg := root.get_node_or_null("Background") as TextureRect
	if bg:
		bg.visible = true
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	var full_left := -origin.x / maxf(factor, 0.001)
	var full_width := safe_extent.x / maxf(factor, 0.001)

	var header := root.get_node("TopInfo") as Control
	_root_place(header, Vector2.ZERO, Vector2(1920, 88), factor, origin)
	var ribbon := _ensure_panel(header, "TopHeaderRibbon", Color(0.15, 0.19, 0.30, 0.94), Color(0.90, 0.85, 0.76, 0.72), 0, 2)
	var ribbon_path := "res://assets/ui_core/theme/ribbon_header_9slice.png"
	if ResourceLoader.exists(ribbon_path):
		var ribbon_atlas := AtlasTexture.new()
		ribbon_atlas.atlas = load(ribbon_path) as Texture2D
		ribbon_atlas.region = Rect2(12, 14, 996, 98)
		ribbon_atlas.filter_clip = true
		var ribbon_style := StyleBoxTexture.new()
		ribbon_style.texture = ribbon_atlas
		ribbon_style.texture_margin_left = 56
		ribbon_style.texture_margin_right = 56
		ribbon_style.texture_margin_top = 18
		ribbon_style.texture_margin_bottom = 18
		ribbon.add_theme_stylebox_override("panel", ribbon_style)
	DaylightUI.place(ribbon, full_left - 8.0, 0.0, full_width + 16.0, 84.0)
	var turn_tab := _ensure_panel(header, "TurnTabPaper", Color("#FBF4E6"), Color("#D4C4AD"), 10)
	DaylightUI.place(turn_tab, 780, 8, 360, 68)
	header.move_child(ribbon, 0)
	header.move_child(turn_tab, 1)

	var turn := header.get_node("TurnBanner") as Label
	DaylightUI.place(turn, 780, 8, 360, 68)
	turn.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	turn.add_theme_font_size_override("font_size", 40)
	turn.add_theme_color_override("font_color", NotebookUI.INK)
	turn.add_theme_constant_override("outline_size", 0)
	turn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var round_label := header.get_node("RoundLabel") as Label
	DaylightUI.place(round_label, 1410, 14, 200, 56)
	round_label.add_theme_font_size_override("font_size", 28)
	round_label.add_theme_color_override("font_color", Color("#FFF8EC"))
	round_label.add_theme_constant_override("outline_size", 0)
	round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var loc := _text(header, "EncounterLocation", "校园练习" if bool(root.get("_exploration_mode")) else "校园侧门", Rect2(236, 14, 240, 56), 28, Color("#FFF8EC"))
	loc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var pause := header.get_node_or_null("EscapeButton") as Button
	if pause:
		_header_button(pause, "逃跑 · 判负")
		DaylightUI.place(pause, 28, 13, 180, 56)
	var history := header.get_node_or_null("CombatHistoryButton") as Button
	if history:
		_header_button(history, "回合记录")
		DaylightUI.place(history, 1640, 13, 244, 56)

	var enemy_area := root.get_node("EnemyArea") as Control
	_root_place(enemy_area, Vector2(1010, 108), Vector2(850, 544), factor, origin)
	var enemies := enemy_area.get_node("EnemiesContainer") as HBoxContainer
	var count := maxi(1, enemies.get_child_count())
	var unit_width := (850.0 - 22.0 * (count - 1)) / count
	enemies.add_theme_constant_override("separation", 22)
	for unit in enemies.get_children():
		if unit is Control and unit.has_method("layout_stage"): unit.call("layout_stage", Vector2(unit_width, 544))

	var player_area := root.get_node("PlayerArea") as Control
	_root_place(player_area, Vector2(68, 108), Vector2(740, 544), factor, origin)
	var player := player_area.get_node("ProtagonistSprite") as TextureRect
	player.texture = CombatSkin.actor_texture("res://assets/sprites/characters/phase_three/combat/ye_zhou_idle.png")
	player.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	player.flip_h = false
	DaylightUI.place(player, 390, 0 if count == 1 else 86, 310, 524 if count == 1 else 430)

	_plaque(player_area, "PlayerIdentity", Vector2(8, 12), Vector2(364, 140))
	var p_name := _text(player_area, "PlayerName", "叶舟", Rect2(72, 36, 260, 34), 28)
	p_name.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	var hp := player_area.get_node("PlayerHPBar") as ProgressBar
	DaylightUI.place(hp, 72, 78, 256, 18)
	hp.add_theme_stylebox_override("background", CombatSkin.flat(Color("#E2DACB"), Vector4.ZERO))
	hp.add_theme_stylebox_override("fill", CombatSkin.flat(Color("#6D9C7E"), Vector4.ZERO))
	var hp_label := hp.get_node("HPLabel") as Label
	DaylightUI.place(hp_label, 0, 21, 256, 26)
	hp_label.add_theme_font_size_override("font_size", 22)
	hp_label.add_theme_color_override("font_color", NotebookUI.INK)

	var tactical_pill := _ensure_panel(player_area, "PlayerTacticalPill", Color(0.98, 0.96, 0.91, 0.93), Color("#C8BCA9"), 12)
	DaylightUI.place(tactical_pill, 18, 158, 344, 96)
	var shield := player_area.get_node("PlayerShieldLabel") as Label
	DaylightUI.place(shield, 34, 166, 312, 30)
	shield.add_theme_font_size_override("font_size", 22)
	shield.add_theme_constant_override("outline_size", 0)
	var status := player_area.get_node("PlayerStatusLabel") as Label
	DaylightUI.place(status, 34, 198, 312, 50)
	status.add_theme_font_size_override("font_size", 20)
	status.add_theme_color_override("font_color", NotebookUI.INK)
	status.add_theme_constant_override("outline_size", 0)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var hand := root.get_node("HandArea") as Control
	_root_place(hand, Vector2(0, 650), Vector2(1920, 430), factor, origin)
	var tray := hand.get_node_or_null("NotebookTray") as NinePatchRect
	if tray == null and ResourceLoader.exists(TRAY_PATH):
		tray = NinePatchRect.new()
		tray.name = "NotebookTray"
		tray.texture = load(TRAY_PATH) as Texture2D
		tray.patch_margin_left = 220
		tray.patch_margin_top = 80
		tray.patch_margin_right = 56
		tray.patch_margin_bottom = 68
		tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hand.add_child(tray)
		hand.move_child(tray, 0)
	if tray:
		DaylightUI.place(tray, minf(-18.0, full_left - 18.0), -44.0, full_width + 42.0, 492.0)

	var sticky := hand.get_node_or_null("TargetStickyNote") as TextureRect
	if sticky == null and ResourceLoader.exists(STICKY_PATH):
		sticky = TextureRect.new()
		sticky.name = "TargetStickyNote"
		sticky.texture = load(STICKY_PATH) as Texture2D
		sticky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sticky.stretch_mode = TextureRect.STRETCH_SCALE
		sticky.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hand.add_child(sticky)
		hand.move_child(sticky, 1 if tray else 0)
	if sticky:
		DaylightUI.place(sticky, 1456, 18, 434, 396)

	var heading := _text(hand, "HandbookHeading", "行动手册", Rect2(198, 35, 168, 30), 25)
	heading.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	var platform := root.get_node_or_null("/root/Platform") as PlatformService
	var touch := platform != null and platform.is_touch()
	_text(hand, "HandbookHint", "轻触选牌 · 再点或上滑打出" if touch else "点击出牌 · 先观察对方意图", Rect2(368, 37, 500, 28), 21, NotebookUI.MUTED)

	var cards := hand.get_node("CardsContainer") as HBoxContainer
	DaylightUI.place(cards, 174, 74, 1256, 340)
	cards.custom_minimum_size = Vector2.ZERO
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", int(CARD_GAP))
	for card in cards.get_children():
		if card.has_method("layout_notebook_card"): card.call("layout_notebook_card", CARD_SIZE)

	for old_photo in ["TargetPhotoPaper", "TargetPhotoBacking"]:
		var node := hand.get_node_or_null(old_photo) as CanvasItem
		if is_instance_valid(node): node.visible = false

	_text(hand, "TargetHeading", "当前目标", Rect2(1490, 68, 180, 28), 21, Color("#6C5482"))
	var target := _text(hand, "TargetCopy", "", Rect2(1490, 100, 250, 36), 27)
	target.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	target.autowrap_mode = TextServer.AUTOWRAP_OFF
	var target_description := _text(hand, "TargetDescription", "", Rect2(1490, 138, 250, 122), 20, NotebookUI.INK)
	target_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var portrait_frame := _ensure_panel(hand, "TargetPortraitFrame", Color("#FFFDF8"), Color("#D0C3AE"), 8)
	DaylightUI.place(portrait_frame, 1756, 102, 90, 98)
	hand.move_child(portrait_frame, sticky.get_index() + 1 if sticky else 1)
	var portrait := hand.get_node_or_null("TargetPortrait") as TextureRect
	if portrait == null:
		portrait = TextureRect.new()
		portrait.name = "TargetPortrait"
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		hand.add_child(portrait)
	DaylightUI.place(portrait, 1760, 106, 82, 90)
	hand.move_child(portrait, portrait_frame.get_index() + 1)

	var end_button := root.get("end_turn_btn") as Button
	if is_instance_valid(end_button):
		CombatSkin.button(end_button, true)
		DaylightUI.place(end_button, 1490, 272, 354, 72)
		end_button.add_theme_font_size_override("font_size", 33)
	var cd_copy := _text(hand, "CooldownCopy", "下回合推进冷却", Rect2(1490, 348, 354, 30), 21, NotebookUI.MUTED)
	cd_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.call("_refresh_tactical_note")
