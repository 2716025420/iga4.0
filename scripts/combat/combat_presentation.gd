class_name CombatPresentation
extends RefCounted

## Responsive 1920x1080 central combat layout over a full-bleed backdrop
## with edge-to-edge top indigo ribbon and modular watercolor notebook tray.
const DESIGN := Vector2(1920, 1080)
const CARD_SIZE := Vector2(242, 340)
const CARD_GAP := 8.0
const TRAY_PATH := "res://assets/combat/notebook_tray_9slice.png"
const STICKY_PATH := "res://assets/combat/notebook_sticky_target.png"
const PLAQUE_PATH := "res://assets/combat/status_plaque.png"
const ZODIAC_HALO_PATH := "res://assets/ui_core/animations/ui_zodiac_resonance_halo.png"
const REDMOON_HUD_PATH := "res://assets/ui_core/animations/ui_redmoon_hud_pulse.png"
const CUTIN_BANNER_PATH := "res://assets/ui_core/animations/ui_companion_cutin_banner.png"
const ICON_SHIELD := "res://assets/ui_core/icons/combat/shield.svg"
const ICON_ATK := "res://assets/ui_core/icons/combat/atk_single.svg"
const ICON_REFLECT := "res://assets/ui_core/icons/combat/reflect_counter.svg"
const ICON_ASSIST := "res://assets/ui_core/icons/combat/companion_assist.svg"
const ENEMY_SLOT_SIZE := Vector2(332.0, 572.0)
const ENEMY_GAP := 22.0
const TEAM_CENTER_OFFSET := 460.0
const SOLO_SLOT_SIZE := Vector2(224.0, 572.0)
const DUO_SLOT_SIZE := Vector2(168.0, 572.0)
const DUO_GAP := 16.0
const ENEMY_2V2_SLOT_SIZE := DUO_SLOT_SIZE
const ENEMY_2V2_GAP := DUO_GAP
const DUEL_CREST_PATH := "res://assets/ui_core/vfx/svg_duel_crest_vs.svg"
const REDMOON_RETICLE_PATH := "res://assets/ui_core/vfx/svg_red_moon_reticle.svg"
const CHIP_PALETTES := {
	"shield": {"bg": Color("#EAF2F8"), "border": Color("#7BA1BF"), "ink": Color("#234B6B")},
	"muted": {"bg": Color("#F3EFE6"), "border": Color("#C9BFB0"), "ink": Color("#6F7078")},
	"danger": {"bg": Color("#FCECEA"), "border": Color("#D47E78"), "ink": Color("#9E2F2A")},
	"safe": {"bg": Color("#EAF4EE"), "border": Color("#72A386"), "ink": Color("#2B6244")},
	"burn": {"bg": Color("#FCECE8"), "border": Color("#D67963"), "ink": Color("#A33722")},
	"weak": {"bg": Color("#F4EBF6"), "border": Color("#B085B8"), "ink": Color("#64376E")},
	"reflect": {"bg": Color("#FDF3DF"), "border": Color("#C49E5A"), "ink": Color("#7A5318")},
	"assist": {"bg": Color("#EEF2F7"), "border": Color("#7D96B2"), "ink": Color("#2E4A6B")},
	"assist_ready": {"bg": Color("#FCF0CA"), "border": Color("#C79332"), "ink": Color("#6E480F")},
	"intent_atk": {"bg": Color("#FDF1EE"), "border": Color("#D28B80"), "ink": Color("#8E2E29")},
	"intent_def": {"bg": Color("#EEF4FA"), "border": Color("#86A7C4"), "ink": Color("#2B5373")},
	"intent_heal": {"bg": Color("#ECF5EF"), "border": Color("#7CA98D"), "ink": Color("#2E6145")},
	"intent_debuff": {"bg": Color("#F5EDF7"), "border": Color("#B188BA"), "ink": Color("#62376B")},
	"intent_mix": {"bg": Color("#FFF8EC"), "border": Color("#C4B49A"), "ink": Color("#232C36")},
}

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

## Build a soft tinted pill StyleBoxFlat keyed from CHIP_PALETTES.
static func status_chip_style(palette_key: String, pad_x: float = 9.0, pad_y: float = 2.0) -> StyleBoxFlat:
	var pal: Dictionary = CHIP_PALETTES.get(palette_key, CHIP_PALETTES["muted"])
	var box := StyleBoxFlat.new()
	box.bg_color = pal.get("bg", Color("#F3EFE6"))
	box.border_color = pal.get("border", Color("#C9BFB0"))
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	return box

## Create or update a compact [SVG Icon + Number] pill chip inside a horizontal status bar.
static func sync_status_chip(row: HBoxContainer, chip_name: String, icon_path: String, copy: String, palette_key: String, icon_name: String = "ChipIcon") -> PanelContainer:
	var chip := row.get_node_or_null(chip_name) as PanelContainer
	var hbox: HBoxContainer
	var icon_rect: TextureRect
	var lbl: Label
	if chip == null:
		chip = PanelContainer.new()
		chip.name = chip_name
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.custom_minimum_size = Vector2(0, 28)
		hbox = HBoxContainer.new()
		hbox.name = "ChipRow"
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 4)
		chip.add_child(hbox)
		icon_rect = TextureRect.new()
		icon_rect.name = icon_name
		icon_rect.custom_minimum_size = Vector2(18, 18)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon_rect)
		lbl = Label.new()
		lbl.name = "ChipLabel"
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		lbl.clip_text = false
		lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_constant_override("outline_size", 0)
		hbox.add_child(lbl)
		row.add_child(chip)
	else:
		hbox = chip.get_node("ChipRow") as HBoxContainer
		for child in hbox.get_children():
			if child is TextureRect:
				icon_rect = child as TextureRect
				if icon_rect.name != icon_name:
					icon_rect.name = icon_name
			elif child is Label:
				lbl = child as Label
	var pal: Dictionary = CHIP_PALETTES.get(palette_key, CHIP_PALETTES["muted"])
	chip.add_theme_stylebox_override("panel", status_chip_style(palette_key))
	if is_instance_valid(icon_rect):
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon_rect.texture = load(icon_path) as Texture2D
			icon_rect.visible = true
		else:
			icon_rect.visible = false
	if is_instance_valid(lbl):
		lbl.text = copy
		lbl.add_theme_color_override("font_color", pal.get("ink", NotebookUI.INK))
	chip.visible = true
	return chip

