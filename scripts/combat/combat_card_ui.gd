class_name CombatCardUI
extends PanelContainer

signal card_clicked(card_data: CardData)

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
var _base_y: float = 0.0
var _is_base_y_set: bool = false
var _hover_tween: Tween = null
var _paper_art: TextureRect

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
	_paper_art.texture = CombatSkin.actor_texture("res://assets/ui/combat_notebook/action_card.png")
	_paper_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_paper_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_paper_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_paper_art)
	body.move_child(_paper_art, 0)

func layout_notebook_card(extent: Vector2 = CombatPresentation.CARD_SIZE) -> void:
	custom_minimum_size = extent
	size = extent
	var body := get_node("VBox") as Control
	DaylightUI.place(_paper_art, 0, 0, extent.x, extent.y)
	var header := body.get_node("Header") as HBoxContainer
	DaylightUI.place(header, 18, 18, extent.x - 36, 38)
	header.add_theme_constant_override("separation", 5)
	name_label.add_theme_font_size_override("font_size", 29)
	name_label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	DaylightUI.place(body.get_node("CardIllustration"), 22, 61, extent.x - 44, 105)
	DaylightUI.place(desc_label, 18, 166, extent.x - 36, 108)
	desc_label.add_theme_font_size_override("normal_font_size", 26)
	desc_label.add_theme_font_size_override("bold_font_size", 26)
	desc_label.add_theme_constant_override("line_separation", 1)
	var footer := body.get_node("Footer") as HBoxContainer
	DaylightUI.place(footer, 18, 282, extent.x - 36, 27)
	level_label.add_theme_font_size_override("font_size", 22)
	cd_hint_label.add_theme_font_size_override("font_size", 22)
	var divider := body.get_node_or_null("FooterRule") as ColorRect
	if divider == null:
		divider = ColorRect.new()
		divider.name = "FooterRule"
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		divider.color = Color(0.58, 0.49, 0.39, 0.22)
		body.add_child(divider)
	DaylightUI.place(divider, 18, 275, extent.x - 36, 1)
	_refresh_category_tab()
	if not _is_hovered:
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
	
	# Keep card effects visible; cooldown belongs in the footer rather than a full-card overlay.
	cd_badge.visible = false
	if uses_remaining == 0:
		is_available = false
		cd_hint_label.text = "本场已用完"
		cd_hint_label.add_theme_color_override("font_color", DaylightUI.MUTED)
	elif current_cooldown > 0:
		is_available = false
		cd_label.text = "下回合可用" if current_cooldown == 1 else "还需%d回合" % current_cooldown
		cd_hint_label.text = cd_label.text
		cd_hint_label.add_theme_color_override("font_color", DaylightUI.ACCENT)
		add_theme_stylebox_override("panel", _disabled_style)
	else:
		is_available = true
		cd_hint_label.text = "冷却 %d 回合" % card_data.get_current_cooldown()
		cd_hint_label.add_theme_color_override("font_color", DaylightUI.MUTED)
		add_theme_stylebox_override("panel", _highlight_style if _is_hovered else _base_style)
	modulate = Color.WHITE
	if is_instance_valid(_paper_art): _paper_art.modulate = Color.WHITE if is_available else Color(0.72, 0.76, 0.84)

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
	_reset_position_to_base()
	_update_display()

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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_available:
			# 点击时立即将位置安全重置归位，绝不残留浮动偏移
			_is_hovered = false
			_reset_position_to_base()
			card_clicked.emit(card_data)
			
			# 点击缩放微反馈
			if not bool(SaveManager.settings["reduced_motion"]):
				var tween = create_tween()
				tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.06)
				tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.06)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		if is_available:
			_is_hovered = true
			add_theme_stylebox_override("panel", _highlight_style)
			_animate_hover(-12.0)
	elif what == NOTIFICATION_MOUSE_EXIT:
		_is_hovered = false
		if is_available:
			add_theme_stylebox_override("panel", _base_style)
		else:
			add_theme_stylebox_override("panel", _disabled_style)
		_animate_hover(0.0)
