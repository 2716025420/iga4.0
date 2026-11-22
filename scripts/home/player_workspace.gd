class_name PlayerWorkspace
extends Control

signal close_requested
signal action_requested(action: String, payload: Dictionary)
const INK := Color("#242F42")
const MUTED := Color("#495467")
const BLUE := Color("#526D87")
const CORAL := Color("#BA6A58")
const IVORY := Color("#F7F3E8")
# Central projection screen: keep live content clear of the painted frame.
const RECORDS_BODY_RECT := Rect2(590,156,825,652)
const RECORDS_BODY_SOURCE := Rect2(420,166,875,691)
var panel_kind := "workshop"
var current_tab := "journey"
var selected_card_id := ""
var context: Dictionary = {}
var refs: Dictionary = {}
var snapshot: Dictionary = {}
var card_filter := "all"
var material_quality := "common"
var preset_index := 0
var _drafts: Dictionary = {}
var replacing_card_id := ""
var warehouse_category := "all"
var warehouse_sort := "number"
var warehouse_descending := false
var inventory_query := ""
var selected_item_id := ""
var journey_mode := "memories"
var _scroll_positions: Dictionary = {}
var _revision := 0
var stage: Control
var _bg_art: TextureRect

static func create(kind: String, panel_context: Dictionary = {}) -> PlayerWorkspace:
 if kind not in ["workshop","records"]: return null
 var panel := PlayerWorkspace.new()
 panel.panel_kind = kind
 if panel_context.has("tab"):
  panel.current_tab = str(panel_context["tab"])
 elif kind == "records":
  panel.current_tab = "growth" if int(PlayerJourney.home_snapshot().get("claim_count", 0)) > 0 else "journey"
 else:
  panel.current_tab = "journey"
 if panel.current_tab not in ["journey","growth","classmates","warehouse"]: panel.current_tab = "journey"
 panel.refresh(panel_context)
 return panel

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 resized.connect(_layout)
 _layout()

func _layout() -> void:
 if not is_instance_valid(stage): return
 var edge := Color("#D7E0E4") if panel_kind == "workshop" else Color("#D9BC90")
 var tex: Texture2D = _bg_art.texture if is_instance_valid(_bg_art) else null
 Platform.fit_stage(self,stage,edge,tex)

func refresh(panel_context: Dictionary = {}) -> void:
 var focus_name := ""
 var caret := -1
 if is_inside_tree():
  var focused := get_viewport().gui_get_focus_owner()
  if focused != null and is_ancestor_of(focused):
   focus_name = str(focused.name)
   if focused is LineEdit: caret = focused.caret_column
 for node in find_children("*", "ScrollContainer", true, false):
  _scroll_positions[str(node.name)] = node.scroll_vertical
 context.merge(panel_context,true)
 selected_card_id = str(context.get("selected_card_id",selected_card_id))
 snapshot = HomePanels.content_snapshot(panel_kind,selected_card_id)
 selected_card_id = str(snapshot["selected_card"].get("id",""))
 if replacing_card_id != selected_card_id or _draft().has(replacing_card_id): replacing_card_id = ""
 _revision += 1
 for child in get_children():
  if child.name == "_PlatformEdgeBleed": continue
  remove_child(child)
  child.queue_free()
 refs.clear()
 if not is_inside_tree(): size = Vector2(1920,1080)
 theme = DaylightUI.get_theme().duplicate() as Theme
 theme.set_font("font","Button",theme.default_font)
 theme.set_font("font","Label",theme.default_font)
 mouse_filter = Control.MOUSE_FILTER_STOP
 set_meta("full_scene_overlay",true)
 set_meta("design_size",Vector2(1920,1080))
 stage = Control.new()
 stage.name = "WorkspaceStage"
 stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.size = Vector2(1920,1080)
 add_child(stage)
 _surface(stage,"ScreenBase",Rect2(-210,0,2340,1080),Color("#D7E0E4") if panel_kind == "workshop" else Color("#D9BC90"))
 var room_default := "res://assets/ui/player_experience/" + ("prep_scene_room.png" if panel_kind == "workshop" else "records_room.png")
 var room_wide := "res://assets/ui/player_experience/" + ("prep_scene_room_wide.png" if panel_kind == "workshop" else "records_room_wide.png")
 var use_room_wide := ResourceLoader.exists(room_wide)
 _bg_art = SchoolObjectUI.art(stage,"WorkspaceArt",room_wide if use_room_wide else room_default,Rect2(-210,0,2340,1080) if use_room_wide else Rect2(0,0,1920,1080))
 _bg_art.stretch_mode = TextureRect.STRETCH_SCALE
 var struct_default := "res://assets/ui/player_experience/" + ("prep_scene_structure_neutral_v2.png" if panel_kind == "workshop" else "records_structure.png")
 var struct_wide := "res://assets/ui/player_experience/" + ("prep_scene_structure_wide.png" if panel_kind == "workshop" else "records_structure_wide.png")
 var use_struct_wide := ResourceLoader.exists(struct_wide)
 var struct_art := SchoolObjectUI.art(stage,"WorkspaceStructure",struct_wide if use_struct_wide else struct_default,Rect2(-210,0,2340,1080) if use_struct_wide else Rect2(0,0,1920,1080))
 struct_art.stretch_mode = TextureRect.STRETCH_SCALE
 if panel_kind == "workshop": _render_workshop()
 else: _render_records()
 var close := _plate_button(stage,"CloseButton","×",Rect2(1808,20,88,60),false)
 close.add_theme_font_size_override("font_size",38)
 close.pressed.connect(func(): close_requested.emit())
 refs["close_button"] = close
 var feedback := str(context.get("message",""))
 if feedback != "":
  _surface(stage,"FeedbackPlate",Rect2(90,160,610,37) if panel_kind == "workshop" else Rect2(550,1030,880,36),IVORY)
  _text(stage,"ActionFeedback",feedback,Rect2(102,160,586,37) if panel_kind == "workshop" else Rect2(562,1030,856,36),22,CORAL,true)
 for button in find_children("*","Button",true,false): SchoolObjectUI.borderless(button)
 _polish_chrome()
 if is_inside_tree(): _layout()
 _restore_state.call_deferred(focus_name,caret,_revision)

func _restore_state(focus_name: String, caret: int, revision: int) -> void:
 if revision != _revision or not is_inside_tree(): return
 for node in find_children("*", "ScrollContainer", true, false):
  node.scroll_vertical = int(_scroll_positions.get(str(node.name),0))
 if focus_name != "":
  var target := find_child(focus_name,true,false) as Control
  if target != null and (not target is BaseButton or not target.disabled):
   target.grab_focus()
   if target is LineEdit and caret >= 0: target.caret_column = caret

func _text(parent: Control, node_name: String, copy: String, rect: Rect2, font_size: int = 26, color: Color = INK, centered: bool = false) -> Label:
 var node := SchoolObjectUI.text(parent,node_name,copy,rect,font_size,color,centered)
 node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 node.clip_text = true
 node.set_deferred("size",rect.size)
 node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 return node

