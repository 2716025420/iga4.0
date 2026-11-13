class_name CombatPresentation
extends RefCounted

## A single 1920x1080 composition, scaled uniformly with its painted source.
## The field notebook is an intact transparent layer; controls sit on its blank papers.
const DESIGN := Vector2(1920, 1080)
const CARD_SIZE := Vector2(232, 320)
const CARD_GAP := 12.0
const FRAME_PATH := "res://assets/ui/combat_notebook/composition.png"

static func _root_place(node: Control, point: Vector2, extent: Vector2, scale_factor: float, origin: Vector2) -> void:
	DaylightUI.place(node, point.x, point.y, extent.x, extent.y)
	node.scale = Vector2.ONE * scale_factor
	node.position = origin + point * scale_factor

static func _text(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int, color: Color = NotebookUI.INK) -> Label:
	var node := parent.get_node_or_null(node_name) as Label
	if node == null: node = NotebookUI.label(parent, node_name, copy, rect.position, rect.size, font_size, color)
	DaylightUI.place(node, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node

static func _header_button(button: Button, copy: String) -> void:
	button.text = copy
	button.custom_minimum_size = Vector2.ZERO
	button.add_theme_font_size_override("font_size", 28)
	for state in ["normal", "disabled", "focus"]: button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.12 if state == "hover" else 0.20)
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]: button.add_theme_color_override(state, Color("#F5E8CD"))
	button.add_theme_color_override("font_disabled_color", Color("#A4A0B1"))

static func _plaque(parent: Control, node_name: String, point: Vector2, extent: Vector2) -> TextureRect:
	var paper := parent.get_node_or_null(node_name) as TextureRect
	if paper == null:
		paper = TextureRect.new()
		paper.name = node_name
		paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		paper.texture = CombatSkin.actor_texture("res://assets/ui/combat_notebook/status_note.png")
		parent.add_child(paper)
		parent.move_child(paper, 0)
	DaylightUI.place(paper, point.x, point.y, extent.x, extent.y)
	return paper

