class_name SchoolObjectPanels
extends Control

signal close_requested
signal action_requested(action: String, payload: Dictionary)
const CARD_SIZE := Vector2(440, 660)
const CARD_STEP := 456.0
const MOTIVES := {"yang_zi_ying": "想拍下这条路的夕阳。", "liu_yu_long": "想赢一场认真的比赛。", "jiang_zi": "想把今天的事务理清。"}
const TOPICS := {"yang_zi_ying": "聊聊摄影", "liu_yu_long": "聊聊比赛", "jiang_zi": "聊聊近况"}
const TINTS: Array[Color] = [Color("#E99383"), Color("#A396CE"), Color("#8EAFCE")]
var panel_kind := ""
var context: Dictionary = {}
var snapshot: Dictionary = {}
var refs: Dictionary = {}
var carousel: SchoolCardCarousel
var _scroll_position := 0.0

static func create(kind: String, panel_context: Dictionary = {}) -> SchoolObjectPanels:
	if kind != "lounge": return null
	var panel := SchoolObjectPanels.new()
	panel.panel_kind = kind
	panel.refresh(panel_context)
	return panel

func refresh(panel_context: Dictionary = {}) -> void:
	context.merge(panel_context, true)
	if is_instance_valid(carousel): _scroll_position = carousel.offset
	snapshot = HomePanels.content_snapshot(panel_kind, str(context.get("selected_card_id", "")))
	# The browser accepts roster data of any length; no three-card layout limit.
	if context.has("classmates"): snapshot["classmates"] = context["classmates"].duplicate(true)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	refs.clear()
	theme = DaylightUI.get_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("design_size", SchoolObjectUI.DESIGN)
	set_meta("full_scene_overlay", true)
	size = SchoolObjectUI.DESIGN
	SchoolObjectUI.art(self, "PhotoFolderBacking", "res://assets/ui/school_objects/lounge_board.png")
	var backing_input := Control.new()
	backing_input.name = "BackingInput"
	backing_input.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backing_input)
	DaylightUI.place(backing_input, 570, 80, 1320, 940)
	SchoolObjectUI.text(self, "Title", "同学交流", Rect2(655, 100, 460, 116), 64)
	SchoolObjectUI.text(self, "Subtitle", "放学后，慢慢聊。", Rect2(1155, 120, 450, 90), 34)
	var close := SchoolObjectUI.hit(self, "CloseButton", Rect2(1750, 80, 86, 86), "×", 54)
	close.pressed.connect(func(): close_requested.emit())
	carousel = SchoolCardCarousel.new()
	carousel.name = "ClassmateCarousel"
	add_child(carousel)
	DaylightUI.place(carousel, 608, 245, 1216, 690)
	carousel.card_step = CARD_STEP
	var track := Control.new()
	track.name = "CardTrack"
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carousel.add_child(track)
	carousel.track = track
	var classmates: Array = snapshot["classmates"]
	carousel.content_width = maxf(0.0, classmates.size() * CARD_STEP - (CARD_STEP - CARD_SIZE.x))
	DaylightUI.place(track, 0, 0, carousel.content_width, CARD_SIZE.y)
	var chats: Dictionary = {}
	var cards: Dictionary = {}
	for index in classmates.size():
		var mate: Dictionary = classmates[index]
		var card := _classmate_card(mate, index)
		track.add_child(card)
		DaylightUI.place(card, index * CARD_STEP, 0, CARD_SIZE.x, CARD_SIZE.y)
		cards[str(mate["id"])] = card
		chats[str(mate["id"])] = card.get_node("Information/Chat_" + str(mate["id"]))
	refs["chat_buttons"] = chats
	refs["classmate_cards"] = cards
	refs["carousel"] = carousel
	var previous := _arrow("PreviousClassmates", Rect2(530, 522, 70, 70), "‹", -1)
	var next := _arrow("NextClassmates", Rect2(1830, 522, 70, 70), "›", 1)
	refs["previous_button"] = previous
	refs["next_button"] = next
	refs["range_label"] = SchoolObjectUI.text(self, "VisibleClassmates", "", Rect2(668, 963, 300, 50), 26, SchoolObjectUI.PURPLE)
	SchoolObjectUI.text(self, "BrowseHint", "左右拖动，看看其他同学。", Rect2(1010, 959, 685, 56), 30)
	carousel.offset_changed.connect(_update_navigation)
	carousel.set_scroll_offset(_scroll_position)

