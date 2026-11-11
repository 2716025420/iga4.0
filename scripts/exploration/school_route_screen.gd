class_name SchoolRouteScreen
extends Control

const KINDS := {"battle":"练习", "elite":"强化练习", "story":"剧情", "npc":"同学", "merchant":"补给联络点", "chest":"补给箱", "rest":"休息", "boss":"首领", "exit":"出口"}
const COLORS := {"battle":Color("#D99B89"), "elite":Color("#B78B9F"), "story":Color("#A699C1"), "npc":Color("#91AFCA"), "merchant":Color("#C6A275"), "chest":Color("#94AD98"), "rest":Color("#94B5A3"), "boss":Color("#AD7185"), "exit":Color("#839FB7")}
const ATLAS_KINDS := ["battle", "story", "npc", "chest", "merchant", "rest", "boss", "exit"]
var presentation: Control
var content: Control
var refs: Dictionary = {}
var _refresh_pending := false
var _busy := false
var _confirm_retreat := false
var _feedback_node_id := ""
var _feedback_text := ""
var _atlas: Texture2D
var _progress: ProgressTrack

class ProgressTrack extends Control:
	var depth := 0
	var boss_defeated := false
	func _draw() -> void:
		for index in 6:
			var center := Vector2(715 + index * 105, 199)
			var fill := Color("#9AB49F") if index < depth else (Color("#DDA45F") if index == depth else Color("#FFF5DE"))
			draw_circle(center, 17 if index == depth else 10, fill)
			draw_arc(center, 17 if index == depth else 10, 0, TAU, 32, Color("#705D61"), 1.5, true)
		var center := Vector2(1345, 199)
		draw_colored_polygon(PackedVector2Array([center+Vector2(0,-30),center+Vector2(30,0),center+Vector2(0,30),center+Vector2(-30,0)]),Color("#9AB49F") if boss_defeated else Color("#BD7C77"))
		draw_line(Vector2(1460,199),Vector2(1510,199),Color("#59657E"),5,true)
		draw_line(Vector2(1494,183),Vector2(1510,199),Color("#59657E"),5,true)
		draw_line(Vector2(1494,215),Vector2(1510,199),Color("#59657E"),5,true)

func _ready() -> void:
	# Old results belong to the previous visit; opening a route never replays them.
	_feedback_node_id = str(GameState.exploration_state.get("last_result",{}).get("node_id",""))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = DaylightUI.get_theme()
	presentation = Control.new()
	presentation.name = "RoutePresentation"
	presentation.size = SchoolObjectUI.DESIGN
	presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(presentation)
	SchoolObjectUI.art(presentation, "StationBackdrop", "res://assets/ui/school_objects/route_station.png")
	SchoolObjectUI.text(presentation, "Title", "模拟训练", Rect2(145, 35, 270, 90), 53)
	refs["dungeon"] = SchoolObjectUI.text(presentation, "Dungeon", "", Rect2(435, 56, 195, 62), 28)
	refs["hp"] = SchoolObjectUI.text(presentation, "HP", "", Rect2(685, 59, 205, 50), 26, SchoolObjectUI.INK, true)
	refs["points"] = SchoolObjectUI.text(presentation, "Points", "", Rect2(925, 59, 180, 50), 26, SchoolObjectUI.INK, true)
	refs["earned"] = SchoolObjectUI.text(presentation, "Earned", "", Rect2(1125, 59, 305, 50), 24, SchoolObjectUI.INK, true)
	refs["pause"] = _action(presentation, "Pause", Rect2(1507, 57, 156, 50), "Ⅱ  暂离", _pause, Color(0,0,0,0), true)
	refs["retreat"] = _action(presentation, "Retreat", Rect2(1675, 57, 195, 50), "结束训练", _request_retreat, Color(0,0,0,0), true)
	refs["stage"] = SchoolObjectUI.text(presentation, "StageTitle", "", Rect2(223, 164, 325, 65), 28, SchoolObjectUI.INK, true)
	_progress = ProgressTrack.new()
	_progress.name = "ProgressTrack"
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(_progress)
	_progress.size = Vector2(1920,300)
	for index in 8:
		var x: int = 715 + index * 105 if index < 6 else (1345 if index == 6 else 1495)
		SchoolObjectUI.text(presentation, "Checkpoint_" + str(index), str(index+1) if index < 6 else ("首领" if index == 6 else "出口"), Rect2(x-45, 230, 90, 48), 26, SchoolObjectUI.INK, true)
	content = Control.new()
	content.name = "EncounterArea"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(content)
	DaylightUI.place(content, 0, 300, 1920, 600)
	SchoolObjectUI.text(presentation, "DeckTitle", "本次行动卡", Rect2(145, 941, 245, 65), 30, SchoolObjectUI.INK, true)
	refs["feedback_backing"] = SchoolPaperSurface.create(presentation,"FeedbackBacking",Rect2(400,875,1120,50),Color(0.99,0.95,0.86,0.92))
	refs["feedback"] = SchoolObjectUI.text(presentation, "Feedback", "", Rect2(420, 875, 1080, 48), 24, SchoolObjectUI.INK, true)
	var deck := Control.new()
	deck.name = "RunDeck"
	deck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(deck)
	refs["deck"] = deck
	SchoolObjectUI.text(presentation, "FooterHint", "每段只走一条路，暂离后可继续。", Rect2(1160, 958, 425, 64), 23, SchoolObjectUI.MUTED, true)
	if ResourceLoader.exists("res://assets/ui/school_objects/route_encounters.png"): _atlas = load("res://assets/ui/school_objects/route_encounters.png")
	GameState.exploration_changed.connect(_schedule_refresh)
	resized.connect(_layout_route)
	_layout_route()
	_refresh()

