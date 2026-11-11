class_name TerminalConceptUI
extends RefCounted

## Pixel registration from each full concept, not an independently laid-out skin.
const NATIVE := Vector2(1672,941)
const DESIGN := Vector2(1920,1080)
const RECTS := {
	"overview": {
		"DeviceName": [
			230,
			128,
			800,
			48
		],
		"Date": [
			1080,
			132,
			280,
			42
		],
		"CloseButton": [
			1393,
			126,
			124,
			57
		],
		"BackButton": [
			151,
			773,
			190,
			50
		],
		"ReadOnlyTime": [
			1110,
			780,
			400,
			40
		],
		"PersonalDevice": [
			190,
			711,
			160,
			40
		],
		"PageTitle": [
			386,
			184,
			1100,
			65
		],
		"PageSubtitle": [
			388,
			239,
			1070,
			40
		],
		"Feedback": [
			386,
			775,
			1100,
			35
		],
		"Hello": [
			425,
			309,
			660,
			60
		],
		"Welcome": [
			425,
			374,
			660,
			80
		],
		"Status": [
			425,
			455,
			660,
			38
		],
		"CollectionTitle": [
			1178,
			305,
			320,
			44
		],
		"CollectionCount": [
			1178,
			351,
			320,
			75
		],
		"OpenZodiac": [
			1160,
			425,
			332,
			58
		],
		"Open_cards": [
			383,
			537,
			549,
			108
		],
		"Open_journal": [
			953,
			537,
			569,
			108
		],
		"Open_contacts": [
			383,
			665,
			549,
			110
		],
		"Open_inventory": [
			953,
			665,
			569,
			110
		]
	},
	"zodiac": {
		"DeviceName": [
			186,
			108,
			800,
			48
		],
		"Date": [
			1085,
			111,
			260,
			42
		],
		"CloseButton": [
			1384,
			113,
			141,
			55
		],
		"BackButton": [
			130,
			797,
			205,
			46
		],
		"ReadOnlyTime": [
			1095,
			807,
			415,
			40
		],
		"PersonalDevice": [
			165,
			726,
			170,
			42
		],
		"PageTitle": [
			355,
			169,
			1050,
			65
		],
		"PageSubtitle": [
			356,
			226,
			1000,
			36
		],
		"Feedback": [
			355,
			803,
			710,
			36
		],
		"ZodiacName": [
			1115,
			287,
			365,
			64
		],
		"Archetype": [
			1116,
			345,
			365,
			44
		],
		"ZodiacDescription": [
			1115,
			420,
			352,
			215
		],
		"KeyProgress": [
			1115,
			726,
			365,
			46
		],
		"PermanentStory": [
			1116,
			654,
			365,
			54
		]
	},
	"cards": {
		"DeviceName": [
			230,
			128,
			800,
			48
		],
		"Date": [
			1080,
			132,
			280,
			42
		],
		"CloseButton": [
			1393,
			126,
			124,
			57
		],
		"BackButton": [
			151,
			773,
			190,
			50
		],
		"ReadOnlyTime": [
			1110,
			780,
			400,
			40
		],
		"PersonalDevice": [
			190,
			711,
			160,
			40
		],
		"PageTitle": [
			386,
			184,
			1100,
			65
		],
		"PageSubtitle": [
			388,
			239,
			1070,
			40
		],
		"Feedback": [
			386,
			775,
			1100,
			35
		],
		"CardScroll": [
			385,
			294,
			688,
			463
		],
		"CardName": [
			1120,
			306,
			377,
			65
		],
		"CardArt": [
			1120,
			384,
			375,
			132
		],
		"CardDescription": [
			1120,
			523,
			375,
			116
		],
		"OpenWorkshop": [
			1125,
			664,
			370,
			58
		]
	},
	"journal": {
		"DeviceName": [
			230,
			128,
			800,
			48
		],
		"Date": [
			1080,
			132,
			280,
			42
		],
		"CloseButton": [
			1393,
			126,
			124,
			57
		],
		"BackButton": [
			151,
			773,
			190,
			50
		],
		"ReadOnlyTime": [
			1110,
			780,
			400,
			40
		],
		"PersonalDevice": [
			190,
			711,
			160,
			40
		],
		"PageTitle": [
			386,
			184,
			1100,
			65
		],
		"PageSubtitle": [
			388,
			239,
			1070,
			40
		],
		"Feedback": [
			386,
			775,
			1100,
			35
		],
		"Journal_journey": [
			389,
			290,
			256,
			54
		],
		"Journal_growth": [
			662,
			290,
			251,
			54
		],
		"JournalScroll": [
			416,
			389,
			650,
			344
		],
		"TrainingHeading": [
			1152,
			382,
			330,
			60
		],
		"TrainingLog": [
			1152,
			458,
			330,
			263
		]
	},
	"contacts": {
		"DeviceName": [
			219,
			119,
			800,
			48
		],
		"Date": [
			1098,
			125,
			260,
			42
		],
		"CloseButton": [
			1408,
			120,
			117,
			55
		],
		"BackButton": [
			151,
			773,
			190,
			50
		],
		"ReadOnlyTime": [
			1110,
			780,
			400,
			40
		],
		"PersonalDevice": [
			190,
			711,
			160,
			40
		],
		"PageTitle": [
			386,
			181,
			1050,
			65
		],
		"PageSubtitle": [
			388,
			235,
			1050,
			37
		],
		"Feedback": [
			386,
			775,
			1100,
			35
		],
		"ContactName": [
			827,
			304,
			647,
			65
		],
		"ContactStatus": [
			827,
			385,
			647,
			65
		],
		"ContactNotes": [
			827,
			478,
			647,
			206
		]
	},
	"inventory": {
		"DeviceName": [
			230,
			128,
			800,
			48
		],
		"Date": [
			1080,
			132,
			280,
			42
		],
		"CloseButton": [
			1393,
			126,
			124,
			57
		],
		"BackButton": [
			151,
			773,
			190,
			50
		],
		"ReadOnlyTime": [
			1110,
			780,
			400,
			40
		],
		"PersonalDevice": [
			190,
			711,
			160,
			40
		],
		"PageTitle": [
			386,
			184,
			1100,
			65
		],
		"PageSubtitle": [
			388,
			239,
			1070,
			40
		],
		"Feedback": [
			386,
			775,
			1100,
			35
		],
		"Filter_all": [
			388,
			283,
			164,
			54
		],
		"Filter_material": [
			567,
			283,
			160,
			54
		],
		"Filter_quest": [
			741,
			283,
			164,
			54
		],
		"Filter_item": [
			918,
			283,
			163,
			54
		],
		"InventorySearch": [
			1108,
			283,
			190,
			54
		],
		"InventorySort": [
			1315,
			283,
			160,
			54
		],
		"SortDirection": [
			1483,
			283,
			35,
			54
		],
		"InventoryScroll": [
			388,
			355,
			693,
			352
		],
		"ItemName": [
			1230,
			367,
			270,
			60
		],
		"ItemDescription": [
			1136,
			480,
			350,
			148
		],
		"UseDrink": [
			1136,
			641,
			350,
			49
		],
		"ItemIcon": [
			1128,
			370,
			85,
			85
		]
	},
	"shop": {
		"LocationName": [
			139,
			79,
			1060,
			65
		],
		"LocalService": [
			142,
			145,
			1025,
			45
		],
		"Balance": [
			1207,
			130,
			185,
			45
		],
		"CloseButton": [
			1414,
			91,
			125,
			59
		],
		"Mode_buy": [
			131,
			230,
			151,
			55
		],
		"Mode_sell": [
			297,
			230,
			178,
			55
		],
		"Talk": [
			572,
			230,
			200,
			55
		],
		"Category_cards": [
			131,
			301,
			262,
			56
		],
		"Category_materials": [
			408,
			301,
			278,
			56
		],
		"Category_supplies": [
			700,
			301,
			278,
			56
		],
		"SelectedName": [
			1064,
			218,
			471,
			57
		],
		"ProductPreview": [
			1064,
			285,
			473,
			185
		],
		"Description": [
			1070,
			495,
			460,
			70
		],
		"UnitPrice": [
			1070,
			579,
			460,
			45
		],
		"QuantityMinus": [
			1070,
			630,
			103,
			55
		],
		"Quantity": [
			1214,
			630,
			60,
			55
		],
		"QuantityPlus": [
			1302,
			630,
			93,
			55
		],
		"Total": [
			1070,
			706,
			460,
			45
		],
		"ConfirmTrade": [
			1070,
			759,
			467,
			67
		],
		"Feedback": [
			136,
			831,
			1350,
			35
		],
		"Rules": [
			169,
			863,
			1300,
			35
		]
	}
}
const NAV := {
	"overview": [
		160,
		208,
		186,
		62,
		71
	],
	"zodiac": [
		134,
		197,
		184,
		61,
		79
	],
	"cards": [
		159,
		207,
		186,
		61,
		75
	],
	"journal": [
		156,
		202,
		192,
		64,
		75
	],
	"contacts": [
		143,
		207,
		201,
		68,
		73
	],
	"inventory": [
		153,
		207,
		192,
		66,
		72
	]
}