static func layout(root: Control, extent: Vector2) -> void:
	var safe_extent := extent if extent.x > 0.0 and extent.y > 0.0 else DESIGN
	var factor := minf(safe_extent.x / DESIGN.x, safe_extent.y / DESIGN.y)
	var origin := (safe_extent - DESIGN * factor) / 2.0
	var old_comp := root.get_node_or_null("PaintedCombatComposition") as CanvasItem
	if is_instance_valid(old_comp): old_comp.visible = false
	var old_bleed := root.get_node_or_null("_PlatformEdgeBleed") as CanvasItem
	if is_instance_valid(old_bleed): old_bleed.visible = false
	var bg := root.get_node_or_null("Background") as TextureRect
	var sports_field := is_sports_field_arena(root)
	if bg:
		bg.visible = true
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if sports_field:
			bg.offset_top = -236.0 * factor
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_layout_redmoon_hud(root)

	var full_left := -origin.x / maxf(factor, 0.001)
	var full_width := safe_extent.x / maxf(factor, 0.001)
	_layout_stage_zones(root, factor, origin, full_left, full_width, is_overclock_combat(root))

	var header := root.get_node("TopInfo") as Control
	_root_place(header, Vector2.ZERO, Vector2(1920, 78), factor, origin)
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
	DaylightUI.place(ribbon, full_left - 8.0, 0.0, full_width + 16.0, 76.0)
	var turn_tab := _ensure_panel(header, "TurnTabPaper", Color("#FBF4E6"), Color("#D4C4AD"), 10)
	DaylightUI.place(turn_tab, 780, 6, 360, 62)
	header.move_child(ribbon, 0)
	header.move_child(turn_tab, 1)

	var turn := header.get_node("TurnBanner") as Label
	DaylightUI.place(turn, 780, 6, 360, 62)
	turn.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	turn.add_theme_font_size_override("font_size", 38)
	turn.add_theme_color_override("font_color", NotebookUI.INK)
	turn.add_theme_constant_override("outline_size", 0)
	turn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var round_label := header.get_node("RoundLabel") as Label
	DaylightUI.place(round_label, 1410, 10, 200, 54)
	round_label.add_theme_font_size_override("font_size", 27)
	round_label.add_theme_color_override("font_color", Color("#FFF8EC"))
	round_label.add_theme_constant_override("outline_size", 0)
	round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var encounter_copy := "校园练习" if bool(root.get("_exploration_mode")) else "旧公园街角"
	if str(GameState.pending_combat_data.get("mode", "")) == "qualifier":
		encounter_copy = "阿瑞忒选拔赛 · 第%d战" % int(GameState.pending_combat_data.get("qualifier_round", 1))
	elif GameState.current_node_id == "n_gate":
		encounter_copy = "操场海选赛 · 2v2"
	var loc := _text(header, "EncounterLocation", encounter_copy, Rect2(236, 10, 260, 54), 27, Color("#FFF8EC"))
	loc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var pause := header.get_node_or_null("EscapeButton") as Button
	if pause:
		_header_button(pause, "逃跑 · 判负")
		DaylightUI.place(pause, 28, 10, 180, 54)
	var history := header.get_node_or_null("CombatHistoryButton") as Button
	if history:
		_header_button(history, "回合记录")
		DaylightUI.place(history, 1640, 10, 244, 54)

	var enemy_area := root.get_node("EnemyArea") as Control
	var enemies := enemy_area.get_node("EnemiesContainer") as HBoxContainer
	var enemy_count := maxi(1, enemies.get_child_count())
	var enemy_slot := SOLO_SLOT_SIZE if enemy_count == 1 else DUO_SLOT_SIZE
	var enemy_gap := 0 if enemy_count == 1 else int(DUO_GAP)
	var enemy_area_w := enemy_slot.x * float(enemy_count) + float(enemy_gap * maxi(0, enemy_count - 1))
	var enemy_area_x := (960.0 + TEAM_CENTER_OFFSET) - enemy_area_w * 0.5
	_root_place(enemy_area, Vector2(enemy_area_x, 80.0), Vector2(enemy_area_w, 576.0), factor, origin)
	enemy_area.clip_contents = false
	DaylightUI.place(enemies, 0.0, 0.0, enemy_area_w, 572.0)
	enemies.clip_contents = false
	enemies.alignment = BoxContainer.ALIGNMENT_CENTER
	enemies.add_theme_constant_override("separation", enemy_gap)
	for unit in enemies.get_children():
		if unit is Control and unit.has_method("layout_stage"):
			unit.call("layout_stage", enemy_slot)

	var old_emblems := root.get_node_or_null("ArenaEmblems")
	if is_instance_valid(old_emblems):
		old_emblems.queue_free()
	var old_reticle := enemy_area.get_node_or_null("RedMoonReticle")
	if is_instance_valid(old_reticle):
		old_reticle.queue_free()

	var player_area := root.get_node("PlayerArea") as Control
	_root_place(player_area, Vector2(0.0, 80.0), Vector2(960.0, 576.0), factor, origin)
	player_area.clip_contents = false
	var companion_id := str(root.get("_companion_id")) if root.get("_companion_id") != null else ""
	var comp_path := CombatSkin.character_combat_path(companion_id) if companion_id != "" and companion_id != "ye_zhou" else ""
	var has_comp_actor := comp_path != ""
	var team_left_center := 960.0 - TEAM_CENTER_OFFSET

	var player := player_area.get_node("ProtagonistSprite") as TextureRect
	player.texture = CombatSkin.actor_texture("res://assets/sprites/characters/phase_three/combat/ye_zhou_idle.png")
	player.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	player.flip_h = false
	var player_center_x := (team_left_center + 92.0) if has_comp_actor else team_left_center
	var player_foot_y := 554.0
	_place_actor_on_floor(player, player_center_x, 276.0 if has_comp_actor else 284.0, 404.0, player_foot_y)
	player.set_meta("lunge_base_pos", player.position)
	var p_shadow := player_area.get_node_or_null("PlayerGroundShadow") as TextureRect
	if p_shadow == null:
		p_shadow = DaylightUI.soft_ground_shadow(player_area, "PlayerGroundShadow", Vector2.ZERO, Vector2(210, 28))
		player_area.move_child(p_shadow, player.get_index())
	var p_shadow_w := 190.0 if has_comp_actor else 200.0
	DaylightUI.place(p_shadow, player_center_x - p_shadow_w * 0.5, player_foot_y - 15.0, p_shadow_w, 28.0)

	var companion := player_area.get_node_or_null("CompanionSprite") as TextureRect
	if companion == null:
		companion = TextureRect.new()
		companion.name = "CompanionSprite"
		companion.mouse_filter = Control.MOUSE_FILTER_IGNORE
		companion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		companion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		companion.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		player_area.add_child(companion)
		player_area.move_child(companion, player.get_index())
	var c_shadow := player_area.get_node_or_null("CompanionGroundShadow") as TextureRect
	if has_comp_actor:
		companion.texture = CombatSkin.actor_texture(comp_path)
		companion.visible = companion.texture != null
		var comp_center_x := team_left_center - 92.0
		var comp_foot_y := 554.0
		_place_actor_on_floor(companion, comp_center_x, 224.0, 380.0, comp_foot_y)
		companion.set_meta("lunge_base_pos", companion.position)
		if c_shadow == null:
			c_shadow = DaylightUI.soft_ground_shadow(player_area, "CompanionGroundShadow", Vector2.ZERO, Vector2(168, 26))
			player_area.move_child(c_shadow, companion.get_index())
		c_shadow.visible = companion.visible
		DaylightUI.place(c_shadow, comp_center_x - 84.0, comp_foot_y - 14.0, 168.0, 26.0)
	else:
		companion.visible = false
		if is_instance_valid(c_shadow):
			c_shadow.visible = false

	var std_identity := _plaque(player_area, "PlayerIdentity", Vector2(254, 2), Vector2(404, 84))
	std_identity.visible = false
	var p_name := _text(player_area, "PlayerName", "叶舟", Rect2(314, 10, 84, 25), 18, Color("#232C36"))
	p_name.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	p_name.add_theme_constant_override("outline_size", 0)
	p_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var hp := player_area.get_node("PlayerHPBar") as ProgressBar
	hp.clip_contents = false
	var hp_label := hp.get_node("HPLabel") as Label
	hp_label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	hp_label.add_theme_constant_override("outline_size", 0)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var compact_comp_box := player_area.get_node_or_null("CompanionIdentityBox") as Panel
	var compact_player_box := player_area.get_node_or_null("PlayerCompactBox") as Panel
	var player_role_lbl := player_area.get_node_or_null("PlayerRoleLabel") as Label
	if has_comp_actor:
		var comp_box_x := (team_left_center - 92.0) - 84.0
		compact_comp_box = _ensure_compact_identity_box(player_area, "CompanionIdentityBox", false)
		compact_comp_box.visible = true
		DaylightUI.place(compact_comp_box, comp_box_x, 12, 168, 76)
		var comp_name_lbl := _text(compact_comp_box, "CompanionNameLabel", "", Rect2(10, 6, 98, 24), 18, Color("#232C36"))
		comp_name_lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
		comp_name_lbl.add_theme_constant_override("outline_size", 0)
		comp_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var comp_role_lbl := _text(compact_comp_box, "CompanionRoleLabel", "支援", Rect2(110, 8, 48, 20), 14, Color("#6F6A62"))
		comp_role_lbl.add_theme_constant_override("outline_size", 0)
		comp_role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		comp_role_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var comp_div := compact_comp_box.get_node_or_null("CompanionDivider") as ColorRect
		if comp_div == null:
			comp_div = ColorRect.new()
			comp_div.name = "CompanionDivider"
			comp_div.color = Color("#D7CCB9")
			comp_div.mouse_filter = Control.MOUSE_FILTER_IGNORE
			compact_comp_box.add_child(comp_div)
		DaylightUI.place(comp_div, 10, 34, 148, 1)
		var comp_skill_lbl := _text(compact_comp_box, "CompanionSkillLabel", "", Rect2(10, 40, 148, 28), 13, Color("#566575"))
		comp_skill_lbl.add_theme_constant_override("outline_size", 0)
		comp_skill_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		comp_skill_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		comp_skill_lbl.clip_text = true

		var p_box_x := player_center_x - 84.0
		compact_player_box = _ensure_compact_identity_box(player_area, "PlayerCompactBox", false)
		compact_player_box.visible = true
		DaylightUI.place(compact_player_box, p_box_x, 12, 168, 76)
		DaylightUI.place(p_name, p_box_x + 10.0, 18, 64, 24)
		p_name.add_theme_font_size_override("font_size", 18)
		DaylightUI.place(hp, p_box_x + 10.0, 46, 148, 9)
		DaylightUI.place(hp_label, 62, -28, 86, 22)
		hp_label.add_theme_font_size_override("font_size", 14)
		hp_label.add_theme_color_override("font_color", Color("#3B444E"))
		player_role_lbl = _text(player_area, "PlayerRoleLabel", "主战", Rect2(p_box_x + 10.0, 59, 54, 22), 14, Color("#6F6A62"))
		player_role_lbl.visible = true
		player_role_lbl.add_theme_constant_override("outline_size", 0)
		player_role_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		if is_instance_valid(compact_comp_box):
			compact_comp_box.visible = false
		var p_solo_x := player_center_x - 112.0
		compact_player_box = _ensure_compact_identity_box(player_area, "PlayerCompactBox", false)
		compact_player_box.visible = true
		DaylightUI.place(compact_player_box, p_solo_x, 12, 224, 76)
		DaylightUI.place(p_name, p_solo_x + 12.0, 18, 78, 24)
		p_name.add_theme_font_size_override("font_size", 18)
		DaylightUI.place(hp, p_solo_x + 12.0, 46, 200, 10)
		DaylightUI.place(hp_label, 104, -28, 96, 22)
		hp_label.add_theme_font_size_override("font_size", 15)
		hp_label.add_theme_color_override("font_color", Color("#3B444E"))
		player_role_lbl = _text(player_area, "PlayerRoleLabel", "主战", Rect2(p_solo_x + 12.0, 59, 64, 22), 14, Color("#6F6A62"))
		player_role_lbl.visible = true
		player_role_lbl.add_theme_constant_override("outline_size", 0)
		player_role_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp.add_theme_stylebox_override("background", CombatSkin.flat(Color("#E2DACB"), Vector4.ZERO))
	hp.add_theme_stylebox_override("fill", CombatSkin.flat(Color("#6D9C7E"), Vector4.ZERO))

	var tactical_pill := _ensure_panel(player_area, "PlayerTacticalPill", Color(0.98, 0.96, 0.91, 0.93), Color("#C8BCA9"), 10)
	tactical_pill.visible = false
	var shield := player_area.get_node("PlayerShieldLabel") as Label
	shield.visible = false
	var status := player_area.get_node("PlayerStatusLabel") as Label
	status.visible = false

	var comp_pill := _ensure_panel(player_area, "CompanionResonancePill", Color(0.96, 0.94, 0.89, 0.94), Color("#B9975B"), 10)
	comp_pill.visible = false
	var halo := player_area.get_node_or_null("ZodiacHaloEmblem") as TextureRect
	if is_instance_valid(halo):
		halo.visible = false
	var comp_badge := _text(player_area, "CompanionAssistBadge", "", Rect2(314, 54, 288, 22), 15, Color("#386485"))
	comp_badge.visible = false
	var res_badge_rect := Rect2(player_center_x - 10.0, 59, 92, 22) if has_comp_actor else Rect2(player_center_x - 32.0, 59, 132, 22)
	var res_badge := _text(player_area, "ZodiacResonanceBadge", "", res_badge_rect, 13, Color("#6E4E86"))
	res_badge.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	res_badge.add_theme_constant_override("outline_size", 0)
	res_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	res_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	res_badge.autowrap_mode = TextServer.AUTOWRAP_OFF
	res_badge.clip_text = true
	var p_status_icons := player_area.get_node_or_null("PlayerStatusIcons") as HBoxContainer
	if p_status_icons == null:
		p_status_icons = HBoxContainer.new()
		p_status_icons.name = "PlayerStatusIcons"
		p_status_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p_status_icons.alignment = BoxContainer.ALIGNMENT_CENTER
		player_area.add_child(p_status_icons)
	p_status_icons.add_theme_constant_override("separation", 5 if has_comp_actor else 6)
	var status_w := 288.0 if has_comp_actor else 300.0
	DaylightUI.place(p_status_icons, player_center_x - status_w * 0.5, 94, status_w, 30)
	update_badges(root)

	var hand := root.get_node("HandArea") as Control
	_root_place(hand, Vector2(0, 654), Vector2(1920, 426), factor, origin)
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

	var old_deck_back := hand.get_node_or_null("DuelDeckBack")
	if is_instance_valid(old_deck_back):
		hand.remove_child(old_deck_back)
		old_deck_back.queue_free()
	_layout_resonance_seal(root, hand)

	var heading := _text(hand, "HandbookHeading", "行动手册", Rect2(198, 35, 168, 30), 25)
	heading.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	var platform := root.get_node_or_null("/root/Platform") as PlatformService
	var touch := platform != null and platform.is_touch()
	_text(hand, "HandbookHint", "轻触选牌 · 再点或上滑打出" if touch else "点击出牌 · 先观察对方意图", Rect2(368, 37, 500, 28), 21, NotebookUI.MUTED)

	var cards := hand.get_node("CardsContainer") as HBoxContainer
	DaylightUI.place(cards, 200, 67, 1246, 340)
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