func _layout_route() -> void:
	if not is_instance_valid(presentation): return
	var factor := minf(size.x/1920.0, size.y/1080.0)
	presentation.scale = Vector2.ONE * factor
	presentation.position = (size-SchoolObjectUI.DESIGN*factor)/2.0

func _schedule_refresh() -> void:
	if _refresh_pending: return
	_refresh_pending = true
	_refresh.call_deferred()

func _clear(parent: Control) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func _refresh() -> void:
	_refresh_pending = false
	_busy = false
	_clear(content)
	refs["card_buttons"] = {}
	refs["choice_buttons"] = {}
	refs["offer_buttons"] = {}
	var state := GameState.exploration_state
	if not GameState.exploration_active or not SchoolExplorationFlow.enabled():
		SchoolObjectUI.text(content,"NoRun","先到体育馆选择一条模拟训练路线。",Rect2(450,180,1020,90),40,SchoolObjectUI.INK,true)
		_action(content,"ReturnHome",Rect2(760,300,400,80),"返回体育馆",func(): CampusLife.return_from_training())
		return
	var definition := ExplorationContent.dungeon_definition(str(state["dungeon_id"]))
	refs["dungeon"].text = str(definition.get("title", "校园路线"))
	refs["hp"].text = "体力 %d / %d" % [GameState.player_current_hp,GameState.player_max_hp]
	refs["points"].text = "练习点 %d" % GameState.scrap_metal
	var earned: Dictionary = state.get("earned", {})
	var quality := str(definition.get("quality", "common"))
	refs["earned"].text = "本次 %s %d" % [ExplorationContent.MATERIAL_NAMES[quality],int(earned.get("materials", {}).get(quality,0))]
	var depth := int(state.get("depth", 0))
	refs["stage"].text = "第 %d 段" % (depth+1) if depth < 6 else ("出口已开放" if state.get("boss_defeated",false) else "终点挑战 · 所有路线汇合")
	if state.get("stage", "") != "map":
		var current := GameState.get_exploration_node(str(state.get("current_node_id", "")))
		refs["stage"].text = ("第%d段 · " % (depth+1) if depth < 6 else "") + str(KINDS.get(SchoolExplorationRoutes.kind_for(current), "训练途中"))
	_progress.depth = depth
	_progress.boss_defeated = state.get("boss_defeated",false)
	_progress.queue_redraw()
	var last: Dictionary = state.get("last_result", {})
	var result_id := str(last.get("node_id",""))
	if result_id != _feedback_node_id:
		_feedback_node_id = result_id
		var previous_node := GameState.get_exploration_node(result_id)
		# Combat already has a dedicated result sheet.
		_feedback_text = "" if not previous_node.get("enemy_keys",[]).is_empty() else "已完成：%s%s" % [last.get("title","")," · 恢复%d体力" % int(last["heal"]) if int(last.get("heal",0)) > 0 else ""]
	refs["feedback"].text = _feedback_text
	refs["feedback_backing"].visible = refs["feedback"].text != ""
	_clear(refs["deck"])
	var run_deck: Array = state.get("deck", [])
	for index in run_deck.size():
		var id := str(run_deck[index]["id"])
		var art := SchoolObjectUI.art(refs["deck"], "Card_"+id, "",Rect2(465+index*125,941,108,88))
		art.texture = SceneSkin.illustration_texture(SceneSkin.card_illustration_path(id))
	if _confirm_retreat:
		_draw_retreat()
	elif state.get("stage", "") == "map":
		var available := GameState.get_exploration_available_nodes()
		var left := (1920.0-(available.size()*360+(available.size()-1)*50))/2.0
		for index in available.size(): _route_card(GameState.get_exploration_node(available[index]),Vector2(left+index*410,20))
		var buttons: Array = refs["card_buttons"].values()
		for index in buttons.size():
			buttons[index].focus_neighbor_left = buttons[index].get_path_to(buttons[maxi(0,index-1)])
			buttons[index].focus_neighbor_right = buttons[index].get_path_to(buttons[mini(buttons.size()-1,index+1)])
			buttons[index].focus_neighbor_top = buttons[index].get_path_to(refs["pause"])
		if not buttons.is_empty(): buttons[0].grab_focus.call_deferred()
	else:
		_encounter(GameState.get_exploration_node(str(state.get("current_node_id", ""))))