static func _rect(values: Array) -> Rect2:
	return Rect2(Vector2(values[0],values[1])*DESIGN/NATIVE,Vector2(values[2],values[3])*DESIGN/NATIVE)

static func register(node: Control, values: Array) -> void:
	var rect := _rect(values)
	node.position = rect.position
	node.size = rect.size
	node.set_meta("concept_source_rect",Rect2(values[0],values[1],values[2],values[3]))

static func overlay(button: Button) -> void:
	for state in ["normal","disabled","focus"]: button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["hover","pressed","hover_pressed"]:
		var wash := StyleBoxFlat.new()
		wash.bg_color = Color(0.2,0.42,0.51,0.07 if state == "hover" else 0.15)
		wash.set_corner_radius_all(12)
		button.add_theme_stylebox_override(state,wash)

static func apply(host: Control, page: String) -> void:
	if page != "shop": TerminalProjection.reset(host)
	for node in host.find_children("*","TextureRect",true,false):
		if node.get_meta("terminal_dynamic_patch",false):
			node.get_parent().remove_child(node)
			node.queue_free()
	var art := host.find_child("DeviceChassis",true,false) as TextureRect
	if art == null: art = host.find_child("LocalShopBackground",true,false) as TextureRect
	art.texture = load("res://assets/ui/student_terminal/layouts/"+page+".png")
	art.stretch_mode = TextureRect.STRETCH_SCALE
	for panel in host.find_children("*","Panel",true,false): panel.hide()
	for button in host.find_children("*","Button",true,false): overlay(button)
	for id in RECTS[page]:
		var node := host.find_child(id,true,false) as Control
		if node != null: register(node,RECTS[page][id])
	if page == "shop":
		_shop(host)
		return
	var nav: Array = NAV[page]
	var index := 0
	for id in StudentTerminal.PAGES:
		var tab: Button = host.refs["tabs"][id]
		register(tab,[nav[0],nav[1]+index*nav[4],nav[2],nav[3]])
		register(tab.get_node("AppIcon"),[16,16,32,32])
		register(tab.get_node("AppName"),[69,9,116,45])
		index += 1
	if page == "overview":
		_plate(host.find_child("OpenZodiac",true,false),art.texture,Rect2(165,281,180,60))
		var picture := SchoolObjectUI.art(art.get_parent(),"GreetingIllustration","",_rect([718,282,400,224]))
		var crop := AtlasTexture.new()
		crop.atlas = load("res://assets/ui/student_terminal/greeting.png")
		crop.region = Rect2(720,305,800,412)
		picture.texture = crop
		picture.set_meta("terminal_dynamic_patch",true)
		art.get_parent().move_child(picture,art.get_index()+1)
		for id in ["cards","journal","contacts","inventory"]:
			var tile := host.find_child("Open_"+id,true,false) as Button
			register(tile.get_node("Title"),[120,18,420,42])
			register(tile.get_node("Note"),[120,66,420,35])
			register(tile.get_node("AppIcon"),[30,27,62,62])
	elif page == "zodiac":
		index = 0
		for tile in host.refs["badges"].values():
			register(tile,[355+(index%4)*178.5,271+(index/4)*177,166,166])
			var icon: Control = tile.get_node("BadgeIcon")
			register(icon,[41,12,84,82])
			register(tile.get_node("Name"),[18,99,130,34])
			register(tile.get_node("State"),[18,131,130,24])
			index += 1
	elif page == "contacts":
		index = 0
		for tile in host.find_children("Contact_*","Button",true,false):
			register(tile,[389,287+index*151,383,134])
			index += 1
	elif page == "cards":
		for tile in host.refs["cards"].values():
			tile.custom_minimum_size = Vector2(249,253)
			register(tile.get_node("Art"),[20,19,170,110])
			register(tile.get_node("Name"),[20,139,186,36])
			register(tile.get_node("Level"),[20,178,186,28])
	elif page == "inventory":
		for tile in host.refs.get("items",{}).values():
			tile.custom_minimum_size = Vector2(790,120)
			_plate(tile,art.texture,Rect2(388,355,694,104))
		var use := host.find_child("UseDrink",true,false) as Button
		if use != null: _plate(use,art.texture,Rect2(567,283,160,54))
		var direction := host.find_child("SortDirection",true,false) as Button
		direction.text = "↓" if host.descending else "↑"
	_shared_chrome(host)
	TerminalProjection.apply(host,page)
	# Input-only overlays inherit the actual perspective already painted into the mother layer.
	# A button's source rectangle is also its live input registration, under the same 16:9 transform.

