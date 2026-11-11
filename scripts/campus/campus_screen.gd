class_name CampusScreen
extends Control

const DESIGN := Vector2(1920,1080)
var presentation: Control
var refs: Dictionary = {}
var location_id := "map"
var dialogue: CampusDialogueUI
var _sleep_confirm := false
var _busy := false
var _fade: ColorRect
var system_menu: GameMenu
var _workspace: Control
var _workspace_focus: Control
var object_home: RegionHomeView
var scene_objects: SceneObjectView

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 theme = DaylightUI.get_theme()
 mouse_filter = Control.MOUSE_FILTER_STOP
 location_id = CampusLife.current_location
 presentation = Control.new()
 presentation.name = "CampusPresentation"
 presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
 presentation.size = DESIGN
 add_child(presentation)
 _build_place()
 if GameState.archive_return_tab != "" and RegionCatalog.is_home(location_id):
  _restore_records.call_deferred()
 GameState.game_time_changed.connect(_refresh_clock)
 resized.connect(_layout)
 _layout()

func _layout() -> void:
 var factor := minf(size.x/DESIGN.x,size.y/DESIGN.y)
 presentation.scale = Vector2.ONE*factor
 presentation.position = (size-DESIGN*factor)/2.0

func _button(parent: Control, node_name: String, copy: String, rect: Rect2, primary: bool = false) -> Button:
 var button := SchoolObjectUI.hit(parent,node_name,rect,copy,27)
 for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
  var tint := Color.WHITE
  if state == "hover": tint = Color(1.08,1.04,0.95)
  elif state in ["pressed","hover_pressed"]: tint = Color(0.83,0.87,0.91)
  elif state == "disabled": tint = Color(0.72,0.73,0.76)
  button.add_theme_stylebox_override(state,SceneSkin.style("button_lavender" if primary else "button_plain",Vector4(24,10,24,10),tint))
 SchoolObjectUI.borderless(button)
 button.disabled = _busy
 return button

func _build_place() -> void:
 if not CampusPlaces.PLACES.has(location_id): _travel("map"); return
 var data: Dictionary = CampusPlaces.PLACES[location_id]
 if RegionHomeView.artwork_available(location_id):
  _build_object_home()
  return
 if not SceneDesignCatalog.place_config(location_id).is_empty():
  _build_scene_objects()
  return
 if data.get("test",false):
  _build_test_place(data)
  return
 if data.get("geometry",false): _build_geometry_place(data)
 else: SchoolObjectUI.art(presentation,"PlaceBackground",CampusPlaces.ROOT+str(data.get("background","")))
 var npc_id := str(data.get("npc",""))
 if npc_id != "": _build_actor(npc_id)
 var title := _button(presentation,"LocationTitle",str(data["title"]),Rect2(62,28,600,87))
 title.mouse_filter = Control.MOUSE_FILTER_IGNORE
 title.focus_mode = Control.FOCUS_NONE
 title.add_theme_font_size_override("font_size",38)
 var time := SchoolObjectUI.text(presentation,"DayTime",GameState.get_detailed_time_string(),Rect2(690,45,620,55),25,Color("#FFF8E8"),true)
 if data.get("geometry",false):
  time.add_theme_color_override("font_color",Color(RegionCatalog.REGIONS[CampusLife.current_region]["ink"]))
 time.add_theme_constant_override("outline_size",0 if data.get("geometry",false) else 3)
 time.add_theme_color_override("font_outline_color",Color("#3E4D6C"))
 var map_button := _button(presentation,"OpenMap",str(RegionCatalog.REGIONS[CampusLife.current_region]["title"])+"地图",Rect2(1560,30,285,80))
 map_button.pressed.connect(_travel.bind("map"))
 refs["map_button"] = map_button
 var menu := _button(presentation,"OpenMenu","菜单",Rect2(1350,30,180,80))
 menu.pressed.connect(_open_menu)
 var actions: Array = data["actions"]
 refs["actions"] = {}
 for index in actions.size():
  var item: Dictionary = actions[index]
  var button := _button(presentation,"Action_"+str(item["id"]),str(item["label"]),Rect2(105+index*580,963,550,76),index == 0)
  button.pressed.connect(_action.bind(item))
  refs["actions"][item["id"]] = button
 if data.get("geometry",false):
  var strip := SchoolObjectUI.slab(presentation,"DescriptionBacking",Rect2(95,869,1730,82),Color(0.12,0.17,0.22,0.88))
  strip.set_meta("role","readable_description")
 var intro := SchoolObjectUI.text(presentation,"LocationDescription",str(data["description"]),Rect2(112,884,1110,59),26,Color("#FFF8EB"))
 intro.add_theme_color_override("font_outline_color",Color("#374562"))
 intro.add_theme_constant_override("outline_size",3)
 intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 intro.clip_text = true