func _illustration(parent: Control, kind: String, rect: Rect2) -> TextureRect:
	var art := SchoolObjectUI.art(parent,"EncounterArt","",rect)
	var key := "battle" if kind == "elite" else kind
	var index := ATLAS_KINDS.find(key)
	if _atlas != null and index >= 0:
		var texture := AtlasTexture.new()
		texture.atlas = _atlas
		var cell := _atlas.get_size()/Vector2(4,2)
		texture.region = Rect2(Vector2(index%4,index/4)*cell,cell)
		texture.filter_clip = true
		art.texture = texture
	return art

func _route_card(node: Dictionary, point: Vector2) -> void:
	var card := Control.new()
	card.name = "Route_"+str(node["id"])
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(card)
	DaylightUI.place(card,point.x,point.y,360,540)
	SchoolObjectUI.art(card,"StandeeBase","res://assets/ui/school_objects/route_standee.png",Rect2(-20,-25,400,600))
	var kind := SchoolExplorationRoutes.kind_for(node)
	_illustration(card,kind,Rect2(39,65,282,243))
	var description := SchoolObjectUI.text(card,"Description",str(node["description"]),Rect2(38,315,286,84),23)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.clip_text = true
	description.set_deferred("size",Vector2(286,84))
	var reward := ExplorationContent.reward_text(node.get("reward",{}))
	if kind == "npc": reward = "帮忙整理 / 停下来聊聊"
	elif kind == "merchant": reward = "整理训练记录"
	elif int(node.get("heal",0)) > 0: reward = "恢复 %d 体力" % int(node["heal"])
	elif kind == "exit": reward = "带着这一趟的收获离开"
	var reward_label := SchoolObjectUI.text(card,"Reward",reward,Rect2(38,400,286,45),22,SchoolObjectUI.MUTED,true)
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_label.clip_text = true
	reward_label.set_deferred("size",Vector2(286,45))
	SchoolPaperSurface.create(card,"RouteAccent",Rect2(24,46,5,57),COLORS.get(kind,COLORS["battle"]))
	SchoolObjectUI.text(card,"RouteName",str(node["title"]),Rect2(42,455,280,43),28,SchoolObjectUI.INK,true)
	var button := SchoolObjectUI.hit(card,"Choose",Rect2(22,40,316,468))
	SchoolObjectUI.borderless(button)
	button.pressed.connect(_choose.bind(str(node["id"])))
	refs["card_buttons"][node["id"]] = button

func _choose(id: String) -> void:
	if _busy or SceneManager.is_transitioning: return
	_busy = true
	_feedback_text = ""
	if not GameState.choose_exploration_node(id): _busy = false