static func _place_actor_on_floor(rect_node: TextureRect, center_x: float, max_w: float, max_h: float, foot_y: float) -> void:
	var draw_size := Vector2(max_w, max_h)
	if rect_node.texture != null:
		var tsize := rect_node.texture.get_size()
		if tsize.x > 0.0 and tsize.y > 0.0:
			var sc := minf(max_w / tsize.x, max_h / tsize.y)
			draw_size = tsize * sc
	DaylightUI.place(rect_node, center_x - draw_size.x * 0.5, foot_y - draw_size.y, draw_size.x, draw_size.y)

static func _layout_stage_zones(root: Control, factor: float, origin: Vector2, full_left: float, full_width: float, overclock: bool) -> void:
	var player_area := root.get_node("PlayerArea") as Control
	var zones := root.get_node_or_null("ArenaStageZones") as Control
	if zones == null:
		zones = Control.new()
		zones.name = "ArenaStageZones"
		zones.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(zones)
		root.move_child(zones, player_area.get_index())
	_root_place(zones, Vector2.ZERO, DESIGN, factor, origin)
	var sports_field := is_sports_field_arena(root)

	var hud_band := zones.get_node_or_null("ArenaHUDBand") as Panel
	if hud_band == null:
		hud_band = Panel.new()
		hud_band.name = "ArenaHUDBand"
		hud_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zones.add_child(hud_band)
	var hud_box := StyleBoxFlat.new()
	hud_box.bg_color = Color(0.08, 0.09, 0.16, 0.30) if overclock else Color(0.97, 0.94, 0.88, 0.24)
	hud_box.border_color = Color(0.84, 0.44, 0.46, 0.42) if overclock else Color(0.75, 0.67, 0.54, 0.42)
	hud_box.set_border_width_all(0)
	hud_box.border_width_bottom = 1
	hud_band.add_theme_stylebox_override("panel", hud_box)
	DaylightUI.place(hud_band, full_left - 8.0, 78.0, full_width + 16.0, 128.0)
	hud_band.visible = not sports_field

	var platform_rect := Rect2(full_left - 8.0, 566.0, full_width + 16.0, 92.0)
	var custom_tex := CombatSkin.platform_texture(overclock)
	var platform_art := zones.get_node_or_null("CombatStagePlatformArt") as TextureRect
	var platform := zones.get_node_or_null("CombatStagePlatform") as Panel
	if sports_field:
		if is_instance_valid(platform_art):
			platform_art.visible = false
		if is_instance_valid(platform):
			platform.visible = false
	elif custom_tex != null:
		if platform_art == null:
			platform_art = TextureRect.new()
			platform_art.name = "CombatStagePlatformArt"
			platform_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			platform_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			platform_art.stretch_mode = TextureRect.STRETCH_SCALE
			zones.add_child(platform_art)
		platform_art.texture = custom_tex
		platform_art.visible = true
		DaylightUI.place(platform_art, platform_rect.position.x, platform_rect.position.y, platform_rect.size.x, platform_rect.size.y)
		if platform != null:
			platform.visible = false
	else:
		if platform_art != null:
			platform_art.visible = false
		if platform == null:
			platform = Panel.new()
			platform.name = "CombatStagePlatform"
			platform.mouse_filter = Control.MOUSE_FILTER_IGNORE
			zones.add_child(platform)
		platform.visible = true
		var plat_box := StyleBoxFlat.new()
		plat_box.bg_color = Color(0.11, 0.07, 0.14, 0.56) if overclock else Color(0.95, 0.91, 0.84, 0.36)
		plat_box.border_color = Color(0.88, 0.36, 0.38, 0.78) if overclock else Color(0.76, 0.64, 0.45, 0.72)
		plat_box.set_border_width_all(0)
		plat_box.border_width_top = 2
		platform.add_theme_stylebox_override("panel", plat_box)
		DaylightUI.place(platform, platform_rect.position.x, platform_rect.position.y, platform_rect.size.x, platform_rect.size.y)