func _build_geometry_place(data: Dictionary) -> void:
 var geometry := RegionGeometry.new()
 geometry.name = "GeometricPlaceLayout"
 geometry.region_id = CampusLife.current_region
 geometry.place_id = location_id
 presentation.add_child(geometry)
 SchoolObjectUI.text(presentation,"GeometryCaption","体育馆 · 训练入口" if location_id == "gym" else "空间布局 · "+str(RegionCatalog.REGIONS[CampusLife.current_region]["title"]),Rect2(110,180,1100,70),40,Color(RegionCatalog.REGIONS[CampusLife.current_region]["accent"]))
 var zones: Array = RegionCatalog.PLACE_ZONES.get(location_id,["入口","主要功能区","交流区"])
 for i in zones.size():
  var plate := SchoolObjectUI.slab(presentation,"ZonePlate"+str(i),Rect2(560+i*330,540+(i%2)*80,290,82),Color(RegionCatalog.REGIONS[CampusLife.current_region]["paper"]))
  SchoolObjectUI.text(plate,"ZoneName",str(zones[i]),Rect2(8,14,274,55),25,Color(RegionCatalog.REGIONS[CampusLife.current_region]["ink"]),true)
 var note := SchoolObjectUI.text(presentation,"PlacePurpose",str(data["description"]),Rect2(110,266,1450,70),28,Color(RegionCatalog.REGIONS[CampusLife.current_region]["ink"]))
 note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _open_menu() -> void:
 if _busy or _sleep_confirm or is_instance_valid(dialogue) or is_instance_valid(_workspace) or is_instance_valid(system_menu): return
 system_menu = GameMenu.new()
 presentation.add_child(system_menu)
 set_meta("region_modal_open",true)
 system_menu.close_requested.connect(func():
  system_menu.queue_free()
  system_menu = null
  set_meta("region_modal_open",false)
 )

func _restore_records() -> void:
 if SceneManager.is_transitioning: await SceneManager.scene_transition_completed
 if not is_inside_tree(): return
 var tab := GameState.archive_return_tab
 GameState.archive_return_tab = ""
 _open_workspace("records",{"tab":tab})

func _open_workspace(kind: String, context: Dictionary = {}) -> void:
 if SceneManager.is_transitioning or is_instance_valid(_workspace) or is_instance_valid(dialogue) or is_instance_valid(system_menu): return
 if kind == "training" and location_id != "gym": return
 if is_instance_valid(object_home) and kind in ["workshop","records"]: object_home.select_object(kind)
 _workspace_focus = get_viewport().gui_get_focus_owner()
 if kind == "training": _workspace = CampusGuidePanel.create("quest",context)
 elif kind in ["records","warehouse"]: _workspace = StudentTerminal.create("inventory" if kind == "warehouse" else "overview",context)
 elif kind == "shop":
  if not CampusShopCatalog.is_shop_location(location_id): return
  _workspace = CampusShopPanel.create()
 else: _workspace = PlayerWorkspace.create("workshop",context)
 _workspace.name = "LocationWorkspace"
 presentation.add_child(_workspace)
 set_meta("region_modal_open",true)
 _workspace.close_requested.connect(_close_workspace)
 _workspace.action_requested.connect(_workspace_action)
 var close := _workspace.find_child("CloseButton",true,false) as Button
 if close != null: close.grab_focus.call_deferred()

func _close_workspace() -> void:
 if not is_instance_valid(_workspace): return
 var panel := _workspace
 _workspace = null
 panel.hide()
 panel.queue_free()
 set_meta("region_modal_open",false)
 if is_instance_valid(object_home): object_home.select_object()
 if is_instance_valid(scene_objects): scene_objects.select_object()
 if is_instance_valid(_workspace_focus): _workspace_focus.grab_focus()

