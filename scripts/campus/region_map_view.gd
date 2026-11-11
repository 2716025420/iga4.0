class_name RegionMapView
extends Control

signal travel_requested(location_id: String)
signal atlas_requested
signal close_requested
var region_id := "campus"
var refs: Dictionary = {}
var _calendar_refresh_pending := false

func _ready() -> void:
 size = Vector2(1920,1080)
 mouse_filter = Control.MOUSE_FILTER_STOP
 refresh()
 DayCycle.changed.connect(_calendar_changed)

func _calendar_changed() -> void:
 if _calendar_refresh_pending: return
 _calendar_refresh_pending = true
 _refresh_calendar.call_deferred()

func _refresh_calendar() -> void:
 _calendar_refresh_pending = false
 if not is_inside_tree(): return
 var focused := get_viewport().gui_get_focus_owner()
 refresh(str(focused.name) if is_instance_valid(focused) and is_ancestor_of(focused) else "")

func _restore_focus(node_name: String) -> void:
 if not is_inside_tree(): return
 var target := get_node_or_null(node_name) as Control
 if is_instance_valid(target) and target.is_inside_tree(): target.grab_focus()

func refresh(focus_name: String = "") -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 refs.clear()
 if SceneDesignCatalog.MAPS.has(region_id):
  _build_illustrated_map(focus_name)
  return
 if RegionCatalog.is_primary(region_id) and region_id != "university_arete":
  _build_test_map(focus_name)
  return
 var spec: Dictionary = RegionCatalog.REGIONS["campus" if region_id == "university_arete" else region_id]
 var campus := region_id in ["campus","university_arete"]
 var visual: Dictionary = RegionCatalog.CONCEPTS[CampusLife.map_concept()] if campus else spec
 var paper := Color(visual["paper"])
 var ink := Color(visual["ink"])
 var path := str(visual.get("path",""))
 var painted := campus and ResourceLoader.exists(path)
 var mother: TextureRect
 if painted:
  mother = SchoolObjectUI.art(self,"ConceptMother",path)
  mother.set_meta("layer_role","complete_unified_campus_composition")
 elif campus:
  var geometry := MapPageGeometry.new()
  add_child(geometry)
  ink = Color("#2D5059")
  paper = Color("#F2E7D6")
 else:
  var geometry := RegionGeometry.new()
  geometry.region_id = region_id
  add_child(geometry)
 if mother != null and mother.texture != null:
  for id in spec["places"]:
   var rect: Rect2 = RegionCatalog.PAINTED_RECTS[CampusLife.map_concept()][id]
   var crop := AtlasTexture.new()
   crop.atlas = mother.texture
   var ratio := mother.texture.get_size()/Vector2(1920,1080)
   crop.region = Rect2(rect.position*ratio,rect.size*ratio)
   crop.filter_clip = true
   var layer := SchoolObjectUI.art(self,"Landmark_"+id,"",rect)
   layer.texture = crop
   layer.set_meta("layer_role","registered_landmark_crop")
 if painted:
  var header_plate := MapPageUI.plate(self,"HeaderBacking",Rect2(80,36,480,124),Color(paper,0.68))
  header_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var heading := SchoolObjectUI.text(self,"MapTitle",str(RegionCatalog.REGIONS[region_id]["title"])+"地图",Rect2(98,43,850,68),46,ink)
 var calendar := SchoolObjectUI.text(self,"DayTime",GameState.get_detailed_time_string(),Rect2(102,116,850,36),21,Color(ink,0.88))
 for label in [heading,calendar]:
  label.add_theme_color_override("font_shadow_color",Color(paper,0.9))
  label.add_theme_constant_override("shadow_offset_y",1)
  label.add_theme_constant_override("shadow_outline_size",2)
 var atlas := MapPageUI.button(self,"OpenRegionAtlas","地区总图 →",Rect2(1270,55,265,70),ink,Color(paper,0.55))
 atlas.pressed.connect(func(): atlas_requested.emit())
 var back := MapPageUI.button(self,"ReturnToPlace","返回地点 ×",Rect2(1570,55,270,70),ink,Color(paper,0.55))
 back.pressed.connect(func(): close_requested.emit())
 refs["atlas"] = atlas
 refs["back"] = back
 refs["locations"] = {}
 for id in spec["places"]:
  var rect: Rect2 = RegionCatalog.PAINTED_RECTS[CampusLife.map_concept()][id] if painted else RegionCatalog.MAP_RECTS[id]
  var button := MapPageUI.button(self,"Place_"+id,"",rect,ink)
  button.pressed.connect(func(): travel_requested.emit(str(id)))
  refs["locations"][id] = button
  var label_rect: Rect2 = (RegionCatalog.PAINTED_LABELS[CampusLife.map_concept()][id] if painted else RegionCatalog.CAMPUS_LABELS[id]) if campus else Rect2(rect.position+Vector2(8,rect.size.y-75),Vector2(rect.size.x-16,70))
  var title := str(RegionCatalog.SHORT_NAMES.get(id,CampusPlaces.PLACES[id]["title"]))
  var name_label := SchoolObjectUI.text(self,"Name_"+id,title,Rect2(label_rect.position,Vector2(label_rect.size.x,40)),28,Color.BLACK,true)
  name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  name_label.add_theme_color_override("font_shadow_color",Color(1,1,1,0.65))
  name_label.add_theme_constant_override("shadow_offset_x",1)
  name_label.add_theme_constant_override("shadow_offset_y",1)
  name_label.add_theme_constant_override("shadow_outline_size",2)
 if region_id == "university_arete":
  for i in 2:
   var id: String = ["arete_coast_test","arete_beach_test"][i]
   var b := MapPageUI.button(self,"Place_"+id,str(CampusPlaces.PLACES[id]["title"]),Rect2(990+i*440,990,420,62),ink,Color(paper,0.8),23)
   b.pressed.connect(func(): travel_requested.emit(id))
   refs["locations"][id] = b
 var hint_ink := Color("#F6ECDD") if painted else ink
 var hint := SchoolObjectUI.text(self,"MapHint","可安排 %d 次活动 · 选择地点前往 · Esc 返回" % DayCycle.remaining(),Rect2(96,1012,700,36),20,Color(hint_ink,0.85))
 hint.add_theme_color_override("font_shadow_color",Color(0,0,0,0.35))
 hint.add_theme_constant_override("shadow_offset_y",1)
 _restore_focus.call_deferred(focus_name if focus_name != "" and has_node(focus_name) else "ReturnToPlace")


