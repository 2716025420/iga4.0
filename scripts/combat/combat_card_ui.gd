class_name CombatCardUI
extends PanelContainer

signal card_clicked(card_data: CardData)
signal card_armed(card_ui: CombatCardUI)

const CARD_PAPER_PATH := "res://assets/combat/card_frame_paper.png"
const FALLBACK_CARD_PAPER := "res://assets/ui/combat_notebook/action_card.png"
const COOLDOWN_ICON_PATH := "res://assets/ui_core/icons/combat/cooldown.svg"

var card_data: CardData
var current_cooldown: int = 0
var uses_remaining: int = -1
var is_available: bool = true

@onready var name_label: Label = $VBox/Header/NameLabel
@onready var type_label: Label = $VBox/Header/TypeBadge
@onready var desc_label: RichTextLabel = $VBox/DescLabel
@onready var cd_badge: PanelContainer = $CDBadge
@onready var cd_label: Label = $CDBadge/CDLabel
@onready var level_label: Label = $VBox/Footer/LevelLabel
@onready var cd_hint_label: Label = $VBox/Footer/CDHintLabel

var _base_style: StyleBox
var _highlight_style: StyleBox
var _disabled_style: StyleBox

# Animation always returns to one absolute baseline.
var _is_hovered: bool = false
var _touch_armed: bool = false
var _touch_pressing: bool = false
var _touch_start: Vector2 = Vector2.ZERO
var _touch_moved: bool = false
var _base_y: float = 0.0
var _is_base_y_set: bool = false
var _hover_tween: Tween = null
var _paper_art: TextureRect
var _cd_veil: Panel
var _cd_pill: PanelContainer
var _cd_pill_label: Label
var _touch_hint_pill: PanelContainer

func setup_card(data: CardData, cd_remaining: int = 0) -> void:
	card_data = data
	uses_remaining = data.get_battle_use_limit()
	current_cooldown = cd_remaining
	custom_minimum_size = CombatPresentation.CARD_SIZE
	_prepare_notebook_composition()
	_setup_styles()
	_update_display()
	DaylightUI.polish(self)
	_refresh_card_illustration()
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	type_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	_reset_position_to_base()

func _setup_styles() -> void:
	_base_style = StyleBoxEmpty.new()
	_highlight_style = StyleBoxEmpty.new()
	_disabled_style = StyleBoxEmpty.new()
	add_theme_stylebox_override("panel", _base_style)

func _prepare_notebook_composition() -> void:
	var body := get_node("VBox") as Control
	if body is VBoxContainer:
		var previous := body
		previous.name = "RetiredCardStack"
		body = Control.new()
		body.name = "VBox"
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(body)
		for child in previous.get_children(): child.reparent(body, false)
		remove_child(previous)
		previous.queue_free()
	_paper_art = TextureRect.new()
	_paper_art.name = "CardPaperArtwork"
	var paper_path := CARD_PAPER_PATH if ResourceLoader.exists(CARD_PAPER_PATH) else FALLBACK_CARD_PAPER
	_paper_art.texture = CombatSkin.actor_texture(paper_path)
	_paper_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paper_art.stretch_mode = TextureRect.STRETCH_SCALE
	_paper_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_paper_art)
	body.move_child(_paper_art, 0)
	_create_overlays(body)