static func _shop(host: Control) -> void:
	_blank_patch(host,[129,374,855,463],[104,374,14,463])
	_blank_patch(host,[128,297,855,63],[104,297,14,63])
	var index := 0
	for tile in host.refs["products"].values():
		register(tile,[131+(index%3)*289,377+(index/3)*235,271,221])
		_plate(tile,load("res://assets/ui/student_terminal/layouts/shop.png"),Rect2(131,377,271,221))
		register(tile.get_node("ProductArt"),[20,13,231,133])
		register(tile.get_node("ProductName"),[20,153,231,35])
		register(tile.get_node("Price"),[20,191,231,26])
		index += 1
	# Recycle/material modes use the same extracted plates at their original registration.
	var texture: Texture2D = load("res://assets/ui/student_terminal/layouts/shop.png")
	for id in ["cards","materials","supplies"]:
		var node := host.find_child("Category_"+id,true,false) as Button
		_plate(node,texture,Rect2(131,301,262,56) if id == host.category else Rect2(408,301,278,56))


static func _plate(button: Button, texture: Texture2D, region: Rect2) -> void:
	var crop := AtlasTexture.new()
	crop.atlas = texture
	crop.region = region
	var style := StyleBoxTexture.new()
	style.texture = crop
	style.set_texture_margin_all(14)
	button.add_theme_stylebox_override("normal",style)
	for state in ["hover","pressed","hover_pressed"]:
		var wash := style.duplicate() as StyleBoxTexture
		wash.modulate_color = Color(0.94,1.0,1.0) if state == "hover" else Color(0.86,0.93,0.94)
		button.add_theme_stylebox_override(state,wash)