func _build_test_map(focus_name: String) -> void:
 var spec: Dictionary = RegionCatalog.REGIONS[region_id]
 var ink := Color("#E7EBED")
 SchoolObjectUI.slab(self,"TestBackground",Rect2(0,0,1920,1080),Color("#20262D"))
 SchoolObjectUI.text(self,"MapTitle",str(spec["title"])+" · TEST 地区地图",Rect2(95,45,1250,75),42,ink)
 SchoolObjectUI.text(self,"DayTime",GameState.get_detailed_time_string(),Rect2(100,125,1200,45),25,ink)
 SchoolObjectUI.text(self,"TestNotice","工程导航占位 · 地点排列不代表地理关系 · 正式全页概念与剧情待主创审核",Rect2(100,205,1700,50),26,ink)
 var atlas := MapPageUI.button(self,"OpenRegionAtlas","世界地图",Rect2(1300,55,230,70),ink,Color(1,1,1,0.06))
 atlas.pressed.connect(func(): atlas_requested.emit())
 var back := MapPageUI.button(self,"ReturnToPlace","返回出发地点",Rect2(1570,55,270,70),ink,Color(1,1,1,0.06))
 back.pressed.connect(func(): close_requested.emit())
 refs["atlas"] = atlas
 refs["back"] = back
 refs["locations"] = {}
 for i in spec["places"].size():
  var id: String = spec["places"][i]
  var b := MapPageUI.button(self,"Place_"+id,str(CampusPlaces.PLACES[id]["title"]),Rect2(100,330+i*130,1730,95),ink,Color(1,1,1,0.06),29)
  b.disabled = not RegionCatalog.is_unlocked(region_id)
  b.pressed.connect(func(): travel_requested.emit(id))
  refs["locations"][id] = b
 SchoolObjectUI.text(self,"MapHint","浏览不移动角色 · 选择地点才旅行 · 首次旅行先经过 TEST 到达入口 · 无活动消耗",Rect2(100,990,1710,55),24,ink)
 _restore_focus.call_deferred(focus_name if focus_name != "" and has_node(focus_name) else "ReturnToPlace")

func _build_illustrated_map(focus_name: String) -> void:
 var spec: Dictionary = SceneDesignCatalog.MAPS[region_id]
 var background := SchoolObjectUI.art(self,"ConceptMother",SceneDesignCatalog.map_path(region_id))
 background.stretch_mode = TextureRect.STRETCH_SCALE
 background.set_meta("layer_role","current_registered_district_concept")
 SceneSurfaceUI.heading(self,str(RegionCatalog.REGIONS[region_id]["title"])+"地图")
 get_node("LocationTitle").name = "MapTitle"
 var atlas := SceneSurfaceUI.button(self,"OpenRegionAtlas","世界地图",Rect2(1365,32,220,76),28)
 atlas.pressed.connect(func(): atlas_requested.emit())
 var back := SceneSurfaceUI.button(self,"ReturnToPlace","返回地点",Rect2(1610,32,240,76),28)
 back.pressed.connect(func(): close_requested.emit())
 refs["atlas"] = atlas
 refs["back"] = back
 refs["locations"] = {}
 refs["landmarks"] = {}
 for id in spec["locations"]:
  var item: Dictionary = spec["locations"][id]
  var activate := func(): travel_requested.emit(str(id))
  var pair := SceneSurfaceUI.landmark(self,"Place_"+id,background.texture,item["polygon"],item["tag"],str(item["label"]),activate)
  pair["label"].disabled = not RegionCatalog.is_unlocked(region_id)
  pair["image"].disabled = pair["label"].disabled
  refs["locations"][id] = pair["label"]
  refs["landmarks"][id] = pair["image"]
 var note := SchoolObjectUI.text(self,"MapHint","TEST · 地理/建筑为可调整提案 · 浏览不旅行 · Esc 返回",Rect2(90,1009,1600,43),23,Color("#FFF7E5"))
 note.add_theme_color_override("font_shadow_color",Color(0,0,0,0.85))
 note.add_theme_constant_override("shadow_offset_y",2)
 var order: Array = [back,atlas]+refs["locations"].values()
 for i in order.size():
  var button: Button = order[i]
  button.focus_previous = button.get_path_to(order[posmod(i-1,order.size())])
  button.focus_next = button.get_path_to(order[(i+1)%order.size()])
  button.focus_neighbor_left = button.focus_previous
  button.focus_neighbor_top = button.focus_previous
  button.focus_neighbor_right = button.focus_next
  button.focus_neighbor_bottom = button.focus_next
 SceneSurfaceUI.finish_layering(self,background)
 _restore_focus.call_deferred(focus_name if focus_name != "" and has_node(focus_name) else "ReturnToPlace")