func _surface(parent: Control, node_name: String, rect: Rect2, color: Color = IVORY, border: Color = Color("#8293A2")) -> Panel:
 var node := SchoolObjectUI.slab(parent,node_name,rect,color)
 var style := node.get_theme_stylebox("panel") as StyleBoxFlat
 style.set_corner_radius_all(2)
 style.border_color = border
 return node

func _button(parent: Control, node_name: String, copy: String, rect: Rect2, primary: bool = false, selected: bool = false) -> Button:
 var node := Button.new()
 node.name = node_name
 node.text = copy
 node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 node.add_theme_font_size_override("font_size",25)
 for state in ["normal","hover","pressed","hover_pressed","focus","disabled"]:
  var style := StyleBoxFlat.new()
  style.bg_color = CORAL if primary else (BLUE if selected else IVORY)
  if state == "hover": style.bg_color = Color("#CA7770") if primary else (Color("#6888A3") if selected else Color("#E1EBEE"))
  if state in ["pressed","hover_pressed"]: style.bg_color = style.bg_color.darkened(0.14)
  if state == "disabled": style.bg_color = Color("#D5D7D5")
  style.border_color = Color(0.32,0.43,0.55,0.55 if selected else 0.18)
  style.set_border_width_all(1)
  style.set_corner_radius_all(6)
  node.add_theme_stylebox_override(state,style)
 node.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  node.add_theme_color_override(key,Color.WHITE if primary or selected else INK)
 node.add_theme_color_override("font_disabled_color",Color("#647080"))
 parent.add_child(node)
 DaylightUI.place(node,rect.position.x,rect.position.y,rect.size.x,rect.size.y)
 SchoolObjectUI.set_selected(node,selected)
 return node

func _scroll(parent: Control, node_name: String, rect: Rect2) -> Control:
 var scroll := ScrollContainer.new()
 scroll.name = node_name
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 parent.add_child(scroll)
 DaylightUI.place(scroll,rect.position.x,rect.position.y,rect.size.x,rect.size.y)
 var list := Control.new()
 list.name = node_name+"Content"
 scroll.add_child(list)
 refs[node_name] = scroll
 return list

func _art(parent: Control, node_name: String, path: String, rect: Rect2) -> TextureRect:
 var node := SchoolObjectUI.art(parent,node_name,path,rect)
 if ResourceLoader.exists(path): node.texture = SceneSkin.illustration_texture(path)
 return node

func _pill(parent: Control, node_name: String, rect: Rect2, fill: Color, radius: int = 10) -> Panel:
 var node := Panel.new()
 node.name = node_name
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var style := StyleBoxFlat.new()
 style.bg_color = fill
 style.set_border_width_all(0)
 style.set_corner_radius_all(radius)
 node.add_theme_stylebox_override("panel",style)
 parent.add_child(node)
 DaylightUI.place(node,rect.position.x,rect.position.y,rect.size.x,rect.size.y)
 return node

func _polish_chrome() -> void:
 for button in find_children("*","Button",true,false):
  if button.name == "CloseButton":
   for state in ["normal","hover","pressed","hover_pressed","disabled"]:
    var pill := StyleBoxFlat.new()
    pill.bg_color = Color("#FFFDF7") if state == "hover" else (Color("#E5DCC7") if state in ["pressed","hover_pressed"] else Color("#FAF3E3"))
    pill.set_border_width_all(0)
    pill.set_corner_radius_all(12)
    button.add_theme_stylebox_override(state,pill)
   button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
   for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
    button.add_theme_color_override(key,INK)
   button.add_theme_color_override("font_disabled_color",MUTED)
  elif button.has_meta("plate_light_text"):
   button.add_theme_color_override("font_disabled_color",Color("#F7F1E2"))
   if button.name in ["SaveLoadout","ApplyLoadout","TrainButton"]:
    var muted := StyleBoxFlat.new()
    muted.bg_color = Color(0.12,0.16,0.22,0.42)
    muted.set_corner_radius_all(8)
    button.add_theme_stylebox_override("disabled",muted)
  elif button.name == "EquipButton":
   button.add_theme_color_override("font_disabled_color",Color("#5C6473"))
   var muted := StyleBoxFlat.new()
   muted.bg_color = Color(0.32,0.40,0.50,0.10)
   muted.set_corner_radius_all(8)
   button.add_theme_stylebox_override("disabled",muted)
  elif str(button.name).begins_with("Material_"):
   button.add_theme_color_override("font_disabled_color",Color("#68707E"))
  elif str(button.name).begins_with("Claim_") or button.name == "UseDrink":
   button.add_theme_color_override("font_disabled_color",Color("#535D6B"))

func _nav_button(parent: Control, node_name: String, copy: String, rect: Rect2, active: bool = false) -> Button:
 # The art is neutral; live state is a light fill that never draws an outline.
 var button := _plate_button(parent,node_name,copy,rect,true)
 if active:
  var wash := StyleBoxFlat.new()
  wash.bg_color = Color(1.0,0.94,0.78,0.16)
  wash.set_corner_radius_all(6)
  button.add_theme_stylebox_override("normal",wash)
 SchoolObjectUI.set_selected(button,active)
 return button

func _plate_button(parent: Control, node_name: String, copy: String, rect: Rect2, white_text: bool = false) -> Button:
 var button := SchoolObjectUI.hit(parent,node_name,rect,copy,27)
 if white_text:
  button.set_meta("plate_light_text",true)
  for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: button.add_theme_color_override(key,Color.WHITE)
 return button

func _action_art(parent: Control, node_name: String, card_id: String, rect: Rect2) -> TextureRect:
 var regions := {"wrench_smash":Rect2(615,210,330,260),"scrap_shield":Rect2(950,220,255,255),"icy_soda":Rect2(1225,210,315,260),"overclock_torch":Rect2(625,477,322,280),"fake_cheque":Rect2(941,480,290,272),"steel_barricade":Rect2(1232,480,310,280)}
 var art := SchoolObjectUI.art(parent,node_name,"",rect)
 var texture_path := SceneSkin.card_illustration_path(card_id)
 if ResourceLoader.exists(texture_path):
  art.texture = SceneSkin.illustration_texture(texture_path)
 elif regions.has(card_id) and ResourceLoader.exists("res://assets/ui/player_experience/prep_action_atlas.png"):
  var atlas := AtlasTexture.new()
  atlas.atlas = load("res://assets/ui/player_experience/prep_action_atlas.png")
  atlas.region = regions[card_id]
  atlas.filter_clip = true
  art.texture = atlas
 return art

func _card_type_badge(card_type: int) -> Dictionary:
 match card_type:
  0: return {"label":"进攻","color":CORAL}
  2: return {"label":"恢复","color":Color("#54745D")}
  3: return {"label":"支援","color":Color("#98753E")}
  _: return {"label":"防护","color":BLUE}