func _workspace_action(action: String, payload: Dictionary) -> void:
 if SceneManager.is_transitioning or not is_instance_valid(_workspace): return
 var message := ""
 match action:
  "close": _close_workspace(); return
  "shop_talk":
   _close_workspace()
   _action({"id":"talk"})
   return
  "start_exploration":
   if location_id != "gym": return
   if GameState.start_exploration(str(payload.get("dungeon_id",""))): _close_workspace()
   else: _workspace.refresh({"message":"这条路线暂不可用，请先继续或结束当前训练。"})
   return
  "open_workshop": _close_workspace(); _open_workspace("workshop"); return
  "select_card": _workspace.refresh({"selected_card_id":str(payload.get("card_id",""))}); return
  "save_loadout","apply_loadout":
   var index := int(payload.get("index",0))
   var ok := PlayerJourney.save_loadout(index,payload.get("card_ids",GameState.equipped_card_ids)) if action == "save_loadout" else PlayerJourney.apply_loadout(index)
   message = ("卡组方案已保存" if action == "save_loadout" else "卡组方案已应用") if ok else "方案不可用，卡组至少保留一张攻击卡。"
  "upgrade_card":
   var id := str(payload.get("card_id",""))
   var quality := str(payload.get("quality","common"))
   message = "练习完成，行动卡已经提升" if GameState.upgrade_card(id,quality) else str(PlayerJourney.training_quote(id,quality)["reason"])
  "claim_milestone": message = "成长奖励已放入仓库" if PlayerJourney.claim_milestone(str(payload.get("id",""))) else "尚未达成或已经领取。"
  "use_drink": message = "已恢复体力" if PlayerJourney.use_drink() else "请在地区 Home 使用补给，并确认体力与库存。"
  "start_chapter":
   _close_workspace()
   CampusLife.travel_to("club")
   return
  "replay_memory":
   if PlayerJourney.open_memory(str(payload.get("dialogue_id",""))): _close_workspace()
   return
 _workspace.refresh({"message":message})

func _build_actor(npc_id: String) -> void:
 var spec: Dictionary = CampusPlaces.NPCS[npc_id]
 var actor := SchoolObjectUI.art(presentation,"ResidentNPC","",Rect2(-30,70,1920,1000))
 if spec.has("texture"): actor.texture = load(CampusPlaces.ROOT+str(spec["texture"]))
 else:
  actor.texture = load(str(spec["path"]))
  DaylightUI.place(actor,1130,130,620,880)
 actor.set_meta("npc_id",npc_id)
 refs["npc"] = actor

func _travel(target: String) -> void:
 if _busy or _sleep_confirm or is_instance_valid(dialogue) or is_instance_valid(system_menu) or is_instance_valid(_workspace): return
 CampusLife.travel_to(target)

func _action(item: Dictionary) -> void:
 if _busy or _sleep_confirm or is_instance_valid(dialogue) or is_instance_valid(_workspace) or is_instance_valid(system_menu): return
 match str(item["id"]):
  "coast_observe": _show_dialogue([["TEST","海风沿着道路吹过。这里暂作阿瑞忒沿海生活空间的场景提案，正式事件待完善。"]])
  "complete_visit": CampusLife.complete_first_visit()
  "partner_test": _show_dialogue([["TEST","伙伴交流入口。伙伴身份、正式对白与互动内容尚待主创编写。"]])
  "test_difficulty": _show_dialogue([["TEST","难度、关卡、奖励及时间规则尚待确认。此入口不启动正式副本。"]])
  "go": _travel(str(item["target"]))
  "talk": _show_dialogue(CampusLife.npc_lines(str(CampusPlaces.PLACES[location_id]["npc"])))
  "study": _show_dialogue(CampusLife.study())
  "sleep": _confirm_sleep()
  "training": _open_workspace("training")
  "workshop": _open_workspace("workshop")
  "records": _open_workspace("records")
  "warehouse": _open_workspace("warehouse")
  "shop": _open_workspace("shop")
  "preview": _show_dialogue([["空间规划",str(CampusPlaces.PLACES[location_id]["description"])],["空间规划","地点已接入地区地图，正式剧情与专属系统将在这里补充。"]])
  _: _show_dialogue(CampusLife.inspect(str(item["id"])))

