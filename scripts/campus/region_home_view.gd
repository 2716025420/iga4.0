class_name RegionHomeView
extends Control

signal action_requested(item: Dictionary)
signal map_requested
signal menu_requested
const SCALE := Vector2(1920.0/1672.0,1080.0/941.0)
var home_id := "techne_home_test"
var layout: Dictionary
var art: String
var refs: Dictionary = {"actions":{}}
var objects: Dictionary = {}
var selected_id := ""
var clock: Label
var remaining: Label
var ui_layer: Texture2D

static func artwork_available(id: String = "techne_home_test") -> bool:
 if not RegionHomeLayout.HOMES.has(id): return false
 var slug := str(RegionHomeLayout.HOMES[id]["slug"])
 return ResourceLoader.exists("res://assets/ui/scene_reset/homes/"+slug+"_clean.png")

func _ready() -> void:
 layout = RegionHomeLayout.HOMES[home_id]
 art = "res://assets/ui/scene_reset/homes/"+str(layout["slug"])
 size = Vector2(1920,1080)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 var room := SchoolObjectUI.art(self,"RoomBackground",art+"_clean.png")
 room.stretch_mode = TextureRect.STRETCH_SCALE
 ui_layer = load(art+"_ui.png") as Texture2D
 if layout.has("date_backing"):
  var backing := SchoolObjectUI.art(self,"DateBacking","")
  backing.texture = _crop_ui(layout["date_backing"])
  backing.stretch_mode = TextureRect.STRETCH_SCALE
  var rect: Rect2 = _rect(layout["date_backing"])
  DaylightUI.place(backing,rect.position.x,rect.position.y,rect.size.x,rect.size.y)
 for id in layout["objects"]: _add_object(str(id),room.texture)
 clock = SchoolObjectUI.text(self,"DayTime","",_rect(layout["clock"]),48,Color(layout["clock_ink"]))
 remaining = SchoolObjectUI.text(self,"Remaining","",_rect(layout["remaining"]),24,Color(layout["clock_ink"]))
 remaining.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 for text in [clock,remaining]:
  text.add_theme_color_override("font_shadow_color",Color(0,0,0,0.3) if str(layout["slug"]) == "agora" else Color(1,1,1,0.55))
  text.add_theme_constant_override("shadow_offset_y",1)
 var caption := SchoolObjectUI.text(self,"PreviewStatus","TEST · 人物与内容待完善",Rect2(70,1020,670,32),20,Color("#FFF7E7"))
 caption.add_theme_color_override("font_shadow_color",Color(0,0,0,0.75))
 caption.add_theme_constant_override("shadow_offset_y",1)
 var menu := _paper_button("OpenMenu",layout["menu"])
 menu.text = "☰ 菜单"
 menu.add_theme_font_size_override("font_size",29)
 menu.pressed.connect(func(): menu_requested.emit())
 refs["menu"] = menu
 _wire_focus()
 update_clock()
 DayCycle.changed.connect(update_clock)
 menu.grab_focus.call_deferred()

func _rect(source: Rect2) -> Rect2:
 return Rect2(source.position*SCALE,source.size*SCALE)

func _crop_ui(source: Rect2) -> AtlasTexture:
 var crop := AtlasTexture.new()
 crop.atlas = ui_layer
 var ratio := ui_layer.get_size()/Vector2(1672,941)
 crop.region = Rect2(source.position*ratio,source.size*ratio)
 crop.filter_clip = true
 return crop

func _paper_button(node_name: String, source: Rect2) -> Button:
 var button := SchoolObjectUI.hit(self,node_name,_rect(source),"",29)
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  var style := StyleBoxTexture.new()
  style.texture = _crop_ui(source)
  style.modulate_color = Color(1.04,1.04,1.01) if state == "hover" else (Color(0.86,0.90,0.85) if state in ["pressed","hover_pressed"] else Color.WHITE)
  button.add_theme_stylebox_override(state,style)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: button.add_theme_color_override(state,Color(layout["ink"]))
 SchoolObjectUI.borderless(button)
 return button