func _render_workshop() -> void:
 _pill(stage,"TitleBacking",Rect2(80,14,560,140),Color(0.14,0.20,0.27,0.74),12)
 var title := _text(stage,"Title","卡牌整理",Rect2(102,16,516,90),56,Color("#FFF9EC"))
 title.autowrap_mode = TextServer.AUTOWRAP_OFF
 title.clip_text = false
 _text(stage,"Subtitle","整理行动卡，找到顺手的配合节奏。",Rect2(104,108,516,40),24,Color("#F3ECE0"))
 _pill(stage,"ResourcesBacking",Rect2(1495,22,290,54),Color(0.14,0.20,0.27,0.74),12)
 _text(stage,"Resources","练习点  %d" % GameState.scrap_metal,Rect2(1505,22,270,54),26,Color("#FFF9EC"),true)
 var loadouts: Array = GameState.player_profile["loadouts"]
 var saved: Array = loadouts[preset_index]["card_ids"] if preset_index < loadouts.size() else []
 var preset_rects := [Rect2(714,79,140,49),Rect2(875,79,129,49),Rect2(1020,79,140,49)]
 for i in 3:
  var preset := _nav_button(stage,"Preset%d" % i,"方案%d" % (i+1),preset_rects[i],i == preset_index)
  preset.pressed.connect(func(): preset_index = i; replacing_card_id = ""; refresh())
 var save := _plate_button(stage,"SaveLoadout","保存",Rect2(1191,80,142,48),true)
 save.disabled = _draft() == saved or not PlayerJourney.deck_summary(_draft())["ready"]
 save.pressed.connect(func(): action_requested.emit("save_loadout",{"index":preset_index,"card_ids":_draft().duplicate()}))
 var applied := PlayerJourney.active_loadout_index() == preset_index
 var dirty := _draft() != saved
 var apply := _plate_button(stage,"ApplyLoadout","应用中" if applied else "应用",Rect2(1356,80,148,48),true)
 apply.disabled = not PlayerJourney.deck_summary(saved)["ready"] or applied or dirty
 apply.pressed.connect(func(): replacing_card_id = ""; action_requested.emit("apply_loadout",{"index":preset_index}))
 var eligible_companions: Array[String] = []
 for cid in PlayerJourney.COMPANION_ORDER:
  if SaveManager.test_session or GameState.companions.get(cid,{}).get("unlocked",false): eligible_companions.append(cid)
 var current_comp := GameState.get_active_companion_id()
 if current_comp == "" or not eligible_companions.has(current_comp):
  current_comp = eligible_companions[0] if not eligible_companions.is_empty() else ""
 var comp_spec := PlayerJourney.companion_assist_spec(current_comp)
 var comp_label := "协战：%s Lv.%d" % [str(comp_spec.get("name","未解锁")), int(comp_spec.get("tier",1))] if not comp_spec.is_empty() else "协战：未解锁"
 var comp_btn := _plate_button(stage,"CompanionButton",comp_label,Rect2(1524,80,260,48),true)
 comp_btn.add_theme_font_size_override("font_size",22)
 for state in ["normal","hover","pressed","hover_pressed"]:
  var pill := StyleBoxFlat.new()
  pill.bg_color = Color(0.20,0.29,0.40,0.88) if state == "hover" else (Color(0.11,0.16,0.23,0.92) if state in ["pressed","hover_pressed"] else Color(0.14,0.20,0.27,0.78))
  pill.set_corner_radius_all(10)
  comp_btn.add_theme_stylebox_override(state,pill)
 comp_btn.disabled = eligible_companions.is_empty()
 comp_btn.pressed.connect(func():
  if eligible_companions.is_empty(): return
  var idx := eligible_companions.find(current_comp)
  var next_id: String = eligible_companions[(idx + 1) % eligible_companions.size()]
  GameState.set_active_companion_id(next_id)
  var next_spec := PlayerJourney.companion_assist_spec(next_id)
  context["message"] = "协战同伴：%s · %s（%s）" % [str(next_spec.get("name","")),str(next_spec.get("skill","")),str(next_spec.get("summary",""))]
  refresh()
 )
 refs["companion_button"] = comp_btn
 var keys := ["all","attack","guard","heal","support"]
 var names := ["全部","进攻","防护","恢复","支援"]
 var filter_rects := [Rect2(816,207,131,43),Rect2(974,207,119,43),Rect2(1117,207,119,43),Rect2(1261,207,119,43),Rect2(1404,207,119,43)]
 for i in keys.size():
  var filter := _nav_button(stage,"Filter_"+keys[i],names[i],filter_rects[i],card_filter == keys[i])
  filter.pressed.connect(func(): card_filter = keys[i]; _scroll_positions["CardLibraryScroll"] = 0; refresh())
 var list := _scroll(stage,"CardLibraryScroll",Rect2(800,272,760,533))
 var visible_cards: Array = []
 for card in snapshot["cards"]:
  var type: int = int(card["type"])
  if card_filter == "all" or (card_filter == "attack" and type == 0) or (card_filter == "guard" and type in [1,4]) or (card_filter == "heal" and type == 2) or (card_filter == "support" and type == 3): visible_cards.append(card)
 list.custom_minimum_size = Vector2(735,maxi(530,ceili(visible_cards.size()/3.0)*267))
 var cards := {}
 for i in visible_cards.size():
  var data: Dictionary = visible_cards[i]
  var id: String = data["id"]
  var card := _button(list,"Card_"+id,"",Rect2((i%3)*246,(i/3)*267,230,251))
  for state in ["normal","hover","pressed"]:
   var style := card.get_theme_stylebox(state).duplicate() as StyleBoxFlat
   style.bg_color = Color("#FFF9E8") if state == "hover" else (Color("#E3EAF0") if state == "pressed" else (Color("#F1DAB0") if id == selected_card_id else Color("#FBF2DE")))
   style.set_border_width_all(0)
   style.set_corner_radius_all(8)
   card.add_theme_stylebox_override(state,style)
  SchoolObjectUI.set_selected(card,id == selected_card_id)
  var badge: Dictionary = _card_type_badge(int(data["type"]))
  _pill(card,"TypeBadge",Rect2(12,10,62,24),badge["color"],6)
  _text(card,"TypeLabel",badge["label"],Rect2(12,10,62,24),16,Color("#FFFDF6"),true)
  if _draft().has(id):
   _pill(card,"EquippedBadge",Rect2(156,10,62,24),Color("#35485E"),6)
   _text(card,"EquippedLabel","已编",Rect2(156,10,62,24),16,Color("#FFFDF6"),true)
  _action_art(card,"CardArt",id,Rect2(16,38,198,96))
  _text(card,"CardName",data["name"],Rect2(14,138,202,32),24)
  var brief := _text(card,"CardBrief",str(data.get("brief","")),Rect2(14,171,202,42),17,Color("#5A6577"))
  brief.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  _text(card,"CardState","Lv.%d · 冷却 %d" % [data["level"],data["cooldown"]],Rect2(14,215,202,28),18,BLUE)
  card.set_meta("hint_light_text",true)
  card.pressed.connect(func(): replacing_card_id = ""; action_requested.emit("select_card",{"card_id":id}))
  cards[id] = card
 refs["card_buttons"] = cards
 if visible_cards.is_empty(): _text(list,"EmptyCards","这类行动卡还没有解锁。\n继续行程，试试新的搭配。",Rect2(40,135,650,170),28,Color("#FFF5DC"),true)
 _render_card_detail()
 _render_deck()