func _create_overlays(body: Control) -> void:
	_cd_veil = Panel.new()
	_cd_veil.name = "CDVeil"
	_cd_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cd_veil.visible = false
	var veil_box := StyleBoxFlat.new()
	veil_box.bg_color = Color(0.95, 0.92, 0.87, 0.56)
	veil_box.border_color = Color(0.78, 0.72, 0.65, 0.35)
	veil_box.set_border_width_all(1)
	veil_box.set_corner_radius_all(6)
	_cd_veil.add_theme_stylebox_override("panel", veil_box)
	body.add_child(_cd_veil)
	var header_node := body.get_node_or_null("Header")
	if header_node != null:
		body.move_child(_cd_veil, header_node.get_index())

	_cd_pill = PanelContainer.new()
	_cd_pill.name = "CDPill"
	_cd_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cd_pill.visible = false
	var pill_box := CombatSkin.flat(Color("#FFF8EC"), Vector4(10, 5, 10, 5))
	pill_box.border_color = Color("#8D7F72")
	pill_box.set_corner_radius_all(10)
	_cd_pill.add_theme_stylebox_override("panel", pill_box)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	_cd_pill.add_child(row)
	if ResourceLoader.exists(COOLDOWN_ICON_PATH):
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = load(COOLDOWN_ICON_PATH) as Texture2D
		row.add_child(icon)
	_cd_pill_label = Label.new()
	_cd_pill_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cd_pill_label.add_theme_font_size_override("font_size", 19)
	_cd_pill_label.add_theme_color_override("font_color", NotebookUI.INK)
	row.add_child(_cd_pill_label)
	body.add_child(_cd_pill)

	_touch_hint_pill = PanelContainer.new()
	_touch_hint_pill.name = "TouchPlayHint"
	_touch_hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_hint_pill.visible = false
	var hint_box := CombatSkin.flat(Color("#BD4E3F"), Vector4(8, 2, 8, 2))
	hint_box.border_color = Color("#99392C")
	hint_box.set_corner_radius_all(9)
	_touch_hint_pill.add_theme_stylebox_override("panel", hint_box)
	var hint_lbl := Label.new()
	hint_lbl.text = "再点一次打出"
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	hint_lbl.add_theme_font_size_override("font_size", 19)
	hint_lbl.add_theme_color_override("font_color", Color("#FFFDF8"))
	_touch_hint_pill.add_child(hint_lbl)
	body.add_child(_touch_hint_pill)

func layout_notebook_card(extent: Vector2 = CombatPresentation.CARD_SIZE) -> void:
	custom_minimum_size = extent
	size = extent
	pivot_offset = extent * 0.5
	var body := get_node("VBox") as Control
	DaylightUI.place(_paper_art, 0, 0, extent.x, extent.y)
	var header := body.get_node("Header") as HBoxContainer
	DaylightUI.place(header, 20, 16, extent.x - 40, 34)
	header.add_theme_constant_override("separation", 5)
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	var art_h := clampf(extent.y - 216.0, 82.0, 102.0)
	var desc_y := 54.0 + art_h + 4.0
	var footer_y := extent.y - 44.0
	DaylightUI.place(body.get_node("CardIllustration"), 20, 54, extent.x - 40, art_h)
	DaylightUI.place(desc_label, 18, desc_y, extent.x - 36, footer_y - desc_y - 6.0)
	desc_label.add_theme_font_size_override("normal_font_size", 23)
	desc_label.add_theme_font_size_override("bold_font_size", 23)
	desc_label.add_theme_constant_override("line_separation", 1)
	var footer := body.get_node("Footer") as HBoxContainer
	DaylightUI.place(footer, 20, footer_y, extent.x - 40, 26)
	level_label.add_theme_font_size_override("font_size", 20)
	cd_hint_label.add_theme_font_size_override("font_size", 20)
	var divider := body.get_node_or_null("FooterRule") as ColorRect
	if divider == null:
		divider = ColorRect.new()
		divider.name = "FooterRule"
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		divider.color = Color(0.58, 0.49, 0.39, 0.25)
		body.add_child(divider)
	DaylightUI.place(divider, 20, footer_y - 4.0, extent.x - 40, 1)
	if is_instance_valid(_cd_veil):
		DaylightUI.place(_cd_veil, 12, 12, extent.x - 24, extent.y - 24)
		var header_node := body.get_node_or_null("Header")
		if header_node != null and _cd_veil.get_index() > header_node.get_index():
			body.move_child(_cd_veil, header_node.get_index())
	if is_instance_valid(_cd_pill):
		DaylightUI.place(_cd_pill, 24, 86, extent.x - 48, 36)
	if is_instance_valid(_touch_hint_pill):
		DaylightUI.place(_touch_hint_pill, 16, -28, extent.x - 32, 28)
		var hint_lbl := _touch_hint_pill.get_child(0) as Label
		if is_instance_valid(hint_lbl):
			hint_lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
			hint_lbl.add_theme_font_size_override("font_size", 19)
			hint_lbl.add_theme_color_override("font_color", Color("#FFFDF8"))
			hint_lbl.add_theme_constant_override("outline_size", 0)
	_refresh_category_tab()
	if not _is_hovered and not _touch_armed:
		_base_y = position.y
		_is_base_y_set = true

