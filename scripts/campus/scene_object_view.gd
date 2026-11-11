class_name SceneObjectView
extends Control

signal action_requested(item: Dictionary)
signal map_requested
signal menu_requested
var location_id := ""
var config: Dictionary
var refs: Dictionary = {"actions":{}}
var objects: Dictionary = {}
var selected_id := ""
var clock: Label

func _ready() -> void:
 size = Vector2(1920,1080)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 config = SceneDesignCatalog.place_config(location_id)
 var background := SchoolObjectUI.art(self,"PlaceBackground",SceneDesignCatalog.place_path(location_id))
 background.stretch_mode = TextureRect.STRETCH_SCALE
 SceneSurfaceUI.heading(self,str(config["title"]))
 clock = get_node("DayTime") as Label
 DayCycle.changed.connect(func(): clock.text = GameState.get_detailed_time_string())
 var map_button := SceneSurfaceUI.button(self,"OpenMap","地区地图",Rect2(1470,30,250,78),28)
 map_button.pressed.connect(func(): map_requested.emit())
 refs["map_button"] = map_button
 var menu := SceneSurfaceUI.button(self,"OpenMenu","菜单",Rect2(1740,30,135,78),28)
 menu.pressed.connect(func(): menu_requested.emit())
 refs["menu"] = menu
 for item in config["objects"]:
  var id := str(item["id"])
  var activate := func(): select_object(id); action_requested.emit(item)
  var pair := SceneSurfaceUI.landmark(self,"Action_"+id,background.texture,item["polygon"],item["tag"],str(item["label"]),activate)
  objects[id] = pair["image"]
  refs["actions"][id] = pair["label"]
 if config["objects"].is_empty(): _build_context()
 var test := SchoolObjectUI.text(self,"ConceptStatus","TEST · 场景与交互提案",Rect2(70,1015,900,38),21,Color("#FFF7E7"))
 test.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
 test.add_theme_constant_override("shadow_offset_y",1)
 SceneSurfaceUI.finish_layering(self,background)
 _wire_focus()
 map_button.grab_focus.call_deferred()

func _build_context() -> void:
 var place: Dictionary = CampusPlaces.PLACES[location_id]
 var actions: Array = place["actions"].filter(func(item): return item["id"] not in ["go","preview"])
 var panel := Panel.new()
 panel.name = "PlaceContext"
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_theme_stylebox_override("panel",SceneSkin.style("dialogue_sheet",Vector4.ZERO))
 add_child(panel)
 DaylightUI.place(panel,72,707,1100,285)
 var description := SchoolObjectUI.text(panel,"LocationDescription",str(place["description"]),Rect2(42,30,1015,125),29,SceneSkin.INK)
 description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 description.clip_text = true
 for i in actions.size():
  var item: Dictionary = actions[i]
  var id := str(item["id"])+str(i)
  var button := SceneSurfaceUI.button(panel,"Action_"+id,str(item["label"]),Rect2(40+i*340,184,320,71),26)
  button.pressed.connect(func(): action_requested.emit(item))
  refs["actions"][id] = button

func _wire_focus() -> void:
 var order: Array = [refs["menu"],refs["map_button"]]+refs["actions"].values()
 for i in order.size():
  var button: BaseButton = order[i]
  button.focus_previous = button.get_path_to(order[posmod(i-1,order.size())])
  button.focus_next = button.get_path_to(order[(i+1)%order.size()])
  button.focus_neighbor_left = button.focus_previous
  button.focus_neighbor_top = button.focus_previous
  button.focus_neighbor_right = button.focus_next
  button.focus_neighbor_bottom = button.focus_next

func select_object(id: String = "") -> void:
 selected_id = id
 for key in objects: objects[key].set_selected(key == id)

func set_interactions_enabled(enabled: bool) -> void:
 get_node("ConceptStatus").visible = enabled
 for image in objects.values(): image.disabled = not enabled
 for button in refs["actions"].values():
  button.disabled = not enabled
  button.visible = enabled
 refs["map_button"].disabled = not enabled
 refs["menu"].disabled = not enabled