static func layout(root: Control, extent: Vector2) -> void:
	var factor := minf(extent.x / DESIGN.x, extent.y / DESIGN.y)
	var origin := (extent - DESIGN * factor) / 2.0
	var frame := root.get_node_or_null("PaintedCombatComposition") as TextureRect
	if frame == null:
		frame = TextureRect.new()
		frame.name = "PaintedCombatComposition"
		frame.texture = load(FRAME_PATH)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		root.add_child(frame)
		root.move_child(frame, 1)
	_root_place(frame, Vector2.ZERO, DESIGN, factor, origin)
	var platform := root.get_node_or_null("/root/Platform") as PlatformService
	if platform != null:
		platform.fill_backdrop(root, extent, frame, Color(0.92, 0.89, 0.83, 0.0), frame.texture)
	var header := root.get_node("TopInfo") as Control
	_root_place(header, Vector2.ZERO, Vector2(1920, 90), factor, origin)
	var turn := header.get_node("TurnBanner") as Label
	DaylightUI.place(turn, 790, 8, 350, 70)
	turn.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	turn.add_theme_font_size_override("font_size", 43)
	turn.add_theme_color_override("font_color", NotebookUI.INK)
	turn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var round_label := header.get_node("RoundLabel") as Label
	DaylightUI.place(round_label, 1400, 12, 200, 58)
	round_label.add_theme_font_size_override("font_size", 28)
	round_label.add_theme_color_override("font_color", Color("#F5E8CD"))
	_text(header, "EncounterLocation", "校园练习" if bool(root.get("_exploration_mode")) else "校园侧门", Rect2(285, 12, 210, 56), 29)
	var pause := header.get_node_or_null("EscapeButton") as Button
	if pause:
		_header_button(pause, "逃跑 · 判负")
		DaylightUI.place(pause, 28, 10, 180, 58)
	var history := header.get_node_or_null("CombatHistoryButton") as Button
	if history:
		_header_button(history, "回合记录")
		DaylightUI.place(history, 1650, 10, 235, 58)

	var enemy_area := root.get_node("EnemyArea") as Control
	_root_place(enemy_area, Vector2(1050, 118), Vector2(800, 544), factor, origin)
	var enemies := enemy_area.get_node("EnemiesContainer") as HBoxContainer
	var count := maxi(1, enemies.get_child_count())
	var unit_width := (800.0 - 26.0 * (count - 1)) / count
	enemies.add_theme_constant_override("separation", 26)
	for unit in enemies.get_children():
		if unit is Control and unit.has_method("layout_stage"): unit.call("layout_stage", Vector2(unit_width, 544))
	var player_area := root.get_node("PlayerArea") as Control
	_root_place(player_area, Vector2(80, 118), Vector2(720, 544), factor, origin)
	var player := player_area.get_node("ProtagonistSprite") as TextureRect
	player.texture = CombatSkin.actor_texture("res://assets/sprites/characters/phase_three/combat/ye_zhou_idle.png")
	player.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	player.flip_h = false
	DaylightUI.place(player, 285, 0 if count == 1 else 132, 310, 530 if count == 1 else 398)
	_plaque(player_area, "PlayerIdentity", Vector2(12, 18), Vector2(308, 142))
	_text(player_area, "PlayerName", "叶舟", Rect2(94, 45, 190, 40), 30)
	var hp := player_area.get_node("PlayerHPBar") as ProgressBar
	DaylightUI.place(hp, 92, 94, 204, 18)
	hp.add_theme_stylebox_override("background", CombatSkin.flat(Color("#DDD9CA"), Vector4.ZERO))
	hp.add_theme_stylebox_override("fill", CombatSkin.flat(Color("#91AD97"), Vector4.ZERO))
	var hp_label := hp.get_node("HPLabel") as Label
	DaylightUI.place(hp_label, 0, 21, 204, 30)
	hp_label.add_theme_font_size_override("font_size", 23)
	var shield := player_area.get_node("PlayerShieldLabel") as Label
	DaylightUI.place(shield, 64, 166, 260, 32)
	shield.add_theme_font_size_override("font_size", 23)
	var status := player_area.get_node("PlayerStatusLabel") as Label
	DaylightUI.place(status, 22, 202, 330, 56)
	status.add_theme_font_size_override("font_size", 22)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var hand := root.get_node("HandArea") as Control
	_root_place(hand, Vector2(0, 650), Vector2(1920, 430), factor, origin)
	_text(hand, "HandbookHeading", "行动手册", Rect2(175, 4, 220, 56), 36)
	_text(hand, "HandbookHint", "选择行动 · 抓住时机", Rect2(420, 10, 450, 48), 25)
	var cards := hand.get_node("CardsContainer") as HBoxContainer
	DaylightUI.place(cards, 202, 77, 1212, 320)
	cards.custom_minimum_size = Vector2.ZERO
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", int(CARD_GAP))
	for card in cards.get_children():
		if card.has_method("layout_notebook_card"): card.call("layout_notebook_card", CARD_SIZE)
	_text(hand, "TargetHeading", "当前目标", Rect2(1465, 69, 330, 42), 26, NotebookUI.PLUM)
	var target := _text(hand, "TargetCopy", "", Rect2(1465, 114, 330, 46), 30)
	target.autowrap_mode = TextServer.AUTOWRAP_OFF
	var target_description := _text(hand, "TargetDescription", "", Rect2(1468, 171, 240, 94), 24, NotebookUI.MUTED)
	target_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var portrait := hand.get_node_or_null("TargetPortrait") as TextureRect
	if portrait == null:
		var photo_paper := TextureRect.new()
		photo_paper.name = "TargetPhotoPaper"
		photo_paper.texture = CombatSkin.actor_texture("res://assets/ui/combat_notebook/action_card.png")
		photo_paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo_paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		photo_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hand.add_child(photo_paper)
		DaylightUI.place(photo_paper, 1724, 140, 116, 150)
		var photo_back := ColorRect.new()
		photo_back.name = "TargetPhotoBacking"
		photo_back.color = Color("#C7C0C7")
		photo_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hand.add_child(photo_back)
		DaylightUI.place(photo_back, 1736, 154, 92, 117)
		portrait = TextureRect.new()
		portrait.name = "TargetPortrait"
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var material := ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = "shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV); float g=dot(c.rgb,vec3(0.299,0.587,0.114)); COLOR=vec4(vec3(g)*vec3(0.91,0.87,0.94),c.a);}"
		material.shader = shader
		portrait.material = material
		hand.add_child(portrait)
	DaylightUI.place(portrait, 1736, 154, 92, 117)
	var end_button := root.get("end_turn_btn") as Button
	if is_instance_valid(end_button):
		DaylightUI.place(end_button, 1465, 276, 368, 88)
		end_button.add_theme_font_size_override("font_size", 38)
		for state in ["normal", "hover", "pressed"]:
			end_button.add_theme_stylebox_override(state, SceneSkin.style("button_primary", Vector4(18, 10, 18, 10), Color(0.73, 0.63, 0.84) if state == "normal" else Color(0.83, 0.74, 0.93)))
		end_button.add_theme_color_override("font_color", Color("#FFF9F0"))
	_text(hand, "CooldownCopy", "下回合推进冷却", Rect2(1505, 368, 320, 38), 23, NotebookUI.MUTED)
	root.call("_refresh_tactical_note")