func _arrow(node_name: String, rect: Rect2, glyph: String, direction: int) -> Button:
	var arrow := SchoolObjectUI.hit(self, node_name, rect, glyph, 68)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var circle := StyleBoxFlat.new()
		circle.bg_color = Color("#899BC3") if state == "normal" else Color("#778DB8")
		if state == "disabled": circle.bg_color = Color(0.54, 0.61, 0.77, 0.32)
		circle.border_color = Color(1.0, 0.98, 0.94, 0.68 if state != "disabled" else 0.20)
		circle.set_border_width_all(2)
		circle.set_corner_radius_all(36)
		arrow.add_theme_stylebox_override(state, circle)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		arrow.add_theme_color_override(key, Color("#FFF9EC"))
	arrow.add_theme_color_override("font_disabled_color", Color(1.0, 0.98, 0.94, 0.30))
	arrow.pressed.connect(func(): carousel.browse(direction))
	return arrow

func _classmate_card(mate: Dictionary, index: int) -> Control:
	var card := Control.new()
	card.name = "Classmate_" + str(mate["id"])
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SchoolObjectUI.art(card, "CardBase", "res://assets/ui/school_objects/classmate_card.png", Rect2(Vector2.ZERO, CARD_SIZE))
	var photo := Control.new()
	photo.name = "PhotoWindow"
	photo.clip_contents = true
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(photo)
	DaylightUI.place(photo, 43, 55, 354, 324)
	var portrait := SchoolObjectUI.art(photo, "Portrait", str(mate["portrait"]), Rect2(0, 0, 354, 324))
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var info := Control.new()
	info.name = "Information"
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(info)
	DaylightUI.place(info, 0, 0, CARD_SIZE.x, CARD_SIZE.y)
	var tint: Color = TINTS[index % TINTS.size()]
	# The name slip sits above the photo, independent from the portrait and backing.
	SchoolObjectUI.slab(info, "NameSlip", Rect2(34, 358, 245, 59), Color("#FFF3D9"))
	SchoolObjectUI.text(info, "Name", str(mate["name"]), Rect2(49, 359, 215, 57), 38)
	var motive := SchoolObjectUI.text(info, "Motivation", str(MOTIVES.get(mate["id"], mate.get("subtitle", "放学后，慢慢聊。"))), Rect2(42, 425, 358, 54), 25)
	motive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var unlocked: bool = bool(mate["unlocked"])
	var favor := int(mate["favor"])
	SchoolObjectUI.text(info, "Favor", "熟悉度 %d" % favor if unlocked else "继续行程后可交流", Rect2(42, 486, 360 if not unlocked else 158, 39), 25, SchoolObjectUI.MUTED)
	var progress := ProgressBar.new()
	progress.name = "Familiarity"
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.show_percentage = false
	progress.value = clampi(favor, 0, 100)
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color("#DDD9E6")
	track_style.set_corner_radius_all(8)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = tint
	fill_style.set_corner_radius_all(8)
	progress.add_theme_stylebox_override("background", track_style)
	progress.add_theme_stylebox_override("fill", fill_style)
	info.add_child(progress)
	DaylightUI.place(progress, 202, 500, 192, 13)
	progress.visible = unlocked
	SchoolObjectUI.slab(info, "ChatColor", Rect2(38, 546, 364, 74), tint if unlocked else Color("#D8D5DD"))
	var chat := SchoolObjectUI.hit(info, "Chat_" + str(mate["id"]), Rect2(38, 546, 364, 74), str(TOPICS.get(mate["id"], "聊聊近况")) if unlocked else "尚未交流", 32)
	chat.disabled = not unlocked
	chat.focus_entered.connect(func(): carousel.reveal_card(index, CARD_SIZE.x))
	chat.pressed.connect(func():
		if carousel.suppress_clicks() or SceneManager.is_transitioning: return
		action_requested.emit("chat", {"companion_id": str(mate["id"]), "dialogue_id": str(mate["dialogue_id"])})
	)
	return card

func _update_navigation(value: float) -> void:
	_scroll_position = value
	var previous := refs.get("previous_button") as Button
	var next := refs.get("next_button") as Button
	if not is_instance_valid(previous) or not is_instance_valid(next): return
	previous.disabled = value <= 0.5
	next.disabled = value >= carousel.maximum_offset() - 0.5
	var count: int = snapshot["classmates"].size()
	var first := mini(count, int(floor(value / CARD_STEP)) + 1)
	var last := mini(count, int(ceil((value + carousel.size.x) / CARD_STEP)))
	var range_label := refs.get("range_label") as Label
	if is_instance_valid(range_label):
		range_label.text = "%02d — %02d / %02d 位同学" % [first, last, count] if count > 0 else "还没有认识的同学"
