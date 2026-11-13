class_name SceneSkin
extends RefCounted

## Current scene surfaces. No phase_two UI asset fallback is permitted.
const INK := Color("#303B45")
const MUTED := Color("#69716D")
const ACCENT := Color("#72846E")
const PAPER := Color("#F8F2E5")
const ROOT := "res://assets/ui/scene_reset/"
const DEDICATED := "res://assets/ui/phase_three/"
const PANEL_SHEETS := ["route_board","exploration_panel","story_panel","workshop_panel","records_panel","lounge_panel","result_panel","dialogue_sheet"]
const RETAINED := ["route_board","exploration_panel","story_panel","workshop_panel","records_panel","lounge_panel","card_paper","node_battle","node_rest","node_cache","node_elite","result_panel","dialogue_sheet"]
const ILLUSTRATION_REGIONS := {
 "opening":Rect2(32,112,453,305),"bag":Rect2(56,131,419,274),
 "water":Rect2(94,86,342,353),"pressure":Rect2(21,131,468,271),
 "route_step":Rect2(64,124,386,243),"support":Rect2(45,108,451,337)
}
static var _textures: Dictionary = {}
static var _illustrations: Dictionary = {}

static func asset_path(key: String) -> String:
 if key in ["button_primary","button_lavender","button_secondary","button_plain"]:
  if ResourceLoader.exists(ROOT+"campus_surfaces.png"): return ROOT+"campus_surfaces.png"
  return ROOT+("primary_button.svg" if key in ["button_primary","button_lavender"] else "paper_button.svg")
 if key == "card_frame": key = "card_paper"
 if key in PANEL_SHEETS and ResourceLoader.exists(DEDICATED+"paper_panel.png"):
  return DEDICATED+"paper_panel.png"
 if key in RETAINED and ResourceLoader.exists(DEDICATED+key+".png"):
  return DEDICATED+key+".png"
 return ROOT+"paper_panel.svg"

static func texture_for(key: String) -> Texture2D:
 var file := asset_path(key)
 if not ResourceLoader.exists(file): return null
 if not _textures.has(file):
  var source := load(file) as Texture2D
  if file.ends_with("campus_surfaces.png"):
   var crop := AtlasTexture.new()
   crop.atlas = source
   crop.region = Rect2(Vector2(802,616)*source.get_size()/Vector2(1672,941),Vector2(151,75)*source.get_size()/Vector2(1672,941))
   crop.filter_clip = true
   _textures[file] = crop
  else: _textures[file] = source
 return _textures[file] as Texture2D

static func card_illustration_path(card_id: String) -> String:
 var keys := {"wrench_smash":"opening","scrap_shield":"bag","icy_soda":"water","overclock_torch":"pressure","fake_cheque":"route_step","steel_barricade":"support"}
 return DEDICATED+"cards/"+str(keys.get(card_id,"opening"))+".png"

static func illustration_texture(file: String) -> Texture2D:
 if not ResourceLoader.exists(file): return null
 if _illustrations.has(file): return _illustrations[file]
 var source := load(file) as Texture2D
 var key := file.get_file().get_basename()
 if source != null and file.begins_with(DEDICATED+"cards/") and ILLUSTRATION_REGIONS.has(key):
  var crop := AtlasTexture.new()
  crop.atlas = source
  crop.region = ILLUSTRATION_REGIONS[key]
  crop.filter_clip = true
  _illustrations[file] = crop
  return crop
 return source

static func _insets(box: StyleBox, inset: Vector4) -> void:
 box.content_margin_left = inset.x
 box.content_margin_top = inset.y
 box.content_margin_right = inset.z
 box.content_margin_bottom = inset.w

static func texture_style(key: String, inset: Vector4 = Vector4(20,18,20,18), tint: Color = Color.WHITE) -> StyleBoxTexture:
 var texture := texture_for(key)
 if texture == null: return null
 var box := StyleBoxTexture.new()
 box.texture = texture
 box.modulate_color = tint*Color("#E2E9D4") if key in ["button_primary","button_lavender"] else tint
 var corner := 20.0 if texture.resource_path.ends_with(".svg") else 32.0
 if key in ["route_board","exploration_panel","story_panel","workshop_panel","records_panel","lounge_panel","result_panel"]: corner = 112.0
 if key.begins_with("node_"): corner = 0.0
 box.texture_margin_left = minf(corner,texture.get_width()/3.0)
 box.texture_margin_right = box.texture_margin_left
 box.texture_margin_top = minf(corner,texture.get_height()/3.0)
 box.texture_margin_bottom = box.texture_margin_top
 _insets(box,inset)
 return box

static func style(key: String, inset: Vector4 = Vector4(20,18,20,18), tint: Color = Color.WHITE) -> StyleBox:
 var painted := texture_style(key,inset,tint)
 if painted != null: return painted
 var flat := StyleBoxFlat.new()
 flat.bg_color = PAPER*tint
 flat.set_border_width_all(0)
 flat.set_corner_radius_all(3)
 _insets(flat,inset)
 return flat

static func panel_style(fill: Color = PAPER, _border: Color = Color.TRANSPARENT, inset: int = 0) -> StyleBox:
 return style("panel_frame",Vector4(inset,inset,inset,inset),Color(1,1,1,fill.a))

static func card_style(tint: Color = Color.WHITE) -> StyleBox:
 return style("card_frame",Vector4(14,12,14,12),tint)

static func focus_style() -> StyleBoxEmpty:
 return StyleBoxEmpty.new()

static func _button_theme(theme: Theme, type_name: String, key: String) -> void:
 if type_name != "Button": theme.set_type_variation(type_name,"Button")
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  var tint := Color.WHITE
  if state == "hover": tint = Color(1.04,1.035,1.01)
  elif state in ["pressed","hover_pressed"]: tint = Color(0.87,0.90,0.86)
  elif state == "disabled": tint = Color(0.86,0.87,0.84,0.78)
  theme.set_stylebox(state,type_name,style(key,Vector4(18,10,18,10),tint))
 theme.set_stylebox("focus",type_name,focus_style())
 for key_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  theme.set_color(key_name,type_name,INK)
 theme.set_color("font_disabled_color",type_name,MUTED)

static func apply_theme(theme: Theme) -> void:
 for type_name in ["Panel","PanelContainer"]: theme.set_stylebox("panel",type_name,panel_style())
 theme.set_type_variation("CardPanel","PanelContainer")
 theme.set_stylebox("panel","CardPanel",card_style())
 for type_name in ["Button","SecondaryButton","Secondary"]: _button_theme(theme,type_name,"button_plain")
 for type_name in ["PrimaryButton","Primary"]: _button_theme(theme,type_name,"button_primary")
 theme.set_type_variation("StatusPanel","PanelContainer")
 theme.set_stylebox("panel","StatusPanel",style("status_frame",Vector4(14,8,14,8)))
 theme.set_stylebox("background","ProgressBar",style("status_frame",Vector4.ZERO))
 var fill := StyleBoxFlat.new()
 fill.bg_color = Color("#91B29A")
 fill.set_corner_radius_all(3)
 theme.set_stylebox("fill","ProgressBar",fill)
 for type_name in ["LinkButton","CheckBox","CheckButton","OptionButton","MenuButton"]:
  theme.set_stylebox("focus",type_name,focus_style())

static func clear_cache() -> void:
 _textures.clear()
 _illustrations.clear()
