class_name CampusShopPanel
extends Control

signal close_requested
signal action_requested(action: String, payload: Dictionary)
var refs: Dictionary = {}
var mode := "buy"
var category := "cards"
var selected_id := "card_fake_cheque"
var quantity := 1
var message := ""
var _ticket := ""
var _canvas: Control

static func create() -> CampusShopPanel:
	return CampusShopPanel.new()

func _ready() -> void:
	size = Vector2(1920,1080)
	theme = DaylightUI.get_theme()
	set_meta("full_scene_overlay",true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	refresh()

func refresh(context: Dictionary = {}) -> void:
	message = str(context.get("message",message))
	var owner := get_viewport().gui_get_focus_owner()
	var focus_name := str(owner.name) if owner != null and is_ancestor_of(owner) else ""
	if is_instance_valid(_canvas):
		remove_child(_canvas)
		_canvas.queue_free()
	_canvas = Control.new()
	_canvas.name = "Counter"
	_canvas.size = size
	add_child(_canvas)
	refs.clear()
	SchoolObjectUI.art(_canvas,"LocalShopBackground",SceneDesignCatalog.place_path(CampusLife.current_location))
	TerminalUI.panel(_canvas,"Header",Rect2(50,30,1820,135),Color("#F6F2E5"))
	TerminalUI.text(_canvas,"LocationName",str(RegionCatalog.REGIONS[CampusLife.current_region]["title"])+" · 商店柜台",Rect2(83,51,1260,64),43)
	TerminalUI.text(_canvas,"LocalService","普通卡牌与兴趣用品 · 需要到店办理",Rect2(85,114,1170,40),26,true)
	TerminalUI.text(_canvas,"Balance","零用钱 %d" % GameState.energy_crystals,Rect2(1440,108,350,45),28)
	var close := TerminalUI.button(_canvas,"CloseButton","返回 ×",Rect2(1700,58,133,60))
	close.pressed.connect(func(): close_requested.emit())
	refs["close"] = close
	TerminalUI.panel(_canvas,"ProductsBoard",Rect2(75,194,1110,790),Color("#FAF8F0"))
	TerminalUI.panel(_canvas,"DetailBoard",Rect2(1214,194,626,790),Color("#FAF8F0"))
	TerminalUI.button(_canvas,"Mode_buy","购买",Rect2(108,225,180,60),mode == "buy").pressed.connect(func(): mode = "buy"; quantity = 1; refresh())
	TerminalUI.button(_canvas,"Mode_sell","物品回收",Rect2(307,225,200,60),mode == "sell").pressed.connect(func(): mode = "sell"; category = "materials"; quantity = 1; refresh())
	if CampusPlaces.PLACES[CampusLife.current_location].get("npc","") != "":
		TerminalUI.button(_canvas,"Talk","与值班同学聊聊",Rect2(650,225,350,60)).pressed.connect(func(): action_requested.emit("shop_talk",{}))
	var index := 0
	for id in CampusShopCatalog.CATEGORIES:
		var button := TerminalUI.button(_canvas,"Category_"+id,CampusShopCatalog.CATEGORIES[id],Rect2(109+index*340,310,315,60),category == id)
		button.disabled = mode == "sell" and id == "cards"
		button.pressed.connect(func(): category = id; quantity = 1; refresh())
		index += 1
	var products: Array = CampusShopCatalog.PRODUCTS.keys().filter(func(id: String): return CampusShopCatalog.PRODUCTS[id]["category"] == category)
	if not products.has(selected_id): selected_id = str(products[0]) if not products.is_empty() else ""
	refs["products"] = {}
	index = 0
	for id in products:
		var product := CampusShopCatalog.definition(id)
		var tile := TerminalUI.button(_canvas,"Product_"+id,"",Rect2(110+(index%3)*347,411+(index/3)*260,315,230),id == selected_id)
		SchoolObjectUI.art(tile,"ProductArt",product["icon"],Rect2(32,12,250,133))
		TerminalUI.text(tile,"ProductName",product["name"],Rect2(22,151,276,40),28)
		var copy := "%d 零用钱 · 持有%d" % [int(product[mode]),int(product["owned"])]
		if product["kind"] == "card" and int(product["owned"]) > 0: copy = "已拥有"
		TerminalUI.text(tile,"Price",copy,Rect2(22,195,276,29),21,true)
		tile.pressed.connect(func(): selected_id = id; quantity = 1; message = ""; refresh())
		refs["products"][id] = tile
		index += 1
	if selected_id != "":
		var product := CampusShopCatalog.definition(selected_id)
		TerminalUI.text(_canvas,"SelectedName",product["name"],Rect2(1250,213,550,57),38)
		SchoolObjectUI.art(_canvas,"ProductPreview",product["icon"],Rect2(1250,278,550,180))
		TerminalUI.prose(_canvas,"Description",product["description"],Rect2(1250,495,550,115),27)
		TerminalUI.text(_canvas,"UnitPrice","单价 %d · 持有%d" % [int(product[mode]),int(product["owned"])],Rect2(1250,612,550,50),28)
		var minus := TerminalUI.button(_canvas,"QuantityMinus","−",Rect2(1250,674,95,60))
		minus.disabled = quantity <= 1 or product["kind"] == "card"
		minus.pressed.connect(func(): quantity = maxi(1,quantity-1); refresh())
		TerminalUI.text(_canvas,"Quantity",str(quantity),Rect2(1385,674,80,60),36)
		var plus := TerminalUI.button(_canvas,"QuantityPlus","+",Rect2(1468,674,95,60))
		plus.disabled = quantity >= 99 or product["kind"] == "card"
		plus.pressed.connect(func(): quantity = mini(99,quantity+1); refresh())
		var quote := CampusShopCatalog.quote(selected_id,quantity,mode)
		TerminalUI.text(_canvas,"Total","合计 %d · %s后余款 %d" % [quote["total"],"购买" if mode == "buy" else "回收",GameState.energy_crystals+(-1 if mode == "buy" else 1)*int(quote["total"])],Rect2(1250,761,550,60),26)
		var confirm := TerminalUI.button(_canvas,"ConfirmTrade",quote["message"],Rect2(1250,842,550,60),true)
		confirm.disabled = not quote["ok"]
		_ticket = "shop:%s:%d" % [Crypto.new().generate_random_bytes(16).hex_encode(),get_instance_id()]
		var ticket := _ticket
		confirm.pressed.connect(_trade.bind(ticket,selected_id,quantity,mode))
		refs["confirm"] = confirm
	TerminalUI.text(_canvas,"Feedback",message,Rect2(110,988,1640,35),23)
	TerminalUI.panel(_canvas,"FooterBacking",Rect2(75,1022,1765,50),Color("#F6F2E5"))
	TerminalUI.text(_canvas,"Rules","交易不消耗活动次数 · 星座卡与任务道具不参与交易",Rect2(110,1030,1700,38),24,true)
	TerminalConceptUI.apply(self,"shop")
	if focus_name != "": _restore_focus.call_deferred(focus_name)

func _restore_focus(id: String) -> void:
	var node := find_child(id,true,false) as Control
	if node != null and not (node is BaseButton and node.disabled): node.grab_focus()

func _trade(ticket: String, id: String, amount: int, operation: String) -> void:
	if ticket != _ticket: return
	_ticket = ""
	var result := GameState.execute_shop_trade(id,amount,operation,ticket)
	message = str(result["message"])
	refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()