func _render_card_detail() -> void:
 if selected_card_id == "":
  _text(stage,"EmptyDetail","还没有行动卡。继续今天的行程吧。",Rect2(185,300,460,200),30)
  return
 var card: CardData = GameState.get_card(selected_card_id)
 _text(stage,"SelectedCardName",card.name,Rect2(190,198,465,56),36)
 _action_art(stage,"SelectedCardArt",selected_card_id,Rect2(184,258,462,188))
 var effect := _text(stage,"SelectedCardEffect",card.get_plain_description(),Rect2(190,452,465,84),24)
 effect.vertical_alignment = VERTICAL_ALIGNMENT_TOP
 var preview := _text(stage,"UpgradePreview",card.get_upgrade_preview_text().replace(" | ","   ").replace(" -> "," → "),Rect2(190,540,465,66),23,BLUE)
 preview.vertical_alignment = VERTICAL_ALIGNMENT_TOP
 var quote := PlayerJourney.training_quote(selected_card_id,material_quality)
 for i in 3:
  var quality: String = ["common","fine","rare"][i]
  var cost := PlayerJourney.training_quote(selected_card_id,quality)
  var button := _plate_button(stage,"Material_"+quality,"%s ×%d" % [PlayerJourney.QUALITIES[quality],cost["amount"]],Rect2(194+i*156,616,136,42))
  button.add_theme_font_size_override("font_size",22)
  if material_quality == quality:
   var wash := StyleBoxFlat.new()
   wash.bg_color = Color(0.32,0.43,0.55,0.16)
   wash.set_corner_radius_all(8)
   button.add_theme_stylebox_override("normal",wash)
  button.disabled = card.level >= card.max_level
  SchoolObjectUI.set_selected(button,material_quality == quality)
  _text(stage,"Owned_"+quality,"持有%d" % GameState.exploration_materials[quality],Rect2(188+i*156,664,148,28),20,BLUE,true)
  button.pressed.connect(func(): material_quality = quality; refresh())
 _text(stage,"TrainingReason",quote["reason"],Rect2(190,698,465,62),21,Color("#596577"))
 var train := _plate_button(stage,"TrainButton","练习 · %d点" % quote["points"] if card.level < card.max_level else "最高等级",Rect2(213,809,273,51),true)
 train.disabled = not quote["ok"]
 train.pressed.connect(func(): action_requested.emit("upgrade_card",{"card_id":selected_card_id,"quality":material_quality}))
 var removing := _draft().duplicate()
 removing.erase(selected_card_id)
 var keep_attack: bool = _draft().has(selected_card_id) and PlayerJourney.deck_summary(_draft())["ready"] and not PlayerJourney.deck_summary(removing)["ready"]
 var equip := _plate_button(stage,"EquipButton","保留攻击卡" if keep_attack else ("移出" if _draft().has(selected_card_id) else ("替换" if _draft().size() >= 5 else "编入")),Rect2(526,796,151,46))
 equip.disabled = keep_attack
 SchoolObjectUI.fit_surface(train,-14,3,0.96)
 SchoolObjectUI.fit_surface(equip,-8,2,0.96)
 equip.pressed.connect(_equip_selected)
 refs["train_button"] = train
 refs["equip_button"] = equip

func cancel_pending() -> bool:
 if replacing_card_id == "": return false
 replacing_card_id = ""
 refresh()
 return true

func _equip_selected() -> void:
 if _draft().has(selected_card_id):
  var next := _draft().duplicate()
  next.erase(selected_card_id)
  if PlayerJourney.deck_summary(_draft())["ready"] and not PlayerJourney.deck_summary(next)["ready"]:
   context["message"] = GameState.DECK_RULE_MESSAGE
   refresh()
   return
  _drafts[preset_index] = next
  refresh()
 elif _draft().size() >= 5:
  replacing_card_id = selected_card_id
  refresh()
  var slot := find_child("Slot0",true,false) as Button
  if slot != null: slot.grab_focus.call_deferred()
 else: _put_draft_card(selected_card_id)

func _render_deck() -> void:
 _text(stage,"DeckTitle","出牌顺序\n%d / 5" % _draft().size(),Rect2(115,936,163,90),27,INK,true)
 var deck := PlayerJourney.deck_summary(_draft())
 _text(stage,"DeckSummary",deck["text"].replace("  "," · ")+"\n"+deck["reason"],Rect2(1420,934,380,105),24,INK)
 if replacing_card_id != "":
  _surface(stage,"ReplacePlate",Rect2(790,824,780,66),IVORY)
  _text(stage,"ReplacePrompt","选择下方槽位，替换为「%s」" % GameState.get_card(replacing_card_id).name,Rect2(805,831,580,50),26,CORAL)
  _button(stage,"CancelReplace","取消",Rect2(1390,833,160,45)).pressed.connect(func(): replacing_card_id = ""; refresh())
 for i in 5:
  var id: String = _draft()[i] if i < _draft().size() else ""
  var slot := HomePanels.EquipSlot.new()
  slot.name = "Slot%d" % i
  slot.slot_index = i
  slot.card_id = id
  slot.deck_ids = _draft()
  slot.card_name = GameState.get_card(id).name if id != "" else ""
  slot.drag_enabled = replacing_card_id == ""
  for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
   slot.add_theme_stylebox_override(state,_slot_style(replacing_card_id != "" or state == "focus",state))
  stage.add_child(slot)
  DaylightUI.place(slot,298+i*216,934,200,90)
  _text(slot,"Number",str(i+1).pad_zeros(2),Rect2(2,3,30,24),18,BLUE)
  if i < 4:
   var divider := SchoolObjectUI.rule(slot,"OrderDivider",Rect2(207,20,1,52))
   divider.color = Color(0.32,0.42,0.53,0.20)
  if id != "":
   var icon := _action_art(slot,"Art",id,Rect2(25,17,79,68))
   slot.drag_texture = icon.texture
   _text(slot,"Name",slot.card_name,Rect2(105,17,93,68),23)
  else: _text(slot,"Empty","＋",Rect2(30,15,140,65),37,BLUE,true)
  slot.pressed.connect(func():
   if replacing_card_id != "" and id != "":
    var replacement := replacing_card_id
    replacing_card_id = ""
    _put_draft_card(replacement,i)
   elif id != "": action_requested.emit("select_card",{"card_id":id})
   elif selected_card_id != "" and not _draft().has(selected_card_id): _put_draft_card(selected_card_id,i)
  )
  slot.move_requested.connect(func(from_index: int,to_index: int):
   replacing_card_id = ""
   _move_draft_card(from_index,to_index)
  )

func _slot_style(active: bool, state: String = "normal") -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 # The long paper strip already supplies the surface; retain its grain.
 style.bg_color = Color(0.32,0.43,0.55,0.0)
 if state == "hover": style.bg_color.a = 0.07
 if state in ["pressed","hover_pressed"]: style.bg_color.a = 0.12
 if active: style.bg_color.a = maxf(style.bg_color.a,0.08)
 style.set_border_width_all(0)
 style.set_corner_radius_all(10)
 return style