static func _blank_patch(host: Control, target: Array, source: Array) -> void:
	var image := host.find_child("DeviceChassis",true,false) as TextureRect
	if image == null: image = host.find_child("LocalShopBackground",true,false) as TextureRect
	var patch := TextureRect.new()
	patch.name = "DynamicListBacking"
	patch.set_meta("terminal_dynamic_patch",true)
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	patch.stretch_mode = TextureRect.STRETCH_SCALE
	var crop := AtlasTexture.new()
	crop.atlas = image.texture
	crop.region = Rect2(source[0],source[1],source[2],source[3])
	patch.texture = crop
	image.get_parent().add_child(patch)
	image.get_parent().move_child(patch,image.get_index()+1)
	register(patch,target)


static func _shared_chrome(host: Control) -> void:
	var texture: Texture2D = load("res://assets/ui/student_terminal/layouts/overview.png")
	for id in ["DeviceName","Date","CloseButton","BackButton","ReadOnlyTime","PersonalDevice","Feedback"]:
		var node := host.find_child(id,true,false) as Control
		if node != null:
			register(node,RECTS["overview"][id])
			node.set_meta("terminal_fixed_chrome",true)
	var index := 0
	for id in StudentTerminal.PAGES:
		var tab: Button = host.refs["tabs"][id]
		register(tab,[160,208+index*71,186,62])
		tab.set_meta("terminal_fixed_chrome",true)
		_plate(tab,texture,Rect2(160,208,186,62) if id == host.current_tab else Rect2(165,281,180,60))
		index += 1