func _show_dialogue(lines: Array) -> void:
 if lines.is_empty() or is_instance_valid(dialogue): return
 set_meta("campus_dialogue_open",true)
 var return_focus := get_viewport().gui_get_focus_owner()
 _set_actions_visible(false)
 dialogue = CampusDialogueUI.new()
 dialogue.lines = lines
 presentation.add_child(dialogue)
 dialogue.closed.connect(func():
  dialogue = null
  set_meta("campus_dialogue_open",false)
  _set_actions_visible(true)
  if is_instance_valid(object_home): object_home.select_object()
  if is_instance_valid(scene_objects): scene_objects.select_object()
  if is_instance_valid(return_focus) and return_focus.is_inside_tree(): return_focus.grab_focus()
 )
 if refs.has("npc") and refs["npc"].texture != null and str(lines[0][0]) != "我":
  # The existing story frame's portrait slot is optional; keep a quiet image
  # rather than copying a whole scene background into the small portrait.
  var npc_id := str(CampusPlaces.PLACES[location_id].get("npc",""))
  if npc_id == "liu_yu_long": dialogue.portrait.texture = load("res://assets/sprites/characters/phase_two/portraits/liu_yu_long.png")
  elif npc_id in ["lin_zhi_xia","tang_xiao_man"]:
   var face := AtlasTexture.new()
   face.atlas = refs["npc"].texture
   face.region = Rect2(1205,0,260,300) if npc_id == "lin_zhi_xia" else Rect2(1122,40,250,280)
   face.filter_clip = true
   dialogue.portrait.texture = face

func _confirm_sleep() -> void:
 if _sleep_confirm: return
 _sleep_confirm = true
 var curtain := ColorRect.new()
 curtain.name = "SleepConfirmation"
 curtain.color = Color(0.14,0.18,0.27,0.48)
 curtain.mouse_filter = Control.MOUSE_FILTER_STOP
 presentation.add_child(curtain)
 DaylightUI.place(curtain,0,0,1920,1080)
 var plate := Panel.new()
 plate.add_theme_stylebox_override("panel",SceneSkin.style("panel_frame",Vector4(30,25,30,25)))
 curtain.add_child(plate)
 DaylightUI.place(plate,540,340,840,360)
 SchoolObjectUI.text(plate,"SleepQuestion",DayCycle.rest_label()+"？",Rect2(65,40,710,85),38,SchoolObjectUI.INK,true)
 SchoolObjectUI.text(plate,"SleepDescription","休息会推进到下一个时段。",Rect2(70,135,700,55),27,SchoolObjectUI.MUTED,true)
 var cancel := _button(plate,"CancelSleep","再待一会儿",Rect2(55,235,340,78))
 cancel.pressed.connect(func(): _sleep_confirm = false; curtain.queue_free())
 var confirm := _button(plate,"ConfirmSleep",DayCycle.rest_label(),Rect2(445,235,340,78),true)
 confirm.pressed.connect(func():
  if _busy: return
  _busy = true
  curtain.queue_free()
  _sleep_confirm = false
  _sleep()
 )
 cancel.grab_focus()

func _sleep() -> void:
 _fade = ColorRect.new()
 _fade.name = "OvernightFade"
 _fade.mouse_filter = Control.MOUSE_FILTER_STOP
 _fade.color = Color("#172337")
 _fade.modulate.a = 0.0
 presentation.add_child(_fade)
 DaylightUI.place(_fade,0,0,1920,1080)
 var tween := create_tween()
 tween.tween_property(_fade,"modulate:a",1.0,SaveManager.motion_duration(0.45))
 await tween.finished
 var lines: Array = CampusLife.sleep_to_morning()
 refs.clear()
 # Keep the transition above the rebuilt room until its new date is ready.
 for node in presentation.get_children():
  if node != _fade:
   presentation.remove_child(node)
   node.queue_free()
 _build_place()
 presentation.move_child(_fade,-1)
 tween = create_tween()
 tween.tween_property(_fade,"modulate:a",0.0,SaveManager.motion_duration(0.5))
 await tween.finished
 _fade.queue_free()
 _fade = null
 _busy = false
 for button in presentation.find_children("*","Button",true,false): button.disabled = false
 _show_dialogue(lines)