func _render_records() -> void:
 _pill(stage,"HeaderBacking",Rect2(68,28,376,260),Color(0.97,0.94,0.88,0.92),12)
 _text(stage,"Title","放映档案室",Rect2(84,38,344,92),52,INK)
 _text(stage,"IndexCaption","胶片留住回忆，\n印章见证每一次成长。",Rect2(84,132,344,86),23,BLUE,true)
 var unclaimed_cnt := 0
 for item in PlayerJourney.milestones():
  if bool(item["ready"]) and not bool(item["claimed"]): unclaimed_cnt += 1
 var growth_label := ("委托与成就·%d" % unclaimed_cnt) if unclaimed_cnt > 0 else "委托与成就"
 var keys := ["growth","journey","classmates","warehouse"]
 var names := [growth_label,"故事胶片","同学拍立得","社团收纳"]
 var symbols := ["★","◉","◇","□"]
 for i in keys.size():
  var tab := SchoolObjectUI.hit(stage,"Tab_"+keys[i],Rect2(72,300+i*110,360,100),"",31)
  tab.set_meta("plate_light_text",true)
  _text(tab,"Symbol",symbols[i],Rect2(18,15,65,70),43,Color.WHITE,true)
  _text(tab,"Title",names[i],Rect2(94,16,252,68),30 if names[i].length() <= 6 else 26,Color.WHITE)
  if current_tab == keys[i]:
   var wash := StyleBoxFlat.new()
   wash.bg_color = Color(1.0,0.96,0.84,0.20)
   wash.set_corner_radius_all(8)
   tab.add_theme_stylebox_override("normal",wash)
  SchoolObjectUI.set_selected(tab,current_tab == keys[i])
  tab.pressed.connect(func(): current_tab = keys[i]; context["message"] = ""; refresh())
 _text(stage,"ArchiveTime",GameState.get_formatted_time(),Rect2(84,224,344,42),22,INK,true)
 if not ResourceLoader.exists("res://assets/ui/player_experience/records_structure.png"):
  _surface(stage,"ArchiveContent",Rect2(530,145,910,740),IVORY)
  _surface(stage,"HistoryDrawer",Rect2(1500,145,380,740),IVORY)
 var body := Control.new()
 body.name = "RecordsContent"
 body.mouse_filter = Control.MOUSE_FILTER_PASS
 body.clip_contents = true
 body.position = RECORDS_BODY_RECT.position
 body.size = RECORDS_BODY_SOURCE.size
 var factor := minf(RECORDS_BODY_RECT.size.x / body.size.x,RECORDS_BODY_RECT.size.y / body.size.y)
 body.scale = Vector2.ONE * factor
 stage.add_child(body)
 var before := stage.get_children()
 match current_tab:
  "journey": _render_journey()
  "growth": _render_growth()
  "classmates": _render_classmates()
  "warehouse": _render_warehouse()
 # Reparent the whole page so text, fields, scrolling and hit areas share one transform.
 for child in stage.get_children():
  if not before.has(child) and child is Control:
   child.reparent(body,false)
   child.position -= RECORDS_BODY_SOURCE.position
 _render_history()
 var complete: bool = snapshot["completed"]
 var qual_done: bool = bool(GameState.story_flags.get("arete_qualifier_completed", false))
 var bottom_objective := "行程已完成 · 回看熟悉的片段" if qual_done else ("已唤醒白羊座母卡 · 前往体育馆参加代表选拔赛" if complete else str(snapshot["current_title"]))
 _text(stage,"CurrentObjective",bottom_objective,Rect2(565,946,620,69),26,Color("#FCF6E8"))
 var zodiac_btn := SchoolObjectUI.hit(stage,"OpenZodiac",Rect2(1205,950,225,74),"✦ 星座图鉴",27)
 zodiac_btn.set_meta("plate_light_text",true)
 for state in ["normal","hover","pressed","hover_pressed"]:
  var wash := StyleBoxFlat.new()
  wash.bg_color = Color(0.18,0.25,0.34,0.40 if state == "normal" else 0.58)
  wash.set_corner_radius_all(10)
  zodiac_btn.add_theme_stylebox_override(state,wash)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: zodiac_btn.add_theme_color_override(state,Color.WHITE)
 zodiac_btn.pressed.connect(func(): action_requested.emit("open_zodiac",{}))
 var next_label := "整理卡组" if qual_done else ("前往校园地图" if complete else "继续行程")
 var next_action := "open_workshop" if qual_done else ("open_quest" if complete else "start_chapter")
 var next := SchoolObjectUI.hit(stage,"ContinueJourney",Rect2(1460,946,354,83),next_label,33)
 next.set_meta("plate_light_text",true)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: next.add_theme_color_override(state,Color.WHITE)
 next.pressed.connect(func(): action_requested.emit(next_action,{}))

func _render_journey() -> void:
 _text(stage,"ChapterTitle","故事胶片与阿瑞忒纪要",Rect2(420,170,790,55),34)
 _text(stage,"ChapterProgress","已走过 %d / %d 段主线 · %s" % [snapshot["completed_count"],snapshot["total_steps"],"第一章完成" if snapshot["completed"] else "继续写下校园经历"],Rect2(420,226,790,42),24,MUTED)
 _button(stage,"MemoryTab","剧情胶片",Rect2(420,285,205,48),false,journey_mode == "memories").pressed.connect(func(): journey_mode = "memories"; refresh())
 _button(stage,"ClueTab","调查线索",Rect2(640,285,205,48),false,journey_mode == "clues").pressed.connect(func(): journey_mode = "clues"; refresh())
 _button(stage,"NoteTab","风物纪要",Rect2(860,285,205,48),false,journey_mode == "notes").pressed.connect(func(): journey_mode = "notes"; refresh())
 if journey_mode == "clues":
  _text(stage,"InvestigationRecord",snapshot["record_anomaly"],Rect2(430,370,765,330),28)
  return
 if journey_mode == "notes":
  var note_list := _scroll(stage,"NotesScroll",Rect2(420,357,875,500))
  var unlocked_notes: Array = GameState.player_profile.get("reading_notes", [])
  note_list.custom_minimum_size = Vector2(850, maxi(480, CampusPlaces.LIBRARY_NOTES.size() * 145))
  for i in CampusPlaces.LIBRARY_NOTES.size():
   var note: Dictionary = CampusPlaces.LIBRARY_NOTES[i]
   var unlocked: bool = unlocked_notes.has(note["id"]) or SaveManager.test_session
   var ny := i * 145
   _surface(note_list,"NoteCard%d" % i,Rect2(0,ny,838,132),Color("#F7F1E2") if unlocked else Color("#ECE8DC"),Color("#CBB89D"))
   _text(note_list,"NoteTitle%d" % i,("【已收录】" + str(note["title"])) if unlocked else ("【%02d · 未收录】前往图书馆研习或翻阅书页解锁" % (i + 1)),Rect2(18,ny+10,802,38),24,CORAL if unlocked else MUTED)
   _text(note_list,"NoteBody%d" % i,str(note["body"]) if unlocked else "阿瑞忒图书馆藏有许多学园史话与卡片手记，完成图书馆牌理研习即可逐步收录。",Rect2(18,ny+52,802,72),20,INK if unlocked else MUTED)
  return
 var list := _scroll(stage,"JourneyScroll",Rect2(420,357,875,500))
 var entries := HomePanels.known_records()
 list.custom_minimum_size = Vector2(850,maxi(480,entries.size()*171))
 var memories := {}
 for entry in PlayerJourney.memories():
  if not memories.has(entry["node"]): memories[entry["node"]] = entry["dialogue_id"]
 refs["memory_buttons"] = {}
 for i in entries.size():
  var entry: Dictionary = entries[i]
  var y := i*171
  SchoolObjectUI.rule(list,"MemorySplice%d" % i,Rect2(0,y+158,848,1))
  _surface(list,"FilmWindow%d" % i,Rect2(0,y+6,282,142),Color("#A48B74"),Color("#B69B80"))
  SchoolObjectUI.art(list,"Scene%d" % i,PhaseTwoContent.resolve_background_path(str(entry["scene"]), false),Rect2(16,y+12,250,130))
  for hole in 6:
   _surface(list,"PerforationL%d_%d" % [i,hole],Rect2(4,y+16+hole*21,7,11),IVORY,IVORY)
   _surface(list,"PerforationR%d_%d" % [i,hole],Rect2(271,y+16+hole*21,7,11),IVORY,IVORY)
  _text(list,"MemoryTitle%d" % i,entry["title"],Rect2(302,y+10,530,40),27)
  _text(list,"MemoryCopy%d" % i,entry["copy"],Rect2(302,y+52,530,62),23,MUTED)
  if memories.has(entry["node"]):
   var id: String = memories[entry["node"]]
   var replay := _button(list,"Replay_"+id,"回看",Rect2(693,y+114,135,32))
   replay.add_theme_font_size_override("font_size",21)
   replay.pressed.connect(func(): GameState.archive_return_tab = "journey"; action_requested.emit("replay_memory",{"dialogue_id":id}))
   refs["memory_buttons"][id] = replay
  else: _text(list,"BattleSummary%d" % i,"已完成 · 遭遇记录",Rect2(220,y+114,520,32),21,BLUE)
 if entries.is_empty(): _text(list,"EmptyMemories","今天的故事还没开始。\n先一起走到学校吧。",Rect2(20,80,730,180),30,MUTED,true)