func _encounter(node: Dictionary) -> void:
	if node.is_empty(): return
	var kind := SchoolExplorationRoutes.kind_for(node)
	SchoolPaperSurface.create(content,"EncounterSurface",Rect2(145,25,1630,530),Color(0.99,0.96,0.90,0.95))
	_illustration(content,kind,Rect2(170,60,520,425))
	SchoolObjectUI.text(content,"EncounterTitle",str(node["title"]),Rect2(755,56,945,76),46)
	var copy := SchoolObjectUI.text(content,"EncounterDescription",str(node.get("description","")),Rect2(760,140,925,90),28)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.set_deferred("size",Vector2(925,90))
	match kind:
		"merchant":
			SchoolObjectUI.text(content,"SupplyContact","补给联络点已完成登记，可以继续训练。",Rect2(765,260,925,100),28)
			refs["continue"] = _action(content,"LeaveMerchant",Rect2(1420,461,290,62),"继续训练",_settle.bind("leave"),COLORS[kind])
		"npc":
			for index in node.get("choices",[]).size():
				var choice: Dictionary = node["choices"][index]
				var reward := ExplorationContent.reward_text(choice.get("reward",{})) if int(choice.get("heal",0)) == 0 else "恢复%d体力" % int(choice["heal"])
				var button := _action(content,"Choice_"+str(choice["id"]),Rect2(770,265+index*115,930,88),str(choice["title"])+" · "+reward,_settle.bind(str(choice["id"])),COLORS[kind])
				refs["choice_buttons"][choice["id"]] = button
		"exit":
			SchoolObjectUI.text(content,"ExitSummary",ExplorationContent.reward_text(GameState.exploration_state.get("earned",{}))+"\n此前训练消耗 %d 练习点" % int(GameState.exploration_state.get("spent_points",0)),Rect2(765,255,925,100),28)
			refs["continue"] = _action(content,"ConfirmExit",Rect2(1090,400,610,85),"收好这一趟的收获 · 返回体育馆",_exit_run,COLORS[kind])
		_:
			SchoolObjectUI.text(content,"EncounterReward","恢复%d体力" % int(node.get("heal",0)) if int(node.get("heal",0)) > 0 else ExplorationContent.reward_text(node.get("reward",{})),Rect2(765,255,925,90),30)
			refs["continue"] = _action(content,"SettleEncounter",Rect2(1130,400,570,85),"坐下来歇一会儿" if kind == "rest" else "打开补给箱",_settle.bind("victory"),COLORS.get(kind,COLORS["chest"]))

func _settle(outcome: String) -> void:
	if _busy or SceneManager.is_transitioning: return
	_busy = true
	if not GameState.complete_exploration_node(str(GameState.exploration_state.get("current_node_id","")),outcome): _busy = false

func _exit_run() -> void:
	if _busy or SceneManager.is_transitioning: return
	_busy = true
	if GameState.finish_exploration("victory"): CampusLife.return_from_training()
	else: _busy = false

func _action(parent: Control, node_name: String, rect: Rect2, label: String, callback: Callable, color: Color = Color("#A89BBF"), light_text: bool = false) -> Button:
	if color.a > 0: SchoolPaperSurface.create(parent,node_name+"Plate",rect,color.lightened(0.24))
	var button := SchoolObjectUI.hit(parent,node_name,rect,label,27)
	SchoolObjectUI.borderless(button)
	if light_text:
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: button.add_theme_color_override(state,Color("#FFF6E9"))
	button.pressed.connect(callback)
	return button

func _pause() -> void:
	if not _busy: GameState.pause_exploration()

func _request_retreat() -> void:
	if _busy or SceneManager.is_transitioning: return
	_confirm_retreat = true
	_refresh()

func _draw_retreat() -> void:
	SchoolPaperSurface.create(content,"RetreatSurface",Rect2(145,25,1630,530),Color("#F7F0E6"))
	_illustration(content,"exit",Rect2(170,60,520,425))
	SchoolObjectUI.text(content,"RetreatTitle","结束这次训练？",Rect2(760,90,920,85),46)
	SchoolObjectUI.text(content,"RetreatDescription","已收集的材料与练习点会保留。\n结束后，这条路线将不能继续。",Rect2(760,210,920,120),30)
	refs["cancel_retreat"] = _action(content,"CancelRetreat",Rect2(770,405,420,80),"再走一会儿",func(): _confirm_retreat=false; _refresh(),Color("#A6B9BC"))
	refs["confirm_retreat"] = _action(content,"ConfirmRetreat",Rect2(1270,405,420,80),"结束并返回",func(): GameState.retreat_exploration(),Color("#D2A291"))
	refs["cancel_retreat"].grab_focus.call_deferred()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _confirm_retreat:
			_confirm_retreat = false
			_refresh()
		else: _pause()
		get_viewport().set_input_as_handled()