func _update_display() -> void:
	if not card_data:
		return
	
	name_label.text = card_data.name
	level_label.text = "余%d次" % uses_remaining if uses_remaining >= 0 else "等级%d" % card_data.level
	cd_hint_label.text = "冷却 %d 回合" % card_data.get_current_cooldown()
	
	# 技能类型徽章
	match card_data.card_type:
		CardData.CardType.ATTACK:
			type_label.text = " 攻击 "
			type_label.modulate = Color("#B65B63")
		CardData.CardType.DEFENSE:
			type_label.text = " 防御 "
			type_label.modulate = Color("#557C9A")
		CardData.CardType.RECOVERY:
			type_label.text = " 恢复 "
			type_label.modulate = Color("#547C69")
		CardData.CardType.DEBUFF:
			type_label.text = " 干扰 "
			type_label.modulate = Color("#A47741")
		CardData.CardType.SPECIAL:
			type_label.text = " 战术 "
			type_label.modulate = Color("#796B9E")
	
	desc_label.text = card_data.get_combat_summary()
	desc_label.scroll_active = false
	
	# Tracing-paper veil & stamped pill replace muddy tinting so card details stay readable.
	cd_badge.visible = false
	if uses_remaining == 0:
		is_available = false
		cd_hint_label.text = "本场已用完"
		cd_hint_label.add_theme_color_override("font_color", DaylightUI.MUTED)
		disarm_touch()
	elif current_cooldown > 0:
		is_available = false
		cd_label.text = "下回合可用" if current_cooldown == 1 else "还需%d回合" % current_cooldown
		cd_hint_label.text = cd_label.text
		cd_hint_label.add_theme_color_override("font_color", Color("#9B5E3A"))
		add_theme_stylebox_override("panel", _disabled_style)
		disarm_touch()
	else:
		is_available = true
		cd_hint_label.text = "冷却 %d 回合" % card_data.get_current_cooldown()
		cd_hint_label.add_theme_color_override("font_color", DaylightUI.MUTED)
		add_theme_stylebox_override("panel", _highlight_style if _is_hovered else _base_style)
	modulate = Color.WHITE
	if is_instance_valid(_paper_art): _paper_art.modulate = Color.WHITE
	if is_instance_valid(_cd_veil): _cd_veil.visible = not is_available
	if is_instance_valid(_cd_pill):
		_cd_pill.visible = not is_available
		if is_instance_valid(_cd_pill_label):
			_cd_pill_label.text = "本场已用完" if uses_remaining == 0 else ("下回合可用" if current_cooldown == 1 else "还需 %d 回合" % current_cooldown)

func _refresh_card_illustration() -> void:
	var box := $VBox as Control
	var art := box.get_node_or_null("CardIllustration") as TextureRect
	if art == null:
		art = TextureRect.new()
		art.name = "CardIllustration"
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(art)
		box.move_child(art, 1)
	var asset := SceneSkin.card_illustration_path(card_data.id)
	art.texture = SceneSkin.illustration_texture(asset)
	art.visible = art.texture != null
	desc_label.scroll_active = false
	layout_notebook_card()