func _render_growth() -> void:
 var goals := PlayerJourney.milestones()
 var stamped := 0
 for g in goals:
  if bool(g["claimed"]): stamped += 1
 _text(stage,"GrowthTitle","社团委托与成就印章",Rect2(420,170,790,56),34)
 _text(stage,"GrowthHint","达成目标后加盖社团印章 · 已收录 %d / %d 枚巡回印章" % [stamped, goals.size()],Rect2(420,234,790,42),23,MUTED)
 var list := _scroll(stage,"GrowthScroll",Rect2(420,295,845,560))
 list.custom_minimum_size = Vector2(822,goals.size()*167)
 refs["milestone_buttons"] = {}
 for i in goals.size():
  var goal: Dictionary = goals[i]
  var y := i*167
  var claimed: bool = bool(goal["claimed"])
  var ready: bool = bool(goal["ready"])
  var goal_card := _surface(list,"Goal_"+goal["id"],Rect2(0,y,815,151),Color("#F0E4CE") if claimed else Color("#F4EBDC"),CORAL if (ready and not claimed) else Color("#D6C6AB"))
  DynamicUI.apply_nine_slice_panel(goal_card,DynamicUI.THEME_PAPER_CARD,Vector4(44,36,32,32),Color(0.95,0.92,0.86,0.98) if claimed else (Color(1.0,0.96,0.92,1.0) if (ready and not claimed) else Color(1.0,0.99,0.97,1.0)))
  var copy_w := 502 if claimed else 565
  _text(list,"Title",goal["title"],Rect2(18,y+8,copy_w,40),28)
  _text(list,"Condition",goal["condition"]+" · "+goal["progress"],Rect2(18,y+50,copy_w,46),21,MUTED)
  _text(list,"Reward","奖励："+goal["reward"],Rect2(18,y+102,copy_w,38),22,CORAL)
  if claimed:
   var seal := _art(list,"SealBadge_"+goal["id"],"res://assets/ui_core/v14_ui/buttons/ui_seal_claimed_badge.png",Rect2(516,y+36,76,76))
   seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
   seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   var stamp_pill := _pill(list,"StampPill_"+goal["id"],Rect2(604,y+14,192,30),Color("#C85242"),6)
   stamp_pill.add_theme_stylebox_override("panel",DynamicUI.make_paper_tag(Color("#C85242"),Color("#9E3B2E"),6,8.0,2.0))
   _text(list,"StampCopy_"+goal["id"],"社团已盖章",Rect2(604,y+14,192,30),17,Color.WHITE,true)
  var btn_y := y+54 if claimed else y+44
  var btn_h := 56 if claimed else 65
  var claim := _button(list,"Claim_"+goal["id"],"已领奖" if claimed else ("盖章领奖" if ready else "未达成"),Rect2(604,btn_y,192,btn_h),ready and not claimed)
  var stamp_norm := DynamicUI.nine_slice_box(DynamicUI.THEME_PAPER_CARD,Vector4(44,36,32,32),Vector4(10,4,10,4),Color(0.84,0.40,0.33,1.0) if (ready and not claimed) else Color(0.90,0.87,0.82,0.86),Vector4(-1,-1,-1,-1),btn_h)
  var stamp_dis := DynamicUI.nine_slice_box(DynamicUI.THEME_PAPER_CARD,Vector4(44,36,32,32),Vector4(10,4,10,4),Color(0.88,0.85,0.80,0.82),Vector4(-1,-1,-1,-1),btn_h)
  if stamp_norm != null:
   var stamp_hover := DynamicUI.nine_slice_box(DynamicUI.THEME_PAPER_CARD,Vector4(44,36,32,32),Vector4(10,4,10,4),Color(0.90,0.45,0.37,1.0),Vector4(-1,-1,-1,-1),btn_h)
   var stamp_press := DynamicUI.nine_slice_box(DynamicUI.THEME_PAPER_CARD,Vector4(44,36,32,32),Vector4(10,4,10,4),Color(0.74,0.33,0.27,1.0),Vector4(-1,-1,-1,-1),btn_h)
   claim.add_theme_stylebox_override("normal",stamp_norm)
   claim.add_theme_stylebox_override("hover",stamp_hover if stamp_hover != null else stamp_norm)
   claim.add_theme_stylebox_override("pressed",stamp_press if stamp_press != null else stamp_norm)
   claim.add_theme_stylebox_override("hover_pressed",stamp_press if stamp_press != null else stamp_norm)
   claim.add_theme_stylebox_override("disabled",stamp_dis if stamp_dis != null else stamp_norm)
  claim.disabled = claimed or not ready
  claim.pressed.connect(func(): action_requested.emit("claim_milestone",{"id":goal["id"]}))
  refs["milestone_buttons"][goal["id"]] = claim

