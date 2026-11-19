class_name CampusShopPanel
extends Control

signal close_requested
signal action_requested(action: String, payload: Dictionary)
signal clerk_reacted(emotion: String, line: String)

const WARM_PAPER := Color("#FAF5E8")
const CARD_PAPER := Color("#FFFDF8")
const INK := Color("#1E314D")
const MUTED := Color("#5A687D")
const TEAL := Color("#359686")
const CORAL := Color("#D45B49")
const BORDER_WARM := Color("#C9B89B")

var refs: Dictionary = {}
var mode := "buy"
var category := "cards"
var filter_unowned := false
var selected_id := "card_desk_vault"
var quantity := 1
var message := ""
var _ticket := ""
var _canvas: Control
var _clerk_emotion := "neutral"
var _clerk_line := "欢迎光临阿瑞忒校园商店！左栏随便挑，需要推荐的话点我聊聊~"


static func create() -> CampusShopPanel:
	return CampusShopPanel.new()


func _ready() -> void:
	size = Vector2(1920, 1080)
	theme = DaylightUI.get_theme()
	set_meta("full_scene_overlay", true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	refresh()


func _set_clerk(emotion: String, line: String) -> void:
	_clerk_emotion = emotion
	_clerk_line = line
	clerk_reacted.emit(_clerk_emotion, _clerk_line)


func refresh(context: Dictionary = {}) -> void:
	message = str(context.get("message", message))
	var owner := get_viewport().gui_get_focus_owner()
	var focus_name := str(owner.name) if owner != null and is_ancestor_of(owner) else ""
	if is_instance_valid(_canvas):
		remove_child(_canvas)
		_canvas.queue_free()
	_canvas = Control.new()
	_canvas.name = "Counter"
	_canvas.size = size
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	refs.clear()

	var is_arete_shop := CampusLife.current_location == "shop"
	if not is_arete_shop:
		var backdrop := ColorRect.new()
		backdrop.name = "NonAreteBackdrop"
		backdrop.color = Color(0.12, 0.15, 0.22, 0.72)
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
		_canvas.add_child(backdrop)
		DaylightUI.place(backdrop, -260.0, 0.0, 2440.0, 1080.0)

	# 1. Left Ledger & Shelf Panel (03/01 split: x = 28..1004, leaving right half 1020..1920 completely clear!)
	var ledger := Panel.new()
	ledger.name = "ProductsBoard"
	ledger.mouse_filter = Control.MOUSE_FILTER_STOP
	if not DynamicUI.apply_nine_slice_panel(ledger, "res://assets/ui_core/theme/paper_modal_9slice.png", Vector4(32, 32, 32, 32)):
		var lstyle := StyleBoxFlat.new()
		lstyle.bg_color = Color(WARM_PAPER, 0.97)
		lstyle.border_color = BORDER_WARM
		lstyle.set_border_width_all(2)
		lstyle.border_width_bottom = 5
		lstyle.set_corner_radius_all(18)
		lstyle.shadow_color = Color(0.10, 0.14, 0.22, 0.24)
		lstyle.shadow_size = 14
		lstyle.shadow_offset = Vector2(0, 6)
		ledger.add_theme_stylebox_override("panel", lstyle)
	_canvas.add_child(ledger)
	DaylightUI.place(ledger, 28.0, 22.0, 976.0, 1036.0)

	# Header inside Left Ledger
	var region_title := str(RegionCatalog.REGIONS.get(CampusLife.current_region, {}).get("title", "阿瑞忒"))
	var loc_title := SchoolObjectUI.text(_canvas, "LocationName", region_title + " · 商店柜台", Rect2(54.0, 38.0, 440.0, 44.0), 30, INK)
	loc_title.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	loc_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	SchoolObjectUI.text(_canvas, "LocalService", "战术刻印卡 · 练习素材 · 饮品补给", Rect2(56.0, 82.0, 430.0, 28.0), 18, MUTED)

	var buy_btn := _pill_button(_canvas, "Mode_buy", "购买", Rect2(506.0, 44.0, 130.0, 52.0), mode == "buy", TEAL)
	buy_btn.pressed.connect(func():
		mode = "buy"
		quantity = 1
		message = ""
		_set_clerk("neutral", "想添置新卡还是补给素材？选中左边的货架卡片就能看到详情。")
		refresh()
	)
	var sell_btn := _pill_button(_canvas, "Mode_sell", "物品回收", Rect2(648.0, 44.0, 152.0, 52.0), mode == "sell", CORAL)
	sell_btn.pressed.connect(func():
		mode = "sell"
		category = "materials"
		quantity = 1
		message = ""
		_set_clerk("neutral", "多余的练习材料和饮品都能按店价回收换成零用钱哦。")
		refresh()
	)
	var close := _pill_button(_canvas, "CloseButton", "返回柜台 ×", Rect2(812.0, 44.0, 166.0, 52.0), false, Color("#4C75A6"))
	close.pressed.connect(func(): close_requested.emit())
	refs["close"] = close

	SchoolObjectUI.rule(_canvas, "HeaderDivider", Rect2(54.0, 114.0, 924.0, 2.0))

	# Category tabs + FilterUnowned
	var cat_idx := 0
	for cid in CampusShopCatalog.CATEGORIES:
		var id := str(cid)
		var button := _pill_button(_canvas, "Category_" + id, str(CampusShopCatalog.CATEGORIES[id]), Rect2(54.0 + float(cat_idx) * 234.0, 126.0, 220.0, 46.0), category == id, TEAL)
		button.disabled = mode == "sell" and id == "cards"
		button.pressed.connect(func():
			category = id
			quantity = 1
			message = ""
			refresh()
		)
		cat_idx += 1

	if mode == "buy" and category == "cards":
		var unowned_btn := _pill_button(_canvas, "FilterUnowned", "仅看未拥有", Rect2(768.0, 127.0, 210.0, 44.0), filter_unowned, CORAL)
		unowned_btn.add_theme_font_size_override("font_size", 18)
		unowned_btn.pressed.connect(func():
			filter_unowned = not filter_unowned
			refresh()
		)

	# Product shelf grid (3 columns inside ScrollContainer)
	var products: Array = CampusShopCatalog.PRODUCTS.keys().filter(func(pid: String):
		return str(CampusShopCatalog.PRODUCTS[pid]["category"]) == category and CampusShopCatalog.is_product_unlocked(pid) and (not filter_unowned or mode != "buy" or category != "cards" or int(CampusShopCatalog.definition(pid).get("owned", 0)) == 0)
	)
	if not products.has(selected_id):
		selected_id = str(products[0]) if not products.is_empty() else ""

	refs["products"] = {}
	var scroll := ScrollContainer.new()
	scroll.name = "ProductsScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_canvas.add_child(scroll)
	DaylightUI.place(scroll, 52.0, 186.0, 928.0, 466.0)

	var grid := Control.new()
	grid.name = "ProductsGrid"
	grid.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var rows := maxi(2, ceili(float(products.size()) / 3.0))
	grid.custom_minimum_size = Vector2(900.0, float(rows) * 232.0 + 4.0)
	scroll.add_child(grid)

	var p_idx := 0
	for raw_id in products:
		var id := str(raw_id)
		var product := CampusShopCatalog.definition(id)
		var is_sel := id == selected_id
		var tile := _product_tile(grid, "Product_" + id, Rect2(6.0 + float(p_idx % 3) * 304.0, 6.0 + float(p_idx / 3) * 230.0, 288.0, 218.0), is_sel)
		SchoolObjectUI.art(tile, "ProductArt", str(product["icon"]), Rect2(20.0, 10.0, 248.0, 124.0))
		var pname := SchoolObjectUI.text(tile, "ProductName", str(product["name"]), Rect2(14.0, 140.0, 260.0, 36.0), 22, INK, true)
		pname.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pname.clip_text = true
		var copy := "%d 零用钱 · 持有%d" % [int(product[mode]), int(product["owned"])]
		if str(product["kind"]) == "card" and int(product["owned"]) > 0:
			copy = "已拥有"
		var pprice := SchoolObjectUI.text(tile, "Price", copy, Rect2(14.0, 178.0, 260.0, 28.0), 18, CORAL if (str(product["kind"]) == "card" and int(product["owned"]) > 0) else MUTED, true)
		pprice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tile.pressed.connect(func():
			selected_id = id
			quantity = 1
			message = ""
			var item_name := str(product.get("name", ""))
			_set_clerk("neutral", "这张「%s」很实用呢，确认数量后就可以直接结算。" % item_name if str(product.get("kind", "")) == "card" else "选好了「%s」，需要几份呢？" % item_name)
			refresh()
		)
		refs["products"][id] = tile
		p_idx += 1

	# Lower detail card inside Left Ledger
	var detail_card := SchoolObjectUI.slab(_canvas, "DetailBoard", Rect2(52.0, 668.0, 928.0, 312.0), CARD_PAPER)
	if not DynamicUI.apply_nine_slice_panel(detail_card, DynamicUI.THEME_PAPER_CARD, Vector4(44, 36, 32, 32)):
		var dstyle := detail_card.get_theme_stylebox("panel") as StyleBoxFlat
		dstyle.border_color = BORDER_WARM
		dstyle.set_border_width_all(2)
		dstyle.set_corner_radius_all(8)

	if selected_id != "":
		var product := CampusShopCatalog.definition(selected_id)
		var sname := SchoolObjectUI.text(_canvas, "SelectedName", str(product["name"]), Rect2(74.0, 684.0, 520.0, 42.0), 28, INK)
		sname.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
		sname.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		SchoolObjectUI.art(_canvas, "ProductPreview", str(product["icon"]), Rect2(74.0, 738.0, 214.0, 126.0))
		var desc := RichTextLabel.new()
		desc.name = "Description"
		desc.bbcode_enabled = false
		desc.fit_content = false
		desc.scroll_active = false
		desc.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		desc.text = str(product["description"])
		desc.add_theme_font_size_override("normal_font_size", 19)
		desc.add_theme_color_override("default_color", INK)
		desc.add_theme_constant_override("line_separation", 4)
		_canvas.add_child(desc)
		DaylightUI.place(desc, 304.0, 740.0, 312.0, 124.0)
		var uprice := SchoolObjectUI.text(_canvas, "UnitPrice", "单价 %d 零用钱 · 当前持有 %d" % [int(product[mode]), int(product["owned"])], Rect2(74.0, 882.0, 536.0, 34.0), 20, MUTED)
		uprice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var minus := _pill_button(_canvas, "QuantityMinus", "−", Rect2(648.0, 706.0, 74.0, 54.0), false, BORDER_WARM)
		minus.disabled = quantity <= 1 or str(product["kind"]) == "card"
		minus.pressed.connect(func():
			quantity = maxi(1, quantity - 1)
			refresh()
		)
		var qty_lbl := SchoolObjectUI.text(_canvas, "Quantity", str(quantity), Rect2(734.0, 706.0, 88.0, 54.0), 30, INK, true)
		qty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var plus := _pill_button(_canvas, "QuantityPlus", "+", Rect2(834.0, 706.0, 74.0, 54.0), false, BORDER_WARM)
		plus.disabled = quantity >= 99 or str(product["kind"]) == "card"
		plus.pressed.connect(func():
			quantity = mini(99, quantity + 1)
			refresh()
		)
		var quote := CampusShopCatalog.quote(selected_id, quantity, mode)
		var after_bal := GameState.energy_crystals + (-1 if mode == "buy" else 1) * int(quote["total"])
		var total_lbl := SchoolObjectUI.text(_canvas, "Total", "合计 %d 零用钱\n%s后余款 %d" % [int(quote["total"]), "购买" if mode == "buy" else "回收", after_bal], Rect2(632.0, 774.0, 324.0, 62.0), 19, INK, true)
		total_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var confirm := _pill_button(_canvas, "ConfirmTrade", str(quote["message"]), Rect2(646.0, 856.0, 296.0, 62.0), true, CORAL if bool(quote["ok"]) else BORDER_WARM)
		confirm.disabled = not bool(quote["ok"])
		_ticket = "shop:%s:%d" % [Crypto.new().generate_random_bytes(16).hex_encode(), get_instance_id()]
		var ticket := _ticket
		confirm.pressed.connect(_trade.bind(ticket, selected_id, quantity, mode))
		refs["confirm"] = confirm

	var fb := SchoolObjectUI.text(_canvas, "Feedback", message, Rect2(56.0, 988.0, 920.0, 28.0), 18, CORAL, true)
	fb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var rules := SchoolObjectUI.text(_canvas, "Rules", "交易不消耗活动次数 · 已上架行动卡 %d / 16 款（随主线推进到货）" % CampusShopCatalog.unlocked_card_stock_count(), Rect2(56.0, 1018.0, 920.0, 28.0), 18, MUTED, true)
	rules.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 2. Top-Right Allowance Note (matte paper index card, zero small icons)
	var bal_panel := SchoolObjectUI.slab(_canvas, "BalanceBacking", Rect2(1612.0, 24.0, 272.0, 54.0), Color(CARD_PAPER, 0.96))
	if not DynamicUI.apply_nine_slice_panel(bal_panel, DynamicUI.THEME_PAPER_CARD, Vector4(44, 36, 32, 32)):
		var bstyle := bal_panel.get_theme_stylebox("panel") as StyleBoxFlat
		bstyle.border_color = TEAL
		bstyle.set_border_width_all(1)
		bstyle.set_corner_radius_all(8)
	var bal_lbl := SchoolObjectUI.text(_canvas, "Balance", "零用钱  %d" % GameState.energy_crystals, Rect2(1624.0, 31.0, 248.0, 40.0), 22, INK, true)
	bal_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 3. Right Half Live Clerk Speech Bubble + Direct Click Interaction over Tang Xiaoman
	if is_arete_shop or str(CampusPlaces.PLACES.get(CampusLife.current_location, {}).get("npc", "")) != "":
		var speech := Panel.new()
		speech.name = "ClerkSpeechBubble"
		speech.mouse_filter = Control.MOUSE_FILTER_STOP
		var speech_tint := Color(1.0, 0.96, 0.95, 1.0) if _clerk_emotion == "happy" else Color.WHITE
		if not DynamicUI.apply_nine_slice_panel(speech, "panels/ui_clerk_speech_bubble_9slice.png", Vector4(48, 36, 48, 40), speech_tint):
			var spstyle := StyleBoxFlat.new()
			spstyle.bg_color = Color(CARD_PAPER, 0.96)
			spstyle.border_color = CORAL if _clerk_emotion == "happy" else TEAL
			spstyle.set_border_width_all(2)
			spstyle.set_corner_radius_all(10)
			speech.add_theme_stylebox_override("panel", spstyle)
		_canvas.add_child(speech)
		DaylightUI.place(speech, 1038.0, 96.0, 594.0, 114.0)

		var badge := SchoolObjectUI.slab(speech, "ClerkTag", Rect2(26.0, 14.0, 112.0, 30.0), CORAL if _clerk_emotion == "happy" else TEAL)
		var tag_fill := Color("#C85242") if _clerk_emotion == "happy" else Color("#367D6D")
		var tag_border := Color("#9E3B2E") if _clerk_emotion == "happy" else Color("#24594D")
		badge.add_theme_stylebox_override("panel", DynamicUI.make_paper_tag(tag_fill, tag_border, 6))
		var tag_txt := SchoolObjectUI.text(badge, "TagName", "唐小满", Rect2(0.0, 0.0, 112.0, 30.0), 17, Color("#FFFBF2"), true)
		tag_txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var line_lbl := SchoolObjectUI.text(speech, "ClerkLine", _clerk_line, Rect2(24.0, 48.0, 546.0, 56.0), 18, INK)
		line_lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		line_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		DaylightUI.place(line_lbl, 24.0, 48.0, 546.0, 56.0)

		var talk_btn := _pill_button(_canvas, "Talk", "和唐小满聊聊", Rect2(1650.0, 118.0, 234.0, 54.0), false, TEAL)
		talk_btn.pressed.connect(func(): action_requested.emit("shop_talk", {}))

		if is_arete_shop:
			var actor_hit := Button.new()
			actor_hit.name = "ClerkCounterHit"
			actor_hit.flat = true
			actor_hit.focus_mode = Control.FOCUS_NONE
			actor_hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
				actor_hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
			_canvas.add_child(actor_hit)
			DaylightUI.place(actor_hit, 1180.0, 225.0, 440.0, 430.0)
			actor_hit.pressed.connect(func(): action_requested.emit("shop_talk", {}))

	clerk_reacted.emit(_clerk_emotion, _clerk_line)
	if focus_name != "":
		_restore_focus.call_deferred(focus_name)


func _pill_button(parent: Control, node_name: String, copy: String, rect: Rect2, highlighted: bool, accent: Color) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = copy
	parent.add_child(btn)
	DaylightUI.place(btn, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	var fill := accent if highlighted else CARD_PAPER
	var ink := Color("#FFFDF8") if highlighted else INK
	DynamicUI.make_cel_button(btn, fill, ink, accent, 20, 12)
	DaylightUI.bind_button_audio(btn)
	return btn


func _product_tile(parent: Control, node_name: String, rect: Rect2, selected: bool) -> Button:
	var btn := Button.new()
	btn.name = node_name
	btn.text = ""
	btn.custom_minimum_size = rect.size
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(btn)
	DaylightUI.place(btn, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	var margins := Vector4(44, 36, 32, 32)
	var pad := Vector4(8, 8, 8, 8)
	var norm_col := Color(1.0, 0.91, 0.85, 1.0) if selected else Color(1.0, 0.99, 0.97, 1.0)
	var hov_col := Color(1.0, 0.88, 0.81, 1.0) if selected else Color(0.96, 0.93, 0.86, 1.0)
	var prs_col := Color(0.95, 0.82, 0.75, 1.0) if selected else Color(0.91, 0.87, 0.80, 1.0)
	var nbox := DynamicUI.nine_slice_box(DynamicUI.THEME_PAPER_CARD, margins, pad, norm_col, Vector4(-1, -1, -1, -1), rect.size.y)
	if nbox != null:
		var hbox := DynamicUI.nine_slice_box(DynamicUI.THEME_PAPER_CARD, margins, pad, hov_col, Vector4(-1, -1, -1, -1), rect.size.y)
		var pbox := DynamicUI.nine_slice_box(DynamicUI.THEME_PAPER_CARD, margins, pad, prs_col, Vector4(-1, -1, -1, -1), rect.size.y)
		btn.add_theme_stylebox_override("normal", nbox)
		btn.add_theme_stylebox_override("focus", nbox)
		btn.add_theme_stylebox_override("hover", hbox if hbox != null else nbox)
		btn.add_theme_stylebox_override("pressed", pbox if pbox != null else nbox)
		btn.add_theme_stylebox_override("hover_pressed", pbox if pbox != null else nbox)
		btn.add_theme_stylebox_override("disabled", nbox)
	else:
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var st := StyleBoxFlat.new()
			st.bg_color = Color("#FCE6DF") if selected else CARD_PAPER
			if state == "hover":
				st.bg_color = Color("#FFFAF2") if not selected else Color("#FADCD3")
			elif state in ["pressed", "hover_pressed"]:
				st.bg_color = st.bg_color.darkened(0.05)
			st.shadow_color = Color(CORAL, 0.30) if selected else Color(0.14, 0.18, 0.28, 0.10)
			st.shadow_size = 8 if selected else 4
			st.shadow_offset = Vector2(0, 3)
			st.set_corner_radius_all(12)
			btn.add_theme_stylebox_override(state, st)
	SchoolObjectUI.borderless(btn)
	DaylightUI.bind_button_audio(btn)
	return btn


func _restore_focus(id: String) -> void:
	var node := find_child(id, true, false) as Control
	if node != null and not (node is BaseButton and node.disabled):
		node.grab_focus()


func _trade(ticket: String, id: String, amount: int, operation: String) -> void:
	if ticket != _ticket:
		return
	_ticket = ""
	var result := GameState.execute_shop_trade(id, amount, operation, ticket)
	if bool(result.get("ok", false)):
		AudioManager.play_sfx_save()
		var prod := CampusShopCatalog.definition(id)
		var pname := str(prod.get("name", "商品"))
		if operation == "buy":
			_set_clerk("happy", "成交！「%s」已经包好装进你的卡匣包啦，下次对战加油！" % pname)
		else:
			_set_clerk("happy", "「%s」已经按店价回收，零用钱也帮你存好啦！" % pname)
	else:
		_set_clerk("neutral", str(result.get("message", "这次交易没成功，再确认一下条件吧。")))
	message = str(result["message"])
	refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()