static func _compact_plaque_style(selected: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#FBF4E6")
	box.border_color = Color("#C95B48") if selected else Color("#7A634C")
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	return box

static func _ensure_compact_identity_box(parent: Control, node_name: String, selected: bool = false) -> Panel:
	var panel := parent.get_node_or_null(node_name) as Panel
	if panel == null:
		panel = Panel.new()
		panel.name = node_name
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(panel)
		parent.move_child(panel, 0)
	panel.add_theme_stylebox_override("panel", _compact_plaque_style(selected))
	return panel

static func is_sports_field_arena(root: Control) -> bool:
	if not is_instance_valid(root) or is_overclock_combat(root):
		return false
	if GameState.current_node_id == "n_gate":
		return true
	var bg := root.get_node_or_null("Background") as TextureRect
	return is_instance_valid(bg) and bg.texture != null and bg.texture.resource_path.contains("battle_sports_field")

static func is_mirrored_2v2(root: Control) -> bool:
	if not is_instance_valid(root):
		return false
	var enemies: Variant = root.get("enemy_nodes")
	if not (enemies is Array) or (enemies as Array).size() != 2:
		return false
	var comp_id := str(root.get("_companion_id")) if root.get("_companion_id") != null else ""
	if comp_id == "" or comp_id == "ye_zhou":
		return false
	return CombatSkin.character_combat_path(comp_id) != ""

static func update_badges(root: Control) -> void:
	if not is_instance_valid(root):
		return
	var player_area := root.get_node_or_null("PlayerArea") as Control
	if player_area == null:
		return
	var pill := player_area.get_node_or_null("CompanionResonancePill") as CanvasItem
	var comp_badge := player_area.get_node_or_null("CompanionAssistBadge") as Label
	var res_badge := player_area.get_node_or_null("ZodiacResonanceBadge") as Label
	if pill == null or comp_badge == null or res_badge == null:
		return
	var comp_id := str(root.get("_companion_id")) if root.get("_companion_id") != null else ""
	var comp_spec := PlayerJourney.companion_assist_spec(comp_id) if comp_id != "" else {}
	var played_total := int(root.get("_cards_played_total")) if root.get("_cards_played_total") != null else 0
	var zodiac_spec: Dictionary = root.get("_active_zodiac_spec") if root.get("_active_zodiac_spec") is Dictionary else {}
	var has_comp := not comp_spec.is_empty()
	var has_zodiac := not zodiac_spec.is_empty()
	pill.visible = false
	comp_badge.visible = false
	res_badge.visible = has_zodiac
	var compact_comp := player_area.get_node_or_null("CompanionIdentityBox") as Control
	if is_instance_valid(compact_comp):
		var c_name := compact_comp.get_node_or_null("CompanionNameLabel") as Label
		var c_skill := compact_comp.get_node_or_null("CompanionSkillLabel") as Label
		if has_comp:
			if is_instance_valid(c_name):
				c_name.text = str(comp_spec.get("name", ""))
			if is_instance_valid(c_skill):
				c_skill.text = "%s %d/3" % [str(comp_spec.get("skill", "")), played_total % 3]
	if has_zodiac:
		res_badge.text = "✦ %s" % str(zodiac_spec.get("title", ""))
	var halo := player_area.get_node_or_null("ZodiacHaloEmblem") as TextureRect
	if is_instance_valid(halo):
		halo.visible = false
	_update_resonance_seal(root)
	update_player_status_chips(root)

static func _layout_resonance_seal(root: Control, hand: Control) -> void:
	if not is_instance_valid(root) or not is_instance_valid(hand):
		return
	var overclock := is_overclock_combat(root)
	var seal := hand.get_node_or_null("TacticalResonanceSeal") as Control
	var tray := hand.get_node_or_null("NotebookTray") as CanvasItem
	if seal == null:
		seal = Control.new()
		seal.name = "TacticalResonanceSeal"
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hand.add_child(seal)
	if is_instance_valid(tray):
		hand.move_child(seal, tray.get_index() + 1)
	DaylightUI.place(seal, 62.0, 96.0, 134.0, 200.0)

	var medallion := _ensure_panel(seal, "SealMedallion", Color(0.10, 0.15, 0.24, 0.90), Color("#C84C5B") if overclock else Color("#D6B26B"), 54)
	var med_box := medallion.get_theme_stylebox("panel") as StyleBoxFlat
	if med_box != null:
		med_box.set_border_width_all(2)
	DaylightUI.place(medallion, 13.0, 20.0, 108.0, 108.0)

	var expected_vfx := "overclock_redmoon" if overclock else "companion_assist"
	if str(seal.get_meta("vfx_key", "")) != expected_vfx:
		for child in seal.get_children():
			if str(child.name).begins_with("LoopVFX_"):
				seal.remove_child(child)
				child.queue_free()
		var vfx_rect := CombatVFX.play_loop(seal, expected_vfx, Rect2(5.0, 12.0, 124.0, 124.0), 0.56 if overclock else 0.72, 1)
		if is_instance_valid(vfx_rect):
			seal.move_child(vfx_rect, medallion.get_index() + 1)
		seal.set_meta("vfx_key", expected_vfx)

	var reduced := bool(SaveManager.settings.get("reduced_motion", false))
	var outer := seal.get_node_or_null("OuterHalo") as TextureRect
	if outer == null and ResourceLoader.exists(ZODIAC_HALO_PATH):
		outer = TextureRect.new()
		outer.name = "OuterHalo"
		outer.texture = load(ZODIAC_HALO_PATH) as Texture2D
		outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		outer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		outer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		outer.z_index = 2
		seal.add_child(outer)
	if is_instance_valid(outer):
		DaylightUI.place(outer, 2.0, 9.0, 130.0, 130.0)
		outer.pivot_offset = Vector2(65.0, 65.0)
		outer.modulate = Color(0.95, 0.45, 0.52, 0.95) if overclock else Color(0.98, 0.84, 0.48, 0.96)
		if reduced:
			var tw_old := outer.get_meta("spin_tween") as Tween if outer.has_meta("spin_tween") else null
			if tw_old != null and is_instance_valid(tw_old):
				tw_old.kill()
			outer.rotation = 0.0
			outer.remove_meta("spin_tween")
		elif not outer.has_meta("spin_tween"):
			var tw := outer.create_tween()
			tw.set_loops()
			tw.tween_property(outer, "rotation", TAU, 18.0).from(0.0)
			outer.set_meta("spin_tween", tw)

	var inner := seal.get_node_or_null("InnerRing") as TextureRect
	var inner_path := REDMOON_RETICLE_PATH if overclock and ResourceLoader.exists(REDMOON_RETICLE_PATH) else ZODIAC_HALO_PATH
	if inner == null and ResourceLoader.exists(inner_path):
		inner = TextureRect.new()
		inner.name = "InnerRing"
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		inner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		inner.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		inner.z_index = 2
		seal.add_child(inner)
	if is_instance_valid(inner) and ResourceLoader.exists(inner_path):
		inner.texture = load(inner_path) as Texture2D
		DaylightUI.place(inner, 20.0, 27.0, 94.0, 94.0)
		inner.pivot_offset = Vector2(47.0, 47.0)
		inner.modulate = Color(0.96, 0.48, 0.56, 0.92) if overclock else Color(0.48, 0.82, 0.94, 0.88)
		if reduced:
			var tw_old := inner.get_meta("spin_tween") as Tween if inner.has_meta("spin_tween") else null
			if tw_old != null and is_instance_valid(tw_old):
				tw_old.kill()
			inner.rotation = 0.0
			inner.scale = Vector2.ONE
			inner.remove_meta("spin_tween")
		elif not inner.has_meta("spin_tween"):
			var tw_spin := inner.create_tween()
			tw_spin.set_loops()
			tw_spin.tween_property(inner, "rotation", -TAU, 11.0).from(0.0)
			var tw_pulse := inner.create_tween()
			tw_pulse.set_loops()
			tw_pulse.tween_property(inner, "scale", Vector2(1.04, 1.04), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_pulse.tween_property(inner, "scale", Vector2(0.95, 0.95), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			inner.set_meta("spin_tween", tw_spin)

	var crest := seal.get_node_or_null("CenterCrest") as TextureRect
	if crest == null and ResourceLoader.exists(DUEL_CREST_PATH):
		crest = TextureRect.new()
		crest.name = "CenterCrest"
		crest.texture = load(DUEL_CREST_PATH) as Texture2D
		crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crest.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		crest.z_index = 3
		seal.add_child(crest)
	if is_instance_valid(crest):
		DaylightUI.place(crest, 35.0, 42.0, 64.0, 64.0)
		crest.pivot_offset = Vector2(32.0, 32.0)
		crest.modulate = Color(1.0, 0.88, 0.90, 1.0) if overclock else Color.WHITE
		if reduced:
			var tw_old := crest.get_meta("bob_tween") as Tween if crest.has_meta("bob_tween") else null
			if tw_old != null and is_instance_valid(tw_old):
				tw_old.kill()
			crest.position.y = 42.0
			crest.remove_meta("bob_tween")
		elif not crest.has_meta("bob_tween"):
			var tw_bob := crest.create_tween()
			tw_bob.set_loops()
			tw_bob.tween_property(crest, "position:y", 39.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw_bob.tween_property(crest, "position:y", 45.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			crest.set_meta("bob_tween", tw_bob)

	var caption := _text(seal, "SealCaption", "刻印共鸣", Rect2(0.0, 146.0, 134.0, 24.0), 14, Color("#A83B40") if overclock else Color("#303A52"))
	caption.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	caption.add_theme_constant_override("outline_size", 0)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.z_index = 4

	var pips := seal.get_node_or_null("SealPips") as HBoxContainer
	if pips == null:
		pips = HBoxContainer.new()
		pips.name = "SealPips"
		pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.alignment = BoxContainer.ALIGNMENT_CENTER
		pips.add_theme_constant_override("separation", 8)
		pips.z_index = 4
		seal.add_child(pips)
		for idx in 3:
			var pip := Panel.new()
			pip.name = "Pip_%d" % idx
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pip.custom_minimum_size = Vector2(18.0, 9.0)
			pips.add_child(pip)
	DaylightUI.place(pips, 12.0, 173.0, 110.0, 14.0)
	_update_resonance_seal(root)

static func _update_resonance_seal(root: Control) -> void:
	if not is_instance_valid(root):
		return
	var hand := root.get_node_or_null("HandArea") as Control
	if hand == null:
		return
	var seal := hand.get_node_or_null("TacticalResonanceSeal") as Control
	if seal == null:
		return
	var overclock := is_overclock_combat(root)
	var comp_id := str(root.get("_companion_id")) if root.get("_companion_id") != null else ""
	var comp_spec := PlayerJourney.companion_assist_spec(comp_id) if comp_id != "" else {}
	var played_total := int(root.get("_cards_played_total")) if root.get("_cards_played_total") != null else 0
	var zodiac_spec: Dictionary = root.get("_active_zodiac_spec") if root.get("_active_zodiac_spec") is Dictionary else {}
	var caption := seal.get_node_or_null("SealCaption") as Label
	if is_instance_valid(caption):
		if not zodiac_spec.is_empty():
			caption.text = "✦ %s" % str(zodiac_spec.get("title", "星印共鸣")).split("·")[0].strip_edges()
		elif overclock:
			caption.text = "红月超限"
		else:
			caption.text = "刻印共鸣"
		caption.add_theme_color_override("font_color", Color("#A83B40") if overclock else Color("#303A52"))
	var pips := seal.get_node_or_null("SealPips") as HBoxContainer
	if is_instance_valid(pips):
		pips.visible = not comp_spec.is_empty()
		if pips.visible:
			var charge := played_total % 3
			for idx in pips.get_child_count():
				var pip := pips.get_child(idx) as Panel
				if pip == null:
					continue
				var lit := idx < charge
				var box := StyleBoxFlat.new()
				box.bg_color = (Color("#D69E3B") if not overclock else Color("#C84C5B")) if lit else Color("#EFE6D5")
				box.border_color = (Color("#9E6A1C") if not overclock else Color("#8F2B38")) if lit else Color("#BFB19B")
				box.set_border_width_all(1)
				box.set_corner_radius_all(4)
				pip.add_theme_stylebox_override("panel", box)

static func pulse_resonance_seal(root: Control) -> void:
	if not is_instance_valid(root):
		return
	var crest := root.get_node_or_null("HandArea/TacticalResonanceSeal/CenterCrest") as Control
	var outer := root.get_node_or_null("HandArea/TacticalResonanceSeal/OuterHalo") as CanvasItem
	if bool(SaveManager.settings.get("reduced_motion", false)):
		return
	if is_instance_valid(crest):
		var tw := crest.create_tween()
		tw.tween_property(crest, "scale", Vector2(1.24, 1.24), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(crest, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if is_instance_valid(outer):
		var base_mod := outer.modulate
		var tw2 := outer.create_tween()
		tw2.tween_property(outer, "modulate", Color(1.25, 1.15, 0.95, 1.0), 0.10)
		tw2.tween_property(outer, "modulate", base_mod, 0.24)

static func update_player_status_chips(root: Control) -> void:
	var player_area := root.get_node_or_null("PlayerArea") as Control
	if player_area == null:
		return
	var row := player_area.get_node_or_null("PlayerStatusIcons") as HBoxContainer
	if row == null:
		return
	var p_shield := int(root.get("player_shield")) if root.get("player_shield") != null else 0
	var reflect_turns := int(root.get("player_reflect_turns")) if root.get("player_reflect_turns") != null else 0
	var reflect_dmg := int(root.get("player_reflect_damage")) if root.get("player_reflect_damage") != null else 0
	var reflect_hits := int(root.get("player_reflect_hits")) if root.get("player_reflect_hits") != null else 0
	var incoming := 0
	var enemies: Variant = root.get("enemy_nodes")
	if enemies is Array:
		for enemy in enemies:
			if is_instance_valid(enemy) and not bool(enemy.get("is_dead")) and enemy.has_method("predicted_damage"):
				incoming += int(enemy.call("predicted_damage"))
	var net_incoming := maxi(0, incoming - p_shield)
	var comp_id := str(root.get("_companion_id")) if root.get("_companion_id") != null else ""
	var comp_spec := PlayerJourney.companion_assist_spec(comp_id) if comp_id != "" else {}
	var played_total := int(root.get("_cards_played_total")) if root.get("_cards_played_total") != null else 0

	sync_status_chip(row, "ShieldChip", ICON_SHIELD, str(p_shield), "shield" if p_shield > 0 else "muted")
	var inc_chip := sync_status_chip(
		row,
		"IncomingChip",
		ICON_ATK if net_incoming > 0 else ICON_SHIELD,
		("-%d" % net_incoming) if net_incoming > 0 else "挡0",
		"danger" if net_incoming > 0 else "safe"
	)
	inc_chip.visible = incoming > 0
	var ref_chip := sync_status_chip(row, "ReflectChip", ICON_REFLECT, "%d×%d" % [reflect_dmg, reflect_hits], "reflect")
	ref_chip.visible = reflect_turns > 0
	var assist_chip := sync_status_chip(
		row,
		"AssistChip",
		ICON_ASSIST,
		"%d/3" % (played_total % 3),
		"assist_ready" if (played_total % 3) == 2 else "assist"
	)
	assist_chip.visible = not comp_spec.is_empty()

static func is_overclock_combat(root: Control) -> bool:
	if str(GameState.pending_combat_data.get("mode", "")) == "qualifier":
		return false
	if bool(GameState.pending_combat_data.get("overclock", false)):
		return true
	if GameState.current_node_id in ["n_guard", "n_robot", "n5_boss"] or DayCycle.period() == "night":
		return true
	var enemies: Variant = root.get("enemy_nodes")
	if enemies is Array:
		for unit in enemies:
			var edata = unit.get("enemy_data") if is_instance_valid(unit) else null
			if edata != null and str(edata.id) in ["security_guard", "campus_robot", "ch1_hunter_mech", "principal", "alliance_operative", "church_guardian"]:
				return true
	return false

static func _layout_redmoon_hud(root: Control) -> void:
	if not is_instance_valid(root):
		return
	var hud := root.get_node_or_null("RedMoonHudPulse") as TextureRect
	if hud == null and ResourceLoader.exists(REDMOON_HUD_PATH):
		hud = TextureRect.new()
		hud.name = "RedMoonHudPulse"
		hud.texture = load(REDMOON_HUD_PATH) as Texture2D
		hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hud.stretch_mode = TextureRect.STRETCH_SCALE
		hud.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		hud.z_index = 12
		root.add_child(hud)
	if not is_instance_valid(hud):
		return
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var active := is_overclock_combat(root)
	hud.visible = active
	var old_tw: Tween = hud.get_meta("pulse_tween") as Tween if hud.has_meta("pulse_tween") else null
	if old_tw != null and is_instance_valid(old_tw):
		old_tw.kill()
		hud.remove_meta("pulse_tween")
	if not active:
		return
	if bool(SaveManager.settings.get("reduced_motion", false)):
		hud.modulate = Color(1.0, 1.0, 1.0, 0.62)
		return
	hud.modulate = Color(1.0, 1.0, 1.0, 0.45)
	var tw := hud.create_tween()
	tw.set_loops()
	tw.tween_property(hud, "modulate:a", 0.88, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(hud, "modulate:a", 0.42, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hud.set_meta("pulse_tween", tw)

static func play_companion_cutin(root: Control, companion_id: String, spec: Dictionary) -> void:
	if not is_instance_valid(root) or companion_id == "" or spec.is_empty():
		return
	var prev := root.get_node_or_null("CompanionCutinOverlay")
	if prev != null:
		prev.queue_free()
	var extent := root.get_viewport_rect().size
	var safe_extent := extent if extent.x > 0.0 and extent.y > 0.0 else DESIGN
	var factor := minf(safe_extent.x / DESIGN.x, safe_extent.y / DESIGN.y)
	var origin := (safe_extent - DESIGN * factor) / 2.0

	var overlay := Control.new()
	overlay.name = "CompanionCutinOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 35
	root.add_child(overlay)
	_root_place(overlay, Vector2.ZERO, DESIGN, factor, origin)

	if ResourceLoader.exists(CUTIN_BANNER_PATH):
		var banner := TextureRect.new()
		banner.name = "CutinBanner"
		banner.texture = load(CUTIN_BANNER_PATH) as Texture2D
		banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		banner.stretch_mode = TextureRect.STRETCH_SCALE
		banner.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		overlay.add_child(banner)
		DaylightUI.place(banner, 0.0, 290.0, 1920.0, 340.0)

	var cutin_path := CombatSkin.character_cutin_path(companion_id)
	if cutin_path != "" and ResourceLoader.exists(cutin_path):
		var art := TextureRect.new()
		art.name = "CutinPortrait"
		art.texture = load(cutin_path) as Texture2D
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		overlay.add_child(art)
		DaylightUI.place(art, 240.0, 175.0, 460.0, 460.0)

	var title := _text(overlay, "CutinTitle", "%s · %s" % [str(spec.get("name", "")), str(spec.get("skill", ""))], Rect2(740.0, 374.0, 960.0, 56.0), 42, Color("#FFF8EC"))
	title.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.06, 0.88))
	var summary_lbl := _text(overlay, "CutinSummary", str(spec.get("summary", "")), Rect2(740.0, 434.0, 960.0, 38.0), 24, Color("#FAF2DE"))
	summary_lbl.add_theme_constant_override("outline_size", 3)
	summary_lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.06, 0.88))

	var reduced := bool(SaveManager.settings.get("reduced_motion", false))
	var tw := overlay.create_tween()
	if reduced:
		overlay.modulate.a = 0.0
		tw.tween_property(overlay, "modulate:a", 1.0, 0.08)
		tw.tween_interval(0.32)
		tw.tween_property(overlay, "modulate:a", 0.0, 0.16)
		tw.tween_callback(overlay.queue_free)
	else:
		overlay.position.x -= 120.0 * factor
		overlay.modulate.a = 0.0
		tw.set_parallel(true)
		tw.tween_property(overlay, "position:x", origin.x, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(overlay, "modulate:a", 1.0, 0.12)
		tw.chain().tween_interval(0.36)
		tw.chain().tween_property(overlay, "modulate:a", 0.0, 0.18)
		tw.chain().tween_callback(overlay.queue_free)