func _add_object(id: String, source: Texture2D) -> void:
 var spec: Dictionary = layout["objects"][id]
 var place: Dictionary = CampusPlaces.PLACES[home_id]
 var object_name := str(place["map_object_label"]) if id == "map" else str(place["actions"][spec["index"]]["object_label"])
 var copy := "地区地图" if id == "map" else str(place["actions"][spec["index"]]["label"])
 var button := HomeObjectButton.new()
 button.name = "Object_"+id
 add_child(button)
 var polygon := PackedVector2Array()
 for point in spec["polygon"]: polygon.append(Vector2(point[0],point[1])*source.get_size()/Vector2(1672,941))
 button.configure_registered(source,polygon,Vector2(1920,1080)/source.get_size())
 button.set_meta("display_label",object_name+"\n"+copy)
 button.set_meta("object_id",id)
 var plate := _paper_button("Label_"+id,spec["label"])
 plate.focus_mode = Control.FOCUS_NONE
 button.label_plate = plate
 var tab := bool(spec.get("tab",false))
 var label_size: Vector2 = _rect(spec["label"]).size
 var name_ink := Color("#FAF3E5") if tab else Color(layout["ink"])
 var name_y := 15.0 if tab else 44.0
 var body_y := 57.0 if tab else 80.0
 var name_label := SchoolObjectUI.text(plate,"Object",object_name,Rect2(18,name_y,label_size.x-36,32),21,name_ink,true)
 var function_label := SchoolObjectUI.text(plate,"Function",copy+"  →",Rect2(18,body_y,label_size.x-36,52),30,Color(layout["ink"]),true)
 if str(layout["slug"]) == "techne":
  var angle: float = {"workshop":-5.0,"records":-9.0,"map":5.0,"partner_test":9.0}[id]
  for text in [name_label,function_label]:
   text.pivot_offset = text.size/2.0
   text.rotation_degrees = angle
 objects[id] = button
 if id == "map": refs["map_button"] = button
 else: refs["actions"][id+str(spec["index"])] = button
 var activate := func():
  button.grab_focus()
  select_object(id)
  if id == "map": map_requested.emit()
  else: action_requested.emit({"id":id})
 button.pressed.connect(activate)
 plate.pressed.connect(activate)
 plate.mouse_entered.connect(func(): button.hovered = true; button._refresh())
 plate.mouse_exited.connect(func(): button.hovered = false; button._refresh())

func _wire_focus() -> void:
 var order: Array = [refs["menu"],objects["workshop"],objects["records"],objects["map"],objects["partner_test"]]
 for i in order.size():
  var control: BaseButton = order[i]
  control.focus_previous = control.get_path_to(order[posmod(i-1,order.size())])
  control.focus_next = control.get_path_to(order[(i+1)%order.size()])
  control.focus_neighbor_left = control.focus_previous
  control.focus_neighbor_top = control.focus_previous
  control.focus_neighbor_right = control.focus_next
  control.focus_neighbor_bottom = control.focus_next

func select_object(id: String = "") -> void:
 selected_id = id
 for key in objects: objects[key].set_selected(key == id)

func set_interactions_enabled(enabled: bool) -> void:
 for button in objects.values():
  button.disabled = not enabled
  button.label_plate.disabled = not enabled
 refs["menu"].disabled = not enabled

func update_clock() -> void:
 var date := DayCycle.calendar_date(GameState.game_day)
 clock.text = "%d月%d日 · %s" % [date["month"],date["day"],DayCycle.PERIOD_NAMES[DayCycle.period()]]
 remaining.text = ("今天是自由活动日。\n这个时段可安排 %d 次活动。\n伙伴交流不消耗活动次数。" % DayCycle.remaining()) if str(layout["slug"]) == "nomos" else ("%s · 可安排 %d 次活动" % [GameState.game_weekday,DayCycle.remaining()])
