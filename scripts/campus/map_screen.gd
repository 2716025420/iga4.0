class_name MapScreen
extends Control

@export_enum("local","world") var map_level := "local"
var presentation: Control
var view: Control

func _ready() -> void:
 set_meta("map_page",true)
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 theme = DaylightUI.get_theme()
 mouse_filter = Control.MOUSE_FILTER_STOP
 presentation = Control.new()
 presentation.name = "MapPresentation"
 presentation.size = Vector2(1920,1080)
 add_child(presentation)
 if map_level == "world":
  view = RegionAtlasView.new()
  view.region_requested.connect(func(id: String): CampusLife.open_local_map(id))
  view.entry_requested.connect(func(id: String): CampusLife.enter_region(id))
 else:
  view = RegionMapView.new()
  view.region_id = CampusLife.map_region_id
  view.travel_requested.connect(func(id: String): CampusLife.travel_to(id,CampusLife.map_region_id))
  view.atlas_requested.connect(func(): CampusLife.open_region_atlas())
 view.name = "MapView"
 presentation.add_child(view)
 view.close_requested.connect(_back)
 resized.connect(_layout)
 _layout()

func _layout() -> void:
 var bg_tex: Texture2D = null
 var mother := view.get_node_or_null("ConceptMother") as TextureRect if is_instance_valid(view) else null
 if mother != null: bg_tex = mother.texture
 var atlas := view.get_node_or_null("TravelConcept") as TextureRect if is_instance_valid(view) else null
 if bg_tex == null and atlas != null: bg_tex = atlas.texture
 Platform.fit_stage(self,presentation,Color("#EAE1D1"),bg_tex)

func _back() -> void:
 if SceneManager.is_transitioning: return
 if map_level == "world":
  CampusLife.open_local_map(CampusLife.map_region_id if RegionCatalog.is_unlocked(CampusLife.map_region_id) else "campus")
 else: CampusLife.close_map()

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
  _back()
  get_viewport().set_input_as_handled()