func _render_classmates() -> void:
 _text(stage,"ClassmatesTitle","同学拍立得与协战档案",Rect2(420,170,790,64),34)
 var campus_talks: Dictionary = CampusLife.snapshot().get("npc_talks", {})
 var activities: Dictionary = GameState.player_profile.get("activities", {})
 var met: Array = []
 for actor in snapshot["cast"]:
  var aid := str(actor["id"])
  var unlocked := false
  if aid == "ye_zhou": unlocked = true
  elif aid == "huang_qiufeng": unlocked = GameState.visited_node_ids.has("n0") or SaveManager.test_session
  elif aid == "lin_zhi_xia": unlocked = int(campus_talks.get("lin_zhi_xia", 0)) > 0 or int(activities.get("study_count", 0)) > 0 or SaveManager.test_session
  elif aid == "tang_xiao_man": unlocked = int(campus_talks.get("tang_xiao_man", 0)) > 0 or int(activities.get("work_count", 0)) > 0 or SaveManager.test_session
  else: unlocked = GameState.companions.get(aid,{}).get("unlocked",false) or SaveManager.test_session
  if unlocked: met.append(actor)
 var list := _scroll(stage,"ClassmatesScroll",Rect2(420,256,845,595))
 var y := 0.0
 for i in met.size():
  var actor: Dictionary = met[i]
  var aid := str(actor["id"])
  var bio_copy := str(PhaseTwoContent.ACTORS[aid]["bio"])
  if PlayerJourney.COMPANION_ASSISTS.has(aid):
   var assist := PlayerJourney.companion_assist_spec(aid)
   var favor := int(GameState.companions.get(aid, {}).get("favor", 0))
   bio_copy += "\n熟悉度 %d · %s" % [favor, str(assist.get("summary", ""))]
  var bio := _text(list,"Bio%d" % i,bio_copy,Rect2(183,0,610,96),22,MUTED)
  bio.vertical_alignment = VERTICAL_ALIGNMENT_TOP
  # Measure at the final wrapped width; the card and scroll extent grow with the copy.
  var bio_height := maxf(96.0,bio.get_minimum_size().y)
  var row_height := maxf(212.0,105.0+bio_height+26.0)
  var plate := _surface(list,"Classmate_"+aid,Rect2(0,y,815,row_height),Color("#F4EBDC"),Color("#D6C6AB"))
  plate.clip_contents = true
  list.move_child(plate,bio.get_index())
  bio.position = Vector2(183,y+105)
  bio.size = Vector2(610,bio_height)
  SchoolObjectUI.art(list,"Portrait%d" % i,actor["portrait"],Rect2(16,y+12,145,180))
  _text(list,"Name%d" % i,actor["name"],Rect2(183,y+12,610,48),31)
  _text(list,"Subtitle%d" % i,actor["subtitle"],Rect2(183,y+62,610,40),24,BLUE)
  y += row_height+18.0
 list.custom_minimum_size = Vector2(822,maxf(595.0,y))

func _inventory_field(control: Control, option: bool = false) -> void:
 for state in (["normal","hover","pressed","hover_pressed","disabled"] if option else ["normal","read_only"]):
  var style := StyleBoxFlat.new()
  style.bg_color = Color(0.32,0.48,0.56,0.08) if state == "hover" else Color.TRANSPARENT
  style.border_color = Color("#647A8F") if state in ["hover","pressed","hover_pressed"] else Color("#A89579")
  style.set_border_width_all(0)
  style.content_margin_left = 9
  style.content_margin_right = 9
  style.content_margin_top = 4
  style.content_margin_bottom = 4
  control.add_theme_stylebox_override(state,style)
 var focus := StyleBoxFlat.new()
 focus.bg_color = Color.TRANSPARENT
 focus.border_color = Color("#5D82A2")
 focus.set_border_width_all(0)
 control.add_theme_stylebox_override("focus",focus)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
  control.add_theme_color_override(state,INK)
 if option:
  var popup: PopupMenu = control.get_popup()
  var plate := StyleBoxFlat.new()
  plate.bg_color = IVORY
  plate.border_color = Color("#A89579")
  plate.set_border_width_all(1)
  plate.set_content_margin_all(8)
  popup.add_theme_stylebox_override("panel",plate)
  var selection := StyleBoxFlat.new()
  selection.bg_color = Color("#D8E4E8")
  popup.add_theme_stylebox_override("hover",selection)
  popup.add_theme_color_override("font_color",INK)
  popup.add_theme_color_override("font_hover_color",INK)
  popup.add_theme_font_size_override("font_size",23)