func _refresh_category_tab() -> void:
	type_label.add_theme_font_size_override("font_size", 18)
	var category_colors := [Color("#A36A83"), Color("#69849C"), Color("#6F9C96"), Color("#B09363"), Color("#8974A4")]
	var tab_style := CombatSkin.flat(category_colors[int(card_data.card_type)], Vector4(7, 3, 7, 3))
	tab_style.set_corner_radius_all(3)
	tab_style.set_border_width_all(0)
	type_label.add_theme_stylebox_override("normal", tab_style)
	type_label.modulate = Color.WHITE
	type_label.add_theme_color_override("font_color", Color("#FFF9F0"))

func reduce_cooldown() -> void:
	if current_cooldown > 0:
		current_cooldown -= 1
		_update_display()

func put_on_cooldown() -> void:
	if uses_remaining > 0: uses_remaining -= 1
	current_cooldown = card_data.get_current_cooldown()
	_is_hovered = false
	disarm_touch()
	_update_display()

func disarm_touch() -> void:
	var was_armed := _touch_armed
	_touch_armed = false
	_touch_pressing = false
	_touch_moved = false
	if is_instance_valid(_touch_hint_pill):
		_touch_hint_pill.visible = false
	if was_armed:
		scale = Vector2.ONE
		z_index = 0
		_reset_position_to_base()

func _arm_touch() -> void:
	_touch_armed = true
	z_index = 8
	if is_instance_valid(_touch_hint_pill):
		_touch_hint_pill.visible = true
	_animate_hover(-8.0)
	if not bool(SaveManager.settings["reduced_motion"]):
		scale = Vector2(1.05, 1.05)
	card_armed.emit(self)

func _trigger_card_play() -> void:
	_is_hovered = false
	_touch_armed = false
	_touch_pressing = false
	_touch_moved = false
	scale = Vector2.ONE
	z_index = 0
	if is_instance_valid(_touch_hint_pill):
		_touch_hint_pill.visible = false
	_reset_position_to_base()
	card_clicked.emit(card_data)
	if not bool(SaveManager.settings["reduced_motion"]):
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.06)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.06)

func _reset_position_to_base() -> void:
	_animate_hover(0.0)

func _animate_hover(offset_y: float) -> void:
	if not _is_base_y_set:
		# 首帧或未浮动时记录基准高度
		_base_y = position.y
		_is_base_y_set = true
	
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	if bool(SaveManager.settings["reduced_motion"]):
		position.y = _base_y
		return
	
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "position:y", _base_y + offset_y, 0.1).set_trans(Tween.TRANS_SINE)

func _gui_input(event: InputEvent) -> void:
	if not is_available:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_pressing = true
			_touch_start = event.position
			_touch_moved = false
		elif _touch_pressing:
			_touch_pressing = false
			if not _touch_moved:
				if _touch_armed:
					_trigger_card_play()
				else:
					_arm_touch()
		return
	if event is InputEventScreenDrag and _touch_pressing:
		if event.position.distance_to(_touch_start) > 18.0:
			_touch_moved = true
		if event.position.y - _touch_start.y < -70.0:
			_trigger_card_play()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == -1:
			return
		var platform := get_node_or_null("/root/Platform") as PlatformService
		if platform != null and platform.is_touch():
			if event.pressed:
				if _touch_armed:
					_trigger_card_play()
				else:
					_arm_touch()
		elif event.pressed:
			_trigger_card_play()

func _notification(what: int) -> void:
	if not is_inside_tree():
		return
	var platform := get_node_or_null("/root/Platform") as PlatformService
	if what == NOTIFICATION_MOUSE_ENTER:
		if is_available and (platform == null or not platform.is_touch()):
			_is_hovered = true
			add_theme_stylebox_override("panel", _highlight_style)
			_animate_hover(-12.0)
	elif what == NOTIFICATION_MOUSE_EXIT:
		_is_hovered = false
		if is_available:
			add_theme_stylebox_override("panel", _base_style)
		else:
			add_theme_stylebox_override("panel", _disabled_style)
		if not _touch_armed:
			_animate_hover(0.0)