func _input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_ESCAPE: return
 if is_instance_valid(dialogue): return
 if is_instance_valid(system_menu):
  system_menu.go_back()
  get_viewport().set_input_as_handled()
  return
 if is_instance_valid(_workspace):
  _close_workspace()
  get_viewport().set_input_as_handled()
  return
 if _busy: get_viewport().set_input_as_handled(); return
 if _sleep_confirm:
  _sleep_confirm = false
  var confirmation := presentation.get_node_or_null("SleepConfirmation")
  if confirmation != null: confirmation.queue_free()
 else:
  _travel(str(CampusPlaces.PLACES[location_id]["parent"]))
 get_viewport().set_input_as_handled()

func _set_actions_visible(value: bool) -> void:
 if is_instance_valid(scene_objects):
  scene_objects.set_interactions_enabled(value)
  return
 if is_instance_valid(object_home):
  object_home.set_interactions_enabled(value)
  return
 for button in refs.get("actions",{}).values(): button.visible = value
 var description := presentation.get_node_or_null("LocationDescription")
 if description != null: description.visible = value

func _refresh_clock(_day: int, _hour: int, _minute: int, _weekday: String) -> void:
 var clock := presentation.get_node_or_null("DayTime") as Label
 if clock != null: clock.text = GameState.get_detailed_time_string()


func _build_test_place(data: Dictionary) -> void:
 var ink := Color("#E7EBED")
 SchoolObjectUI.slab(presentation,"TestBackground",Rect2(0,0,1920,1080),Color("#20262D"))
 SchoolObjectUI.text(presentation,"LocationTitle",str(data["title"]),Rect2(95,40,1190,95),40,ink)
 SchoolObjectUI.text(presentation,"DayTime",GameState.get_detailed_time_string(),Rect2(100,150,1200,50),25,ink)
 SchoolObjectUI.text(presentation,"TestNotice","TEST 工程占位 · 非正式场景 · 整页概念尚未批准，未拆层、未替换正式美术",Rect2(100,260,1730,70),28,ink)
 var description := SchoolObjectUI.text(presentation,"LocationDescription",str(data["description"]),Rect2(100,380,1700,220),32,ink)
 description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var map_copy := str(data.get("map_object_label",""))
 map_copy = map_copy+"\n地区地图" if map_copy != "" else "地区地图"
 var map_button := MapPageUI.button(presentation,"OpenMap",map_copy,Rect2(1560,45,280,75),ink,Color(1,1,1,0.06))
 map_button.pressed.connect(_travel.bind("map"))
 refs["map_button"] = map_button
 var menu := MapPageUI.button(presentation,"OpenMenu","菜单",Rect2(1330,45,190,75),ink,Color(1,1,1,0.06))
 menu.pressed.connect(_open_menu)
 refs["actions"] = {}
 var actions: Array = data["actions"]
 for i in actions.size():
  var item: Dictionary = actions[i]
  var copy := str(item.get("object_label",""))
  copy = copy+"\n"+str(item["label"]) if copy != "" else str(item["label"])
  var b := MapPageUI.button(presentation,"Action_"+str(item["id"])+str(i),copy,Rect2(100+i*580,860,550,90),ink,Color(1,1,1,0.06),27)
  b.pressed.connect(_action.bind(item))
  refs["actions"][str(item["id"])+str(i)] = b
 map_button.grab_focus.call_deferred()


func _build_object_home() -> void:
 object_home = RegionHomeView.new()
 object_home.home_id = location_id
 object_home.name = "RegionHomeObjects"
 presentation.add_child(object_home)
 refs = object_home.refs
 object_home.action_requested.connect(_action)
 object_home.map_requested.connect(_travel.bind("map"))
 object_home.menu_requested.connect(_open_menu)


func _build_scene_objects() -> void:
 scene_objects = SceneObjectView.new()
 scene_objects.location_id = location_id
 scene_objects.name = "SceneObjects"
 presentation.add_child(scene_objects)
 refs = scene_objects.refs
 scene_objects.action_requested.connect(_action)
 scene_objects.map_requested.connect(_travel.bind("map"))
 scene_objects.menu_requested.connect(_open_menu)
