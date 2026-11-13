class_name RewardCardPopup
extends CanvasLayer

const DESIGN := Vector2(1920,1080)
var pending: Dictionary = {}
var displayed: Dictionary = {}
var backdrop: Control
var presentation: Control
var entries: GridContainer
var confirm: Button
var _previous_focus: Control
var _was_paused := false
var _scheduled := false

func _ready() -> void:
 name = "RewardCards"
 layer = 110
 process_mode = Node.PROCESS_MODE_ALWAYS
 backdrop = Control.new()
 backdrop.name = "RewardBackdrop"
 backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 backdrop.theme = DaylightUI.get_theme()
 add_child(backdrop)
 var shade := ColorRect.new()
 shade.color = Color(0.08,0.14,0.22,0.65)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 backdrop.add_child(shade)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 presentation = Control.new()
 presentation.name = "RewardPresentation"
 presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
 presentation.size = DESIGN
 backdrop.add_child(presentation)
 var panel := SchoolObjectUI.slab(presentation,"RewardPaper",Rect2(365,175,1190,730),Color("#F4EFE3"))
 panel.add_theme_stylebox_override("panel",CombatSkin.paper(Vector4(24,24,24,24)))
 var heading := SchoolObjectUI.text(presentation,"Heading","获得物品",Rect2(425,205,1000,85),46,Color("#303B45"))
 heading.add_theme_font_override("font",load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
 SchoolObjectUI.text(presentation,"Hint","这一份收获，已经好好收下。",Rect2(430,292,1000,42),25,DaylightUI.MUTED)
 var scroll := ScrollContainer.new()
 scroll.name = "RewardScroll"
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 presentation.add_child(scroll)
 DaylightUI.place(scroll,425,365,1070,370)
 entries = GridContainer.new()
 entries.name = "ItemCards"
 entries.columns = 2
 entries.add_theme_constant_override("h_separation",22)
 entries.add_theme_constant_override("v_separation",18)
 scroll.add_child(entries)
 confirm = SchoolObjectUI.hit(presentation,"ConfirmRewards",Rect2(775,790,370,70),"收下",32)
 CombatSkin.button(confirm,true)
 confirm.pressed.connect(dismiss)
 backdrop.resized.connect(_layout)
 backdrop.hide()
 GameState.rewards_received.connect(enqueue)
 SceneManager.scene_transition_completed.connect(_schedule)
 _layout()

func _layout() -> void:
 var extent := get_viewport().get_visible_rect().size
 var factor := minf(extent.x/DESIGN.x,extent.y/DESIGN.y)
 presentation.scale = Vector2.ONE*factor
 presentation.position = (extent-DESIGN*factor)/2.0

func enqueue(rewards: Dictionary) -> void:
 for id in rewards: pending[id] = int(pending.get(id,0))+int(rewards[id])
 _schedule()

func _schedule() -> void:
 if _scheduled or pending.is_empty(): return
 _scheduled = true
 _present_pending.call_deferred()

func _present_pending() -> void:
 _scheduled = false
 if backdrop.visible or pending.is_empty() or SceneManager.is_transitioning: return
 displayed = pending.duplicate()
 pending.clear()
 for child in entries.get_children():
  entries.remove_child(child)
  child.queue_free()
 var columns := 1 if displayed.size() == 1 else 2
 entries.columns = columns
 var card_width := 640.0 if columns == 1 else 510.0
 var rows := mini(2,ceili(float(displayed.size())/columns))
 var list_height := rows*164.0+(rows-1)*18.0
 var paper_width := 760.0 if columns == 1 else 1190.0
 var paper_height := list_height+365.0
 var left := (DESIGN.x-paper_width)/2.0
 var top := (DESIGN.y-paper_height)/2.0
 DaylightUI.place(presentation.get_node("RewardPaper"),left,top,paper_width,paper_height)
 DaylightUI.place(presentation.get_node("Heading"),left+60,top+30,paper_width-120,85)
 DaylightUI.place(presentation.get_node("Hint"),left+65,top+117,paper_width-130,42)
 var scroll := presentation.get_node("RewardScroll") as ScrollContainer
 DaylightUI.place(scroll,left+60,top+190,paper_width-120,list_height)
 scroll.scroll_vertical = 0
 DaylightUI.place(confirm,(DESIGN.x-370)/2.0,top+paper_height-115,370,70)
 for id in displayed:
  var data := _definition(str(id))
  var card := SchoolObjectUI.slab(entries,"Reward_"+str(id).replace(":","_"),Rect2(0,0,card_width,164),Color("#FAF4E6"))
  card.custom_minimum_size = Vector2(card_width,164)
  var style := card.get_theme_stylebox("panel") as StyleBoxFlat
  style.border_color = Color("#D8CBB4")
  style.set_border_width_all(1)
  style.set_corner_radius_all(10)
  SchoolObjectUI.art(card,"Icon",str(data.get("icon","")),Rect2(18,30,100,100))
  var name_lbl := SchoolObjectUI.text(card,"Name",str(data.get("name",id)),Rect2(138,18,345,45),28,Color("#303B45"))
  name_lbl.add_theme_font_override("font",load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
  SchoolObjectUI.text(card,"Quantity","× %d" % int(displayed[id]),Rect2(138,64,345,40),27,Color("#BA6A58"))
  var description := SchoolObjectUI.text(card,"Description",str(data.get("description","")),Rect2(138,104,card_width-165,52),20,DaylightUI.MUTED)
  description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  description.max_lines_visible = 2
  description.clip_text = true
  description.set_deferred("size",Vector2(card_width-165,52))
 _previous_focus = get_viewport().gui_get_focus_owner()
 _was_paused = get_tree().paused
 get_tree().paused = true
 backdrop.show()
 _layout()
 var duration := SaveManager.motion_duration(0.16)
 if duration > 0.0:
  presentation.pivot_offset = DESIGN * 0.5
  presentation.modulate.a = 0.0
  presentation.scale = Vector2(0.97, 0.97)
  var tween := create_tween().set_parallel(true)
  tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
  tween.tween_property(presentation,"modulate:a",1.0,duration).set_trans(Tween.TRANS_CUBIC)
  tween.tween_property(presentation,"scale",Vector2.ONE,duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 else:
  presentation.modulate.a = 1.0
  presentation.scale = Vector2.ONE
 confirm.grab_focus()

func _definition(id: String) -> Dictionary:
 if id == "practice_points": return {"name":"练习点","description":"用来练习行动卡。","icon":"res://assets/ui_core/icons/economy/icon_practice_points.png"}
 if id == "allowance": return {"name":"零用钱","description":"留给接下来的校园生活。","icon":"res://assets/ui_core/icons/economy/icon_allowance.png"}
 if id.begins_with("card:"):
  var card := GameState.get_card(id.trim_prefix("card:"))
  if card != null: return {"name":card.name,"description":"新行动卡 · 已解锁","icon":SceneSkin.card_illustration_path(card.id)}
 var definition := ItemCatalog.definition(id)
 if id == "drink": definition["description"] = "饮用后恢复35点体力。"
 return definition

func dismiss() -> void:
 if not backdrop.visible: return
 backdrop.hide()
 displayed.clear()
 get_tree().paused = _was_paused
 if is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree() and _previous_focus.is_visible_in_tree(): _previous_focus.grab_focus()
 _previous_focus = null
 _schedule()

func _input(event: InputEvent) -> void:
 if not backdrop.visible: return
 if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
  get_viewport().set_input_as_handled()
  if not event.is_echo(): dismiss()
