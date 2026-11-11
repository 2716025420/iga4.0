class_name RegionAtlasView
extends Control

signal region_requested(region_id: String)
signal entry_requested(region_id: String)
signal close_requested
var refs: Dictionary = {}

func _ready() -> void:
 size = Vector2(1920,1080)
 mouse_filter = Control.MOUSE_FILTER_STOP
 var background := SchoolObjectUI.art(self,"TravelConcept",SceneDesignCatalog.ROOT+"maps/world.png")
 background.stretch_mode = TextureRect.STRETCH_SCALE
 SceneSurfaceUI.heading(self,"地区旅行图 · TEST")
 var back := SceneSurfaceUI.button(self,"BackToLocal","返回地区地图",Rect2(1570,35,280,76),27)
 back.pressed.connect(func(): close_requested.emit())
 refs["back"] = back
 refs["regions"] = {}
 for id in WorldRegionContent.REGIONS:
  var spec: Dictionary = SceneDesignCatalog.WORLD[id]
  var activate := func(): entry_requested.emit(str(id))
  var pair := SceneSurfaceUI.landmark(self,"Enter_"+id,background.texture,spec["polygon"],spec["tag"],str(WorldRegionContent.REGIONS[id]["title"])+" →",activate)
  var tag := SceneDesignCatalog.rect(spec["tag"])
  var point := tag.position*SceneDesignCatalog.DESIGN/SceneDesignCatalog.NATIVE
  var browse := SceneSurfaceUI.button(self,"Browse_"+id,"地区地图",Rect2(point+Vector2(125,79),Vector2(155,51)),22)
  browse.pressed.connect(func(): region_requested.emit(str(id)))
  var status := SchoolObjectUI.text(self,"RegionStatus_"+id,"",Rect2(point+Vector2(7,83),Vector2(150,42)),20,Color("#FFF9E9"))
  status.add_theme_color_override("font_shadow_color",Color(0,0,0,0.9))
  status.add_theme_constant_override("shadow_offset_y",1)
  refs["regions"][id] = {"enter":pair["label"],"browse":browse,"landmark":pair["image"]}
 var footer := SchoolObjectUI.slab(self,"CompatibilityBacking",Rect2(45,975,1830,87),Color(0.96,0.93,0.85,0.9))
 footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 SchoolObjectUI.text(self,"Compatibility","其它地区",Rect2(72,996,755,39),22,SceneSkin.INK)
 refs["legacy"] = {}
 var index := 0
 for id in RegionCatalog.LEGACY_REGIONS:
  var button := SceneSurfaceUI.button(self,"Legacy_"+id,str(RegionCatalog.REGIONS[id]["title"]),Rect2(1000+index*280,985,260,66),24)
  button.pressed.connect(func(): region_requested.emit(str(id)))
  refs["legacy"][id] = button
  index += 1
 var legend := SchoolObjectUI.text(self,"Legend","TEST · 旅行示意，不表示正式地理关系",Rect2(70,185,910,42),22,Color("#FFF7E5"))
 legend.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
 legend.add_theme_constant_override("shadow_offset_y",1)
 GameState.story_flag_updated.connect(_refresh_unlocks)
 SceneSurfaceUI.finish_layering(self,background)
 _refresh_unlocks("",null)
 back.grab_focus.call_deferred()

func _refresh_unlocks(_flag: String, _value: Variant) -> void:
 var order: Array = [refs["back"]]
 for id in refs["regions"]:
  var available := RegionCatalog.is_unlocked(str(id))
  var visited := CampusLife.has_visited_region(str(id))
  var home := RegionCatalog.home_for_region(str(id))
  var pair: Dictionary = refs["regions"][id]
  for key in ["enter","browse","landmark"]: pair[key].disabled = not available
  var status := get_node("RegionStatus_"+id) as Label
  status.text = (("直达 Home" if home != "" else "剧情入口") if visited else "首次到达") if available else "尚未解锁"
  for button in [pair["enter"],pair["browse"]]:
   button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
   if available: order.append(button)
 for id in refs["legacy"]:
  var button: Button = refs["legacy"][id]
  button.disabled = not RegionCatalog.is_unlocked(str(id))
  if not button.disabled: order.append(button)
 for i in order.size():
  var button: Button = order[i]
  button.focus_previous = button.get_path_to(order[posmod(i-1,order.size())])
  button.focus_next = button.get_path_to(order[(i+1)%order.size()])
  button.focus_neighbor_top = button.focus_previous
  button.focus_neighbor_left = button.focus_previous
  button.focus_neighbor_bottom = button.focus_next
  button.focus_neighbor_right = button.focus_next