func _render_warehouse() -> void:
 _text(stage,"WarehouseTitle","物品收纳",Rect2(420,166,400,58),36)
 var keys := ["all","material","quest","item"]
 for i in keys.size():
  var filter := _button(stage,"InventoryFilter_"+keys[i],ItemCatalog.CATEGORIES[keys[i]],Rect2(420+i*155,239,143,46),false,warehouse_category == keys[i])
  filter.pressed.connect(func(): warehouse_category = keys[i]; _scroll_positions["InventoryScroll"] = 0; refresh())
 # Paint borders on independent frames, outside the native field clipping.
 var search_frame := _surface(stage,"InventorySearchFrame",Rect2(420,303,320,50),Color("#FAF6EC"),Color("#8F7C61"))
 (search_frame.get_theme_stylebox("panel") as StyleBoxFlat).set_corner_radius_all(6)
 var search := LineEdit.new()
 search.name = "InventorySearch"
 search.placeholder_text = "搜索名称或拼音"
 search.text = inventory_query
 search.add_theme_font_size_override("font_size",24)
 _inventory_field(search)
 search.add_theme_color_override("font_color",INK)
 search.add_theme_color_override("font_placeholder_color",MUTED)
 search.add_theme_color_override("caret_color",INK)
 stage.add_child(search)
 DaylightUI.place(search,422,305,316,46)
 search.focus_entered.connect(func():
  var style := search_frame.get_theme_stylebox("panel") as StyleBoxFlat
  style.bg_color = Color("#E8EFF0")
  style.border_color = BLUE
 )
 search.focus_exited.connect(func():
  var style := search_frame.get_theme_stylebox("panel") as StyleBoxFlat
  style.bg_color = Color("#FAF6EC")
  style.border_color = Color("#8F7C61")
 )
 search.text_changed.connect(func(value: String): inventory_query = value; _scroll_positions["InventoryScroll"] = 0; refresh())
 var sort_frame := _surface(stage,"InventorySortFrame",Rect2(755,303,270,50),Color("#FAF6EC"),Color("#8F7C61"))
 (sort_frame.get_theme_stylebox("panel") as StyleBoxFlat).set_corner_radius_all(6)
 var sort := OptionButton.new()
 sort.name = "InventorySort"
 for name_copy in ["物品序号","拼音首字母","获得时间"]: sort.add_item(name_copy)
 sort.selected = ["number","pinyin","acquired"].find(warehouse_sort)
 sort.add_theme_font_size_override("font_size",23)
 _inventory_field(sort,true)
 sort.add_theme_color_override("font_color",INK)
 stage.add_child(sort)
 DaylightUI.place(sort,757,305,266,46)
 sort.focus_entered.connect(func():
  var style := sort_frame.get_theme_stylebox("panel") as StyleBoxFlat
  style.bg_color = Color("#E8EFF0")
  style.border_color = BLUE
 )
 sort.focus_exited.connect(func():
  var style := sort_frame.get_theme_stylebox("panel") as StyleBoxFlat
  style.bg_color = Color("#FAF6EC")
  style.border_color = Color("#8F7C61")
 )
 sort.item_selected.connect(func(index: int): warehouse_sort = ["number","pinyin","acquired"][index]; warehouse_descending = warehouse_sort == "acquired"; refresh())
 _button(stage,"InventorySortDirection","降序" if warehouse_descending else "升序",Rect2(1043,303,158,50)).pressed.connect(func(): warehouse_descending = not warehouse_descending; refresh())
 var items: Array = []
 for item in GameState.get_inventory_snapshot()["items"]:
  if warehouse_category != "all" and warehouse_category != item["category"]: continue
  var query := inventory_query.strip_edges().to_lower()
  if query != "" and not (str(item["name"]).to_lower().contains(query) or str(item["pinyin"]).contains(query)): continue
  items.append(item)
 items.sort_custom(_compare_inventory_items)
 var selected: Dictionary = {}
 for item in items:
  if item["id"] == selected_item_id: selected = item
 if selected.is_empty() and not items.is_empty(): selected = items[0]
 selected_item_id = str(selected.get("id",""))
 var list := _scroll(stage,"InventoryScroll",Rect2(420,369,795,244))
 list.custom_minimum_size = Vector2(772,maxi(240,items.size()*88))
 refs["inventory_order"] = []
 refs["inventory_item_buttons"] = {}
 for i in items.size():
  var item: Dictionary = items[i]
  var id: String = item["id"]
  refs["inventory_order"].append(id)
  var button := _button(list,"InventoryItem_"+id,"",Rect2(0,i*88,770,78),false,id == selected_item_id)
  _art(button,"Icon",str(item["icon"]),Rect2(12,6,65,65))
  var color := Color.WHITE if id == selected_item_id else INK
  _text(button,"Name","%03d  %s" % [item["number"],item["name"]],Rect2(93,6,465,63),25,color)
  _text(button,"Quantity","×%d" % item["quantity"],Rect2(570,6,180,63),27,color,true)
  button.pressed.connect(func(): selected_item_id = id; refresh())
  refs["inventory_item_buttons"][id] = button
 if items.is_empty(): _text(list,"EmptyInventory","没有符合条件的物品。",Rect2(20,60,730,100),28,MUTED,true)
 _surface(stage,"InventoryDetail",Rect2(420,631,790,143),Color("#EAE0CA"),Color("#D6C6AB"))
 var acquisition: Dictionary = selected.get("acquired",{})
 var date_copy := "此前已持有 · 时间未记录" if acquisition.is_empty() else "最近获得："+DayCycleService.date_label(int(acquisition["day"]),int(acquisition["hour"]))
 _text(stage,"AcquiredTime",date_copy if not selected.is_empty() else "物品会妥善保存在这里",Rect2(438,635,754,35),21,BLUE)
 var item_description := RichTextLabel.new()
 item_description.name = "SelectedItemDescription"
 item_description.text = str(selected.get("description","训练中收集的材料和物品会放进这里。"))
 item_description.fit_content = false
 item_description.scroll_active = true
 item_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 item_description.add_theme_font_size_override("normal_font_size",24)
 item_description.add_theme_color_override("default_color",INK)
 item_description.mouse_filter = Control.MOUSE_FILTER_PASS
 stage.add_child(item_description)
 DaylightUI.place(item_description,438,675,754,91)
 var use := _button(stage,"UseDrink","饮品补给 · 恢复35",Rect2(420,782,366,58))
 use.disabled = not PlayerJourney.safe_at_home() or GameState.energy_drinks < 1 or GameState.player_current_hp >= GameState.player_max_hp
 use.pressed.connect(func(): action_requested.emit("use_drink",{}))
 refs["inventory_selected"] = selected

func _compare_inventory_items(a: Dictionary,b: Dictionary) -> bool:
 var comparison := 0
 match warehouse_sort:
  "pinyin": comparison = str(a["pinyin"]).naturalnocasecmp_to(str(b["pinyin"]))
  "acquired":
   var a_order := int(a.get("acquired",{}).get("order",0))
   var b_order := int(b.get("acquired",{}).get("order",0))
   if (a_order == 0) != (b_order == 0): return a_order != 0
   comparison = signi(a_order-b_order)
  _: comparison = signi(int(a["number"])-int(b["number"]))
 if comparison == 0: return int(a["number"]) < int(b["number"])
 return comparison > 0 if warehouse_descending else comparison < 0

func _render_history() -> void:
 _text(stage,"HistoryTitle","最近训练",Rect2(1548,160,284,60),34)
 _text(stage,"HistoryHint","模拟路线与训练收获",Rect2(1548,227,284,68),23,MUTED)
 var entries: Array = GameState.player_profile["exploration_log"]
 var list := _scroll(stage,"HistoryScroll",Rect2(1548,315,294,566))
 list.custom_minimum_size = Vector2(288,maxi(545,entries.size()*272))
 for i in entries.size():
  var entry: Dictionary = entries[i]
  var y := i*272
  var route_name := "校园路线"
  for dungeon in snapshot["dungeons"]:
   if dungeon["id"] == entry["dungeon_id"]: route_name = str(dungeon["title"])
  SchoolObjectUI.rule(list,"Splice%d" % i,Rect2(0,y,286,1))
  _text(list,"Route",route_name,Rect2(8,y+10,272,43),27)
  _text(list,"Status","%s · %d处" % [{"completed":"已完成","defeat":"未能走完","retreated":"主动撤离"}[entry["status"]],entry["visited"]],Rect2(8,y+55,272,48),24,BLUE)
  var earned: Dictionary = entry["earned"]
  var materials: Dictionary = earned["materials"]
  _text(list,"Gains","收获 %d练习点\n普%d · 精%d · 稀%d\n消费 %d点\n%s" % [earned["scrap_metal"],materials["common"],materials["fine"],materials["rare"],entry["spent_points"],DayCycleService.date_label(int(entry["day"]),int(entry["hour"]))],Rect2(8,y+108,272,145),23,MUTED)
 if entries.is_empty(): _text(list,"EmptyHistory","还没有训练记录。\n\n走完、撤离或失败后，\n经历会留在这里。",Rect2(8,75,272,280),26,MUTED,true)

func _draft() -> Array:
 if not _drafts.has(preset_index):
  var entries: Array = GameState.player_profile["loadouts"]
  _drafts[preset_index] = entries[preset_index]["card_ids"].duplicate() if preset_index < entries.size() else []
 return _drafts[preset_index]

func _put_draft_card(card_id: String, index: int = -1) -> void:
 if not GameState.unlocked_card_ids.has(card_id) or _draft().has(card_id): return
 var ids := _draft().duplicate()
 if index >= 0 and index < ids.size(): ids[index] = card_id
 elif ids.size() < 5: ids.append(card_id)
 if PlayerJourney.deck_summary(_draft())["ready"] and not PlayerJourney.deck_summary(ids)["ready"]:
  context["message"] = GameState.DECK_RULE_MESSAGE
  refresh()
  return
 _drafts[preset_index] = ids
 refresh()

func _move_draft_card(from_index: int, to_index: int) -> void:
 var ids := _draft()
 if from_index < 0 or from_index >= ids.size() or to_index < 0 or to_index >= 5: return
 var moved: String = ids[from_index]
 if to_index < ids.size():
  ids[from_index] = ids[to_index]
  ids[to_index] = moved
 else:
  ids.remove_at(from_index)
  ids.append(moved)
 refresh()
